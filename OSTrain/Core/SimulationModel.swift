//
//  SimulationModel.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation
import SwiftUI

// Busy-loop CPU burn helper used by background threads to simulate work.
// Runs synchronously for approximately `durationMs` milliseconds and
// periodically invokes `progress` with values in 0...1.
private enum CPUBurner {
    @inline(__always)
    static func run(durationMs: Int, progress: @Sendable (Double) -> Void) {
        let duration = max(0, durationMs)
        if duration == 0 {
            progress(1)
            return
        }

        let start = CFAbsoluteTimeGetCurrent()
        let target = start + (Double(duration) / 1000.0)
        var lastReported: Double = -1

        // Spin with some lightweight math to keep a core busy
        while true {
            // Do a bit of meaningless math to avoid being optimized out
            var acc: Double = 0
            for i in 1...10_000 { acc += sin(Double(i)) * cos(Double(i)) }
            _ = acc

            let now = CFAbsoluteTimeGetCurrent()
            let elapsed = now - start
            let total = max(0.000_001, target - start)
            let p = min(1.0, max(0.0, elapsed / total))

            // Throttle progress callbacks to ~1% increments
            if p >= 1.0 || p - lastReported >= 0.01 {
                lastReported = p
                progress(p)
            }

            if now >= target { break }
        }
    }
}

// Thread-safe counting semaphore not isolated to the main actor
final class BlockingSemaphore {
    private let semaphore: DispatchSemaphore
    private let lock = NSLock()
    private var shadowCount: Int

    init(initial: Int) {
        self.semaphore = DispatchSemaphore(value: max(0, initial))
        self.shadowCount = max(0, initial)
    }

    func wait() {
        semaphore.wait()
        lock.lock()
        shadowCount -= 1
        lock.unlock()
    }

    func signal() {
        lock.lock()
        shadowCount += 1
        lock.unlock()
        semaphore.signal()
    }

    // Approximate available permits; may be slightly stale under contention
    func approxValue() -> Int {
        lock.lock()
        let v = shadowCount
        lock.unlock()
        return v
    }
}

// Thread-safe depot for boxes, not isolated to the main actor
final class ThreadDeposito {
    private var storage: [Int] = []
    private let lock = NSLock()

    func push() {
        lock.lock()
        storage.append(1) // value is irrelevant; we only track count
        lock.unlock()
    }

    func pop() {
        lock.lock()
        if !storage.isEmpty { _ = storage.removeLast() }
        lock.unlock()
    }

    var count: Int {
        lock.lock()
        let c = storage.count
        lock.unlock()
        return c
    }
}

// These types are used safely across threads using internal locking.
extension BlockingSemaphore: @unchecked Sendable {}
extension ThreadDeposito: @unchecked Sendable {}

// MARK: - Simulation Model (MainActor)
@MainActor
@Observable
final class SimulationModel {
    // Configuração
    let M: Int
    let N: Int
    let tvMs: Int

    // Semáforos e depósito (blocking, thread-safe)
    private let empty: BlockingSemaphore
    private let full: BlockingSemaphore
    private let deposito: ThreadDeposito

    // UI State
    var depositoCount: Int = 0
    var packers: [PackerViewModel] = []
    var trainStatus: TrainStatus
    var trainProgress: Double = 0

    // Threads
    @ObservationIgnored private var trainThread: Thread? = nil
    @ObservationIgnored private var packerThreads: [Int: Thread] = [:]

    // Cancellation flags
    @ObservationIgnored private var isRunningFlag: Bool = false
    @ObservationIgnored private var packerRunFlags: [Int: Bool] = [:]

    init(M: Int, N: Int, tvMs: Int, packerTeMs: [Int], policy: WaitPolicy) {
        self.M = M
        self.N = N
        self.tvMs = tvMs
        self.empty = BlockingSemaphore(initial: M)
        self.full = BlockingSemaphore(initial: 0)
        self.deposito = ThreadDeposito()
        self.trainStatus = .paradoAguardando(n: N)
        self.packers = packerTeMs.enumerated().map { idx, te in
            PackerViewModel(id: idx + 1, name: "E\(idx + 1)", status: .empacotando, progress: 0, teMs: te)
        }
    }

    func start() {
        guard !isRunningFlag else { return }
        isRunningFlag = true

        // Start packer threads
        for p in packers { startPackerThread(for: p) }

        // Start train thread
        startTrainThread()
    }

    private func startPackerThread(for packer: PackerViewModel) {
        let id = packer.id
        let empty = self.empty
        let full = self.full
        let deposito = self.deposito
        packerRunFlags[id] = true

        let thread = Thread { [weak self] in
            guard let self else { return }
            Thread.current.name = "Packer-\(id)"
            while self.readPackerRunFlag(id: id) && self.readIsRunningFlag() {
                // 1) Empacotar (CPU-bound)
                DispatchQueue.main.async { [weak self] in self?.updatePacker(id: id, status: .empacotando) }
                CPUBurner.run(durationMs: packer.teMs) { p in
                    DispatchQueue.main.async { [weak self] in self?.updatePackerProgress(id: id, p) }
                }

                // 2) Heurística de UI — mostrar dormindo se não há espaço
                var approx = 0
                DispatchQueue.main.sync {
                    approx = empty.approxValue()
                }
                if approx == 0 {
                    DispatchQueue.main.async { [weak self] in self?.updatePacker(id: id, status: .dormindo) }
                }

                // 3) Esperar vaga → inserir → sinalizar full
                empty.wait()
                DispatchQueue.main.async { [weak self] in self?.updatePacker(id: id, status: .colocando) }
                deposito.push()
                let count = deposito.count
                DispatchQueue.main.async { [weak self] in self?.setDepositoCount(count) }
                full.signal()
            }
        }
        thread.qualityOfService = .userInitiated
        packerThreads[id] = thread
        thread.start()
    }

    private func startTrainThread() {
        let N = self.N
        let tvMs = self.tvMs
        let full = self.full
        let empty = self.empty
        let deposito = self.deposito

        let thread = Thread { [weak self] in
            guard let self else { return }
            Thread.current.name = "Train"
            while self.readIsRunningFlag() {
                // 1) Aguardar N caixas
                DispatchQueue.main.async { [weak self] in self?.setTrainStatus(.paradoAguardando(n: N)) }
                for _ in 0..<N { full.wait() }

                // 2) Carregar N caixas
                DispatchQueue.main.async { [weak self] in self?.setTrainStatus(.carregando(n: N)) }
                for _ in 0..<N {
                    deposito.pop()
                    let count = deposito.count
                    DispatchQueue.main.async { [weak self] in self?.setDepositoCount(count) }
                    empty.signal()
                }

                // 3) Viajar A → B
                DispatchQueue.main.async { [weak self] in self?.setTrainStatus(.viajandoAParaB) }
                CPUBurner.run(durationMs: tvMs) { p in
                    DispatchQueue.main.async { [weak self] in self?.setTrainProgress(p) }
                }

                // 4) Viajar B → A
                DispatchQueue.main.async { [weak self] in self?.setTrainStatus(.viajandoBParaA) }
                CPUBurner.run(durationMs: tvMs) { p in
                    DispatchQueue.main.async { [weak self] in self?.setTrainProgress(p) }
                }
            }
        }
        thread.qualityOfService = .userInitiated
        trainThread = thread
        thread.start()
    }

    func addPacker(name: String, teMs: Int) {
        let newId = (packers.map { $0.id }.max() ?? 0) + 1
        let new = PackerViewModel(id: newId, name: name.isEmpty ? "E\(newId)" : name, status: .empacotando, progress: 0, teMs: teMs)
        packers.append(new)
        if isRunningFlag { startPackerThread(for: new) }
    }

    func removePacker(id: Int) {
        // Stop thread
        packerRunFlags[id] = false
        if let _ = packerThreads[id] {
            // Best-effort cooperative stop: signal semaphores to unblock if needed
            empty.signal(); full.signal()
            packerThreads[id] = nil
        }
        if let idx = packers.firstIndex(where: { $0.id == id }) {
            packers.remove(at: idx)
        }
    }

    func stop() {
        guard isRunningFlag else { return }
        isRunningFlag = false

        // Stop packers
        for (id, _) in packerThreads { packerRunFlags[id] = false }
        // Nudge semaphores to unblock
        for _ in 0..<(M + 8) { empty.signal(); full.signal() }

        // Clear references (threads will naturally exit their loops)
        packerThreads.removeAll()
        trainThread = nil

        // Reset UI state
        depositoCount = 0
        for i in packers.indices {
            packers[i].status = .empacotando
            packers[i].progress = 0
        }
        trainStatus = .paradoAguardando(n: N)
        trainProgress = 0
    }

    // MARK: - UI Update helpers (MainActor)
    func setDepositoCount(_ count: Int) {
        depositoCount = count
    }

    func updatePacker(id: Int, status: PackerStatus) {
        if let idx = packers.firstIndex(where: { $0.id == id }) {
            packers[idx].status = status
        }
    }

    func updatePackerProgress(id: Int, _ p: Double) {
        if let idx = packers.firstIndex(where: { $0.id == id }) {
            packers[idx].progress = p
        }
    }

    func setTrainStatus(_ status: TrainStatus) {
        trainStatus = status
        switch status {
        case .carregando:
            // Reset progress when loading begins
            trainProgress = 0
        case .viajandoAParaB, .viajandoBParaA:
            // Reset progress at the start of each travel leg to avoid flicker
            trainProgress = 0
        case .paradoAguardando:
            // When waiting at A, ensure the rendered progress is at the A-end (0)
            trainProgress = 0
        }
    }

    func setTrainProgress(_ p: Double) {
        trainProgress = p
    }

    // MARK: - Nonisolated flag readers for background threads

    nonisolated private func readIsRunningFlag() -> Bool {
        // Safely read the MainActor-isolated flag from a background thread
        DispatchQueue.main.sync { [weak self] in
            self?.isRunningFlag ?? false
        }
    }

    nonisolated private func readPackerRunFlag(id: Int) -> Bool {
        // Safely read the per-packer run flag from a background thread
        DispatchQueue.main.sync { [weak self] in
            self?.packerRunFlags[id] ?? false
        }
    }
}


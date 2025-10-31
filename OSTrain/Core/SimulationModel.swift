//
//  SimulationModel.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation
import SwiftUI

// MARK: - Simulation Model (MainActor)
@MainActor
@Observable
final class SimulationModel {
    // Configuração
    let M: Int
    let N: Int
    let tvMs: Int

    // Semáforos e depósito
    private let empty: AsyncSemaphore
    private let full: AsyncSemaphore
    private let deposito: Deposito

    // UI State
    var depositoCount: Int = 0
    var packers: [PackerViewModel] = []
    var trainStatus: TrainStatus
    var trainProgress: Double = 0

    @ObservationIgnored private var tasks: [Task<Void, Never>] = []
    @ObservationIgnored private var packerTasks: [Int: Task<Void, Never>] = [:]
    private var started: Bool = false

    init(M: Int, N: Int, tvMs: Int, packerTeMs: [Int], policy: WaitPolicy) {
        self.M = M
        self.N = N
        self.tvMs = tvMs
        self.empty = AsyncSemaphore(M, policy: policy)
        self.full = AsyncSemaphore(0, policy: policy)
        self.deposito = Deposito()
        self.trainStatus = .paradoAguardando(n: N)
        self.packers = packerTeMs.enumerated().map { idx, te in
            PackerViewModel(id: idx + 1, name: "E\(idx + 1)", status: .empacotando, progress: 0, teMs: te)
        }
    }

    deinit {
        for t in tasks { t.cancel() }
        for (_, t) in packerTasks { t.cancel() }
    }

    func start() {
        guard !started else { return }
        started = true

        // Empacotadores
        for p in packers {
            startPackerTask(for: p)
        }

        // Trem
        let N = self.N
        let tvMs = self.tvMs
        let empty = self.empty
        let full = self.full
        let deposito = self.deposito

        let trainTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                // 1) Aguardar N caixas
                await self.setTrainStatus(.paradoAguardando(n: N))
                for _ in 0..<N { await full.wait() }

                // 2) Carregar N caixas
                await self.setTrainStatus(.carregando(n: N))
                for _ in 0..<N {
                    await deposito.pop()
                    let count = await deposito.count
                    await self.setDepositoCount(count)
                    await empty.signal()
                }

                // 3) Viajar A → B (CPU-bound + frames pela própria task)
                await self.setTrainStatus(.viajandoAParaB)
                await SpinTimer.cpuBurn(durationMs: tvMs) { p in
                    self.setTrainProgress(p)
                }

                // 4) Viajar B → A
                await self.setTrainStatus(.viajandoBParaA)
                await SpinTimer.cpuBurn(durationMs: tvMs) { p in
                    self.setTrainProgress(p)
                }
            }
        }
        tasks.append(trainTask)
    }

    private func startPackerTask(for packer: PackerViewModel) {
        let id = packer.id
        let teMs = packer.teMs
        let empty = self.empty
        let full = self.full
        let deposito = self.deposito

        let task = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.updatePacker(id: id, status: .empacotando)
                await SpinTimer.cpuBurn(durationMs: teMs) { p in
                    self.updatePackerProgress(id: id, p)
                }
                let approx = await empty.approxValue()
                if approx == 0 {
                    await self.updatePacker(id: id, status: .dormindo)
                }
                await empty.wait()
                await self.updatePacker(id: id, status: .colocando)
                await deposito.push()
                let count = await deposito.count
                await self.setDepositoCount(count)
                await full.signal()
            }
        }
        packerTasks[id] = task
    }

    func addPacker(name: String, teMs: Int) {
        // Determine new unique id
        let newId = (packers.map { $0.id }.max() ?? 0) + 1
        let new = PackerViewModel(id: newId, name: name.isEmpty ? "E\(newId)" : name, status: .empacotando, progress: 0, teMs: teMs)
        packers.append(new)
        if started {
            startPackerTask(for: new)
        }
    }

    func removePacker(id: Int) {
        if let t = packerTasks[id] {
            t.cancel()
            packerTasks[id] = nil
        }
        if let idx = packers.firstIndex(where: { $0.id == id }) {
            packers.remove(at: idx)
        }
    }

    func stop() {
        for (_, t) in packerTasks { t.cancel() }
        packerTasks.removeAll()

        for t in tasks { t.cancel() }
        tasks.removeAll()
        started = false
        // Reset UI state
        depositoCount = 0
        for i in packers.indices {
            packers[i].status = .empacotando
            packers[i].progress = 0
        }
        trainStatus = .paradoAguardando(n: N)
        trainProgress = 0
    }

    // MARK: - UI Updates (MainActor)
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
}


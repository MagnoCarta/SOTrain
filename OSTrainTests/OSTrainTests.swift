//
//  OSTrainTests.swift
//  OSTrainTests
//
//  Created by Gilberto Magno on 24/10/25.
//

import Testing

struct OSTrainTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

//import SwiftUI
//import Foundation
//import Observation
//
//// MARK: - Modes
//
//enum WorkMode: String, CaseIterable, Identifiable {
//    case timeBound = "Time-bound"
//    case cpuBound  = "CPU-bound"
//    var id: String { rawValue }
//}
//
//// MARK: - Domain Config (time in ms)
//
//struct SimulationConfig: Equatable, Hashable, Identifiable {
//    let id = UUID()
//    let name: String
//    let M: Int          // depot capacity (M ≥ N)
//    let N: Int          // batch size per trip
//    let P: Int          // number of packers
//
//    // Travel durations per leg (ms)
//    var tvMsAB: Int
//    var tvMsBA: Int
//
//    // Packer durations per packer (ms) (size == P)
//    var teMsPerPacker: [Int]
//}
//
//enum Scenario: String, CaseIterable, Identifiable {
//    case basicBalanced, depotFillsFast, slowProduction, nEqualsM, smallN, nNearM, singlePacker,
//         veryShortTravel, veryLongTravel, hugeTE, largeMStress, borderN1
//
//    var id: String { rawValue }
//
//    var config: SimulationConfig {
//        switch self {
//        case .basicBalanced:
//            return .mk(name: "1) Basic Balanced", M: 20, N: 10, P: 3, teMs: 1200, tvAB: 2000, tvBA: 2000)
//        case .depotFillsFast:
//            return .mk(name: "2) Depot Fills Fast", M: 20, N: 10, P: 8, teMs: 400, tvAB: 6000, tvBA: 6000)
//        case .slowProduction:
//            return .mk(name: "3) Slow Production", M: 20, N: 10, P: 2, teMs: 5000, tvAB: 2000, tvBA: 2000)
//        case .nEqualsM:
//            return .mk(name: "4) N = M", M: 10, N: 10, P: 5, teMs: 1200, tvAB: 3000, tvBA: 3000)
//        case .smallN:
//            return .mk(name: "5) Small N", M: 20, N: 2, P: 3, teMs: 1600, tvAB: 1600, tvBA: 1600)
//        case .nNearM:
//            return .mk(name: "6) N near M", M: 20, N: 18, P: 6, teMs: 1200, tvAB: 2000, tvBA: 2000)
//        case .singlePacker:
//            return .mk(name: "7) One Packer", M: 20, N: 10, P: 1, teMs: 1200, tvAB: 2000, tvBA: 2000)
//        case .veryShortTravel:
//            return .mk(name: "8) Very Short Travel", M: 20, N: 10, P: 6, teMs: 1200, tvAB: 300, tvBA: 300)
//        case .veryLongTravel:
//            return .mk(name: "9) Very Long Travel", M: 20, N: 10, P: 6, teMs: 1200, tvAB: 10_000, tvBA: 10_000)
//        case .hugeTE:
//            return .mk(name: "10) Huge te", M: 20, N: 10, P: 10, teMs: 8000, tvAB: 2000, tvBA: 2000)
//        case .largeMStress:
//            return .mk(name: "11) Large M Stress", M: 100, N: 10, P: 12, teMs: 800, tvAB: 2400, tvBA: 2400)
//        case .borderN1:
//            return .mk(name: "12) Border N=1", M: 20, N: 1, P: 2, teMs: 2000, tvAB: 1600, tvBA: 1600)
//        }
//    }
//}
//
//private extension SimulationConfig {
//    static func mk(name: String, M: Int, N: Int, P: Int, teMs: Int, tvAB: Int, tvBA: Int) -> SimulationConfig {
//        SimulationConfig(name: name, M: M, N: N, P: P, tvMsAB: tvAB, tvMsBA: tvBA, teMsPerPacker: Array(repeating: teMs, count: P))
//    }
//}
//
//// MARK: - AsyncSemaphore (counting)
//
//actor AsyncSemaphore {
//    private var count: Int
//    private var waiters: [CheckedContinuation<Void, Never>] = []
//
//    init(_ initial: Int) { self.count = initial }
//
//    func acquire() async {
//        if count > 0 { count -= 1; return }
//        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in waiters.append(cont) }
//    }
//
//    func release() {
//        if !waiters.isEmpty { waiters.removeFirst().resume() }
//        else { count += 1 }
//    }
//
//    func value() -> Int { count }
//}
//
//// MARK: - Pause Controller
//
//actor PauseController {
//    private var paused = false
//    private var waiters: [CheckedContinuation<Void, Never>] = []
//
//    func setPaused(_ p: Bool) {
//        paused = p
//        if !p { for c in waiters { c.resume() }; waiters.removeAll() }
//    }
//    func isPaused() -> Bool { paused }
//    func waitIfPaused() async { if paused { await withCheckedContinuation { waiters.append($0) } } }
//}
//
//// MARK: - Timed (wall-clock) Work Runner
//
//struct TimedWork {
//    static var tickNs: UInt64 = 16_666_667 // ~60 FPS default (calibrated on launch)
//
//    static func run(durationMs: Int, pause: PauseController?, progress: @escaping @MainActor (Double) -> Void) async {
//        let dur = max(1, durationMs)
//        let clock = ContinuousClock()
//        let start = clock.now
//        let end   = start.advanced(by: .milliseconds(dur))
//
//        while clock.now < end {
//            if Task.isCancelled { return }
//            await pause?.waitIfPaused()
//            let elapsed = start.duration(to: clock.now)
//            // Convert Duration to milliseconds
//            let elapsedMs = Double(elapsed.components.seconds) * 1000.0 + Double(elapsed.components.attoseconds) / 1_000_000_000_000.0
//            let p = min(1.0, elapsedMs / Double(dur))
//            progress(p)
//            try? await Task.sleep(nanoseconds: tickNs)
//        }
//        progress(1.0)
//    }
//}
//
//// MARK: - CPU-bound Work (calibrated)
//
//struct CPUWork {
//    static var intensity: Int = 35_000 // loop multiplier
//    static var unitsPerMs: Double = 500.0 // set by CPUCalibrator
//
//    @inline(__always)
//    private static func mix(_ x: UInt64) -> UInt64 {
//        var z = x &* 0x9E3779B97F4A7C15
//        z ^= z >> 33
//        z &*= 0xC2B2AE3D27D4EB4F
//        z ^= z >> 29
//        return z
//    }
//
//    // Raw burn used for calibration (no progress callbacks)
//    static func rawBurn(units: Int) async {
//        let iterations = max(1, units) &* intensity
//        var rng: UInt64 = 0x123456789ABCDEF0
//        var s: UInt64 = 0
//        for i in 0..<iterations {
//            s &+= mix(UInt64(i) ^ rng)
//            if i % 4096 == 0 { await Task.yield() }
//            if Task.isCancelled { return }
//        }
//        rng &+= s
//    }
//
//    // CPU-bound run with progress
//    static func run(workUnits: Int, pause: PauseController?, progress: @escaping @MainActor (Double) -> Void) async {
//        let totalUnits = max(1, workUnits)
//        let steps = max(1, min(200, totalUnits / 10))
//        let unitsPerStep = max(1, totalUnits / steps)
//        var rng: UInt64 = 0x123456789ABCDEF0
//
//        @inline(__always) func burn(_ u: Int) async {
//            let iterations = u &* intensity
//            var s: UInt64 = 0
//            for i in 0..<iterations {
//                s &+= mix(UInt64(i) ^ rng)
//                if i % 2048 == 0 { await Task.yield() }
//                if Task.isCancelled { return }
//            }
//            rng &+= s
//        }
//
//        for step in 1...steps {
//            await pause?.waitIfPaused()
//            await burn(unitsPerStep)
//            progress(Double(step) / Double(steps))
//        }
//    }
//}
//
//enum CPUCalibrator {
//    /// Returns estimated workUnits per millisecond for current device/load.
//    static func calibrate(sampleMs: Int = 800, initialUnits: Int = 200) async -> Double {
//        let clock = ContinuousClock()
//        var units = initialUnits
//        // Ramp up until we reach a measurable duration
//        while true {
//            let t0 = clock.now
//            await CPUWork.rawBurn(units: units)
//            let dt = t0.duration(to: clock.now)
//            let ms = Double(dt.components.seconds) * 1000.0 + Double(dt.components.attoseconds) / 1_000_000_000_000.0
//            if ms >= Double(sampleMs) * 0.5 { break }
//            units *= 2
//        }
//        // First estimate
//        var estimates: [Double] = []
//        for _ in 0..<3 {
//            let targetUnits = max(1, Int(Double(units) * (Double(sampleMs) / max(1.0, Double(sampleMs)))))
//            let t0 = clock.now
//            await CPUWork.rawBurn(units: targetUnits)
//            let dt = t0.duration(to: clock.now)
//            let ms = Double(dt.components.seconds) * 1000.0 + Double(dt.components.attoseconds) / 1_000_000_000_000.0
//            let upms = Double(targetUnits) / max(1.0, ms)
//            estimates.append(upms)
//        }
//        // median
//        estimates.sort()
//        return estimates[estimates.count/2]
//    }
//}
//
//enum UICalibrator {
//    static func calibrateTick(samples: Int = 60, targetNs: UInt64 = 16_666_667) async -> UInt64 {
//        let clock = ContinuousClock()
//        var observed: [UInt64] = []
//        for _ in 0..<samples {
//            let t0 = clock.now
//            try? await Task.sleep(nanoseconds: targetNs)
//            let dt = t0.duration(to: clock.now)
//            let ns = UInt64(dt.components.seconds) * 1_000_000_000 + UInt64(dt.components.attoseconds / 1_000_000_000)
//            observed.append(ns)
//        }
//        observed.sort()
//        return max(1_000_000, observed[observed.count/2]) // ≥1ms
//    }
//}
//
//// MARK: - UI Models
//
//enum PackerStatus: String { case empacotando, colocando, dormindo }
//
//enum TrainStatus: String { case parado, carregando, viajandoAtoB, viajandoBtoA }
//
//struct PackerUI: Identifiable, Equatable {
//    let id: Int
//    var status: PackerStatus = .empacotando
//    var progress: Double = 0 // 0..1 within current packing cycle
//    var teMs: Int = 0        // current duration for this packer
//}
//
//@MainActor
//@Observable
//final class SimulationUI {
//    // live state
//    var depotCount: Int = 0
//    var depotCapacity: Int = 0
//    var trainStatus: TrainStatus = .parado
//    var trainProgress: Double = 0
//    var packers: [PackerUI] = []
//    var log: [String] = []
//
//    // control
//    var isRunning: Bool = false
//    var isPaused: Bool = false
//    var mode: WorkMode = .timeBound
//
//    // timings (for display)
//    var tvMsAB: Int = 0
//    var tvMsBA: Int = 0
//
//    // metrics
//    var metricEmptyPlusFull: Int = 0
//    var metricM: Int = 0
//    var metricEmptyPlusFullOK: Bool = true
//    var metricDepotInvariantOK: Bool = true
//    var producerRatePerSec: Double = 0
//    var consumerRatePerSec: Double = 0
//    var trips: Int = 0
//    var avgTripSeconds: Double = 0
//
//    // calibrations
//    var calibratedTickMs: Double = 16.7
//    var cpuUnitsPerMs: Double = 500.0
//
//    func reset(for config: SimulationConfig) {
//        depotCount = 0
//        depotCapacity = config.M
//        trainStatus = .parado
//        trainProgress = 0
//        packers = (0..<config.P).map { idx in
//            PackerUI(id: idx, status: .empacotando, progress: 0, teMs: config.teMsPerPacker[idx])
//        }
//        tvMsAB = config.tvMsAB
//        tvMsBA = config.tvMsBA
//        log.removeAll()
//        isPaused = false
//        metricEmptyPlusFull = 0
//        metricM = config.M
//        metricEmptyPlusFullOK = true
//        metricDepotInvariantOK = true
//        producerRatePerSec = 0
//        consumerRatePerSec = 0
//        trips = 0
//        avgTripSeconds = 0
//    }
//
//    func pushLog(_ s: String) { log.append(s); if log.count > 400 { log.removeFirst(log.count - 400) } }
//}
//
//// MARK: - Simulation Core (Actors + Semaphores)
//
//actor SimulationCore {
//    // Semaphores
//    private let mutex = AsyncSemaphore(1)
//    private let empty: AsyncSemaphore
//    private let full: AsyncSemaphore
//
//    // Shared depot state
//    private var depotCount: Int = 0
//    private let capacity: Int
//
//    // Config (mutable where allowed)
//    private var config: SimulationConfig
//
//    // Controls
//    private var mode: WorkMode = .timeBound
//
//    // Pause
//    private let pauseCtl = PauseController()
//
//    // Tasks
//    private var tasks: [Task<Void, Never>] = []
//
//    // Metrics helpers
//    private var producedEvents: [TimeInterval] = []
//    private var consumedEvents: [TimeInterval] = []
//    private var tripStart: TimeInterval? = nil
//    private var tripDurations: [TimeInterval] = []
//
//    // UI
//    private unowned let ui: SimulationUI
//
//    init(config: SimulationConfig, ui: SimulationUI) {
//        self.config = config
//        self.capacity = config.M
//        self.empty = AsyncSemaphore(config.M)
//        self.full  = AsyncSemaphore(0)
//        self.ui = ui
//    }
//
//    // MARK: Control
//    func start() {
//        Task { @MainActor in ui.isRunning = true }
//
//        // Train
//        tasks.append(Task.detached { [weak self] in await self?.runTrain() })
//
//        // Packers
//        for id in 0..<config.P {
//            tasks.append(Task.detached { [weak self] in await self?.runPacker(id: id) })
//        }
//
//        // Metrics poller
//        tasks.append(Task.detached { [weak self] in await self?.metricsLoop() })
//    }
//
//    func stop() {
//        for t in tasks { t.cancel() }
//        tasks.removeAll()
//        Task { @MainActor in ui.isRunning = false }
//    }
//
//    func setPaused(_ p: Bool) async { await pauseCtl.setPaused(p); Task { @MainActor in ui.isPaused = p } }
//    func setMode(_ m: WorkMode) async { mode = m; Task { @MainActor in ui.mode = m } }
//
//    // Live updates (from UI)
//    func updateTravel(abMs: Int, baMs: Int) async {
//        config.tvMsAB = max(1, abMs)
//        config.tvMsBA = max(1, baMs)
//        let ab = config.tvMsAB
//        let ba = config.tvMsBA
//        await MainActor.run {
//            ui.tvMsAB = ab
//            ui.tvMsBA = ba
//        }
//    }
//    func updatePacker(id: Int, ms: Int) async {
//        guard id >= 0 && id < config.P else { return }
//        config.teMsPerPacker[id] = max(1, ms)
//        await MainActor.run {
//            if let i = ui.packers.firstIndex(where: { $0.id == id }) {
//                ui.packers[i].teMs = ms
//            }
//        }
//    }
//
//    // MARK: Packer Logic
//    private func runPacker(id: Int) async {
//        while !Task.isCancelled {
//            await pauseCtl.waitIfPaused()
//            await MainActor.run { [ui] in if let i = ui.packers.firstIndex(where: { $0.id == id }) { ui.packers[i].status = .empacotando; ui.packers[i].progress = 0 } }
//            let ms = config.teMsPerPacker[id]
//
//            switch mode {
//            case .timeBound:
//                await TimedWork.run(durationMs: ms, pause: pauseCtl) { [weak self] p in
//                    guard let self else { return }
//                    Task { @MainActor in if let i = self.ui.packers.firstIndex(where: { $0.id == id }) { self.ui.packers[i].progress = p } }
//                }
//            case .cpuBound:
//                let units = await max(1, Int((CPUWork.unitsPerMs * Double(ms)).rounded()))
//                await CPUWork.run(workUnits: units, pause: pauseCtl) { [weak self] p in
//                    guard let self else { return }
//                    Task { @MainActor in if let i = self.ui.packers.firstIndex(where: { $0.id == id }) { self.ui.packers[i].progress = p } }
//                }
//            }
//            if Task.isCancelled { return }
//
//            // Deposit
//            let emptyVal = await empty.value()
//            if emptyVal == 0 { await MainActor.run { [ui] in if let i = ui.packers.firstIndex(where: { $0.id == id }) { ui.packers[i].status = .dormindo }; ui.pushLog("E#\(id) aguardando espaço (depósito cheio)") } }
//            await empty.acquire()
//            await pauseCtl.waitIfPaused()
//
//            await MainActor.run { [ui] in if let i = ui.packers.firstIndex(where: { $0.id == id }) { ui.packers[i].status = .colocando } }
//            await mutex.acquire(); depotCount += 1; let newCount = depotCount; await mutex.release()
//            await MainActor.run { [ui] in ui.depotCount = newCount; ui.pushLog("E#\(id) colocou caixa → \(newCount)/\(ui.depotCapacity)") }
//            await full.release()
//            producedEvents.append(CFAbsoluteTimeGetCurrent())
//        }
//    }
//
//    // MARK: Train Logic (Batch consumer)
//    private func runTrain() async {
//        while !Task.isCancelled {
//            await pauseCtl.waitIfPaused()
//            let n = config.N
//            await MainActor.run { [ui] in
//                ui.trainStatus = .parado
//                ui.trainProgress = 0
//                ui.pushLog("Trem parado em A (aguardando \(n) caixas)")
//            }
//            for _ in 0..<n { await full.acquire() }
//            if Task.isCancelled { return }
//            await pauseCtl.waitIfPaused()
//
//            await MainActor.run { [ui] in
//                ui.trainStatus = .carregando
//                ui.pushLog("Carregando \(n) caixas…")
//            }
//            for _ in 0..<n {
//                await mutex.acquire(); depotCount -= 1; let newCount = depotCount; await mutex.release()
//                await MainActor.run { [ui] in ui.depotCount = newCount }
//                await empty.release()
//                consumedEvents.append(CFAbsoluteTimeGetCurrent())
//            }
//
//            tripStart = CFAbsoluteTimeGetCurrent()
//
//            // A->B
//            await MainActor.run { [ui] in ui.trainStatus = .viajandoAtoB }
//            switch mode {
//            case .timeBound:
//                await TimedWork.run(durationMs: config.tvMsAB, pause: pauseCtl) { [weak self] p in guard let self else { return }; Task { @MainActor in self.ui.trainProgress = p } }
//            case .cpuBound:
//                let units = await max(1, Int((CPUWork.unitsPerMs * Double(config.tvMsAB)).rounded()))
//                await CPUWork.run(workUnits: units, pause: pauseCtl) { [weak self] p in guard let self else { return }; Task { @MainActor in self.ui.trainProgress = p } }
//            }
//            if Task.isCancelled { return }
//
//            // B->A
//            await MainActor.run { [ui] in ui.trainStatus = .viajandoBtoA }
//            switch mode {
//            case .timeBound:
//                await TimedWork.run(durationMs: config.tvMsBA, pause: pauseCtl) { [weak self] p in guard let self else { return }; Task { @MainActor in self.ui.trainProgress = p } }
//            case .cpuBound:
//                let units = await max(1, Int((CPUWork.unitsPerMs * Double(config.tvMsBA)).rounded()))
//                await CPUWork.run(workUnits: units, pause: pauseCtl) { [weak self] p in guard let self else { return }; Task { @MainActor in self.ui.trainProgress = p } }
//            }
//            if Task.isCancelled { return }
//
//            if let start = tripStart {
//                let dur = CFAbsoluteTimeGetCurrent() - start
//                tripDurations.append(dur)
//                Task { @MainActor in self.ui.trips += 1; let avg = await tripDurations.reduce(0, +) / Double(max(1, tripDurations.count)); self.ui.avgTripSeconds = avg }
//            }
//            await MainActor.run { [ui] in ui.pushLog("Trem retornou a A") }
//        }
//    }
//
//    // MARK: Metrics loop
//    private func metricsLoop() async {
//        let window: TimeInterval = 10.0
//        while !Task.isCancelled {
//            let e = await empty.value(); let f = await full.value(); let sum = e + f
//            let depotOK = (0 <= depotCount && depotCount <= capacity)
//            let sumOK = (sum == capacity)
//
//            let now = CFAbsoluteTimeGetCurrent()
//            producedEvents = producedEvents.filter { now - $0 <= window }
//            consumedEvents = consumedEvents.filter { now - $0 <= window }
//            let prodRate = Double(producedEvents.count) / window
//            let consRate = Double(consumedEvents.count) / window
//
//            await MainActor.run { [ui, capacity] in
//                ui.metricEmptyPlusFull = sum
//                ui.metricM = capacity
//                ui.metricEmptyPlusFullOK = sumOK
//                ui.metricDepotInvariantOK = depotOK
//                ui.producerRatePerSec = prodRate
//                ui.consumerRatePerSec = consRate
//            }
//            try? await Task.sleep(nanoseconds: 250_000_000)
//        }
//    }
//}
//
//// MARK: - Pretty helpers
//
//extension PackerStatus {
//    var label: String { switch self { case .empacotando: "empacotando"; case .colocando: "colocando"; case .dormindo: "dormindo (depósito cheio)" } }
//    var color: Color { switch self { case .empacotando: .blue; case .colocando: .green; case .dormindo: .purple } }
//}
//
//extension TrainStatus { var label: String { switch self { case .parado: "parado (aguardando N caixas)"; case .carregando: "carregando"; case .viajandoAtoB: "viajando de A para B"; case .viajandoBtoA: "viajando de B para A" } } }
//
//// MARK: - Train Track View
//
//struct TrainTrackView: View {
//    let status: TrainStatus
//    let progress: Double // 0..1 within current leg
//
//    var body: some View {
//        GeometryReader { geo in
//            let w = geo.size.width
//            let h = geo.size.height
//            let y = h * 0.6
//
//            ZStack(alignment: .topLeading) {
//                Path { p in p.move(to: CGPoint(x: 20, y: y)); p.addLine(to: CGPoint(x: w - 20, y: y)) }
//                    .stroke(Color.secondary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
//
//                ForEach(0..<20, id: \.self) { i in
//                    let x = 20 + (w - 40) * CGFloat(i) / 19
//                    Path { p in p.move(to: CGPoint(x: x, y: y - 10)); p.addLine(to: CGPoint(x: x, y: y + 10)) }
//                        .stroke(Color.secondary.opacity(0.5), lineWidth: 2)
//                }
//
//                Text("A").position(x: 10, y: y - 18)
//                Text("B").position(x: w - 10, y: y - 18)
//
//                let clamped = min(max(progress, 0), 1)
//                let xPos: CGFloat = switch status {
//                case .viajandoAtoB: 20 + (w - 40) * CGFloat(clamped)
//                case .viajandoBtoA: 20 + (w - 40) * CGFloat(1 - clamped)
//                case .parado, .carregando: 20
//                }
//
//                Circle()
//                    .fill(color(for: status))
//                    .frame(width: 28, height: 28)
//                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
//                    .position(x: xPos, y: y)
//                    .shadow(radius: 3)
//
//                Text(status.label)
//                    .font(.caption)
//                    .padding(6)
//                    .background(.ultraThinMaterial, in: Capsule())
//                    .position(x: w/2, y: y - 36)
//            }
//        }
//        .frame(height: 120)
//    }
//
//    private func color(for status: TrainStatus) -> Color { switch status { case .parado: .gray; case .carregando: .yellow; case .viajandoAtoB: .blue; case .viajandoBtoA: .green } }
//}
//
//// MARK: - SwiftUI Frontend
//
//struct ContentView: View {
//    @State private var ui = SimulationUI()
//    @State private var selectedScenario: Scenario = .basicBalanced
//    @State private var core: SimulationCore? = nil
//
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 12) {
//                headerControls
//                depotGauge
//                TrainTrackView(status: ui.trainStatus, progress: ui.trainProgress)
//                packersGrid
//                timingsPanel
//                calibrationPanel
//                metricsPanel
//                logView
//            }
//            .padding()
//            .navigationTitle("Cargo Train – Producer/Batch Consumer (ms + CPU toggle)")
//            .onAppear {
//                Task {
//                    // Calibrate UI tick & CPU units/ms at launch
//                    let ns = await UICalibrator.calibrateTick()
//                    TimedWork.tickNs = ns
//                    ui.calibratedTickMs = Double(ns) / 1_000_000.0
//
//                    let upms = await CPUCalibrator.calibrate()
//                    CPUWork.unitsPerMs = upms
//                    ui.cpuUnitsPerMs = upms
//
//                    applyConfig(selectedScenario.config)
//                }
//            }
//            .onChange(of: selectedScenario) { _, newValue in
//                if ui.isRunning { stopRun() }
//                applyConfig(newValue.config)
//            }
//        }
//    }
//
//    // MARK: Sections
//
//    private var headerControls: some View {
//        HStack(spacing: 12) {
//            Text("Scenario:")
//            Picker("Scenario", selection: $selectedScenario) { ForEach(Scenario.allCases) { sc in Text(sc.config.name).tag(sc) } }
//                .pickerStyle(.menu)
//
//            Divider()
//
//            Picker("Mode", selection: Binding(get: { ui.mode }, set: { setMode($0) })) {
//                ForEach(WorkMode.allCases) { m in Text(m.rawValue).tag(m) }
//            }
//            .pickerStyle(.segmented)
//            .frame(maxWidth: 300)
//
//            Spacer()
//            Button(ui.isRunning ? "Stop" : "Start") { toggleRun() }.buttonStyle(.borderedProminent)
//            Button(ui.isPaused ? "Resume" : "Pause") { togglePause() }.buttonStyle(.bordered).disabled(!ui.isRunning)
//        }
//    }
//
//    private var depotGauge: some View {
//        VStack(alignment: .leading) {
//            Text("Depot: \(ui.depotCount)/\(ui.depotCapacity)")
//            ProgressView(value: Double(ui.depotCount), total: Double(max(1, ui.depotCapacity)))
//        }
//    }
//
//    private var packersGrid: some View {
//        ScrollView {
//            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
//                ForEach(ui.packers) { p in
//                    VStack(alignment: .leading, spacing: 8) {
//                        HStack { Text("Packer #\(p.id)").bold(); Spacer(); Text("te: \(p.teMs) ms").font(.caption.monospaced()) }
//                        Text("Status: \(p.status.label)").foregroundStyle(p.status.color)
//                        ProgressView(value: p.progress)
//                    }
//                    .padding()
//                    .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThickMaterial))
//                }
//            }
//            .frame(maxWidth: .infinity)
//        }
//    }
//
//    private var timingsPanel: some View {
//        GroupBox("Timings (milliseconds)") {
//            VStack(alignment: .leading, spacing: 8) {
//                HStack {
//                    Text("Train A→B:")
//                    Stepper(value: Binding(get: { ui.tvMsAB }, set: { setTrainAB($0) }), in: 50...60_000, step: 50) { Text("\(ui.tvMsAB) ms") }
//                    Spacer()
//                    Text("B→A:")
//                    Stepper(value: Binding(get: { ui.tvMsBA }, set: { setTrainBA($0) }), in: 50...60_000, step: 50) { Text("\(ui.tvMsBA) ms") }
//                }
//                Divider()
//                ForEach(ui.packers) { p in
//                    HStack { Text("Packer #\(p.id)")
//                        Stepper(value: Binding(get: { p.teMs }, set: { new in setPacker(id: p.id, newMs: new) }), in: 50...60_000, step: 50) { Text("te: \(p.teMs) ms") }
//                    }
//                }
//            }
//        }
//    }
//
//    private var calibrationPanel: some View {
//        GroupBox("Calibration") {
//            VStack(alignment: .leading, spacing: 8) {
//                HStack { Text("UI tick ≈ \(String(format: "%.1f", ui.calibratedTickMs)) ms"); Button("Recalibrate UI") { Task { let ns = await UICalibrator.calibrateTick(); TimedWork.tickNs = ns; ui.calibratedTickMs = Double(ns)/1_000_000.0 } } }
//                HStack { Text("CPU units/ms ≈ \(String(format: "%.1f", ui.cpuUnitsPerMs))"); Button("Recalibrate CPU") { Task { let upms = await CPUCalibrator.calibrate(); CPUWork.unitsPerMs = upms; ui.cpuUnitsPerMs = upms } } }
//                Text("CPU-bound usa \"units/ms\" para converter ms definidos em trabalho de CPU real.").font(.caption).foregroundStyle(.secondary)
//            }
//        }
//    }
//
//    private var metricsPanel: some View {
//        GroupBox("Metrics") {
//            VStack(alignment: .leading, spacing: 6) {
//                HStack { Label("empty+full == M", systemImage: ui.metricEmptyPlusFullOK ? "checkmark.seal" : "xmark.seal").foregroundStyle(ui.metricEmptyPlusFullOK ? .green : .red); Spacer(); Text("sum: \(ui.metricEmptyPlusFull)  M: \(ui.metricM)").font(.caption.monospaced()) }
//                HStack { Label("0 ≤ depot ≤ M", systemImage: ui.metricDepotInvariantOK ? "checkmark.seal" : "xmark.seal").foregroundStyle(ui.metricDepotInvariantOK ? .green : .red) }
//                HStack { Text("Producer: \(String(format: "%.2f", ui.producerRatePerSec)) boxes/s"); Spacer(); Text("Consumer: \(String(format: "%.2f", ui.consumerRatePerSec)) boxes/s") }
//                HStack { Text("Trips: \(ui.trips)"); Spacer(); Text("Avg round trip: \(String(format: "%.2f", ui.avgTripSeconds)) s") }
//            }
//        }
//    }
//
//    private var logView: some View {
//        GroupBox("Log") { ScrollView { LazyVStack(alignment: .leading, spacing: 4) { ForEach(Array(ui.log.enumerated()), id: \.0) { _, line in Text(line).font(.caption.monospaced()) } } }.frame(maxHeight: 180) }
//    }
//
//    // MARK: Actions
//
//    private func applyConfig(_ cfg: SimulationConfig) {
//        ui.reset(for: cfg)
//        if let old = core { Task { await old.stop() } }
//        core = SimulationCore(config: cfg, ui: ui)
//        if let newCore = core { Task { await newCore.setMode(ui.mode) } }
//    }
//
//    private func toggleRun() { ui.isRunning ? stopRun() : startRun() }
//    private func startRun() { guard let core else { return }; Task { await core.start() }; ui.isRunning = true }
//    private func stopRun() { ui.isRunning = false; ui.isPaused = false; if let core { Task { await core.stop() } } }
//    private func togglePause() { guard let core, ui.isRunning else { return }; Task { await core.setPaused(!ui.isPaused) } }
//    private func setMode(_ m: WorkMode) { ui.mode = m; if let core { Task { await core.setMode(m) } } }
//
//    private func setTrainAB(_ v: Int) { if let core { Task { await core.updateTravel(abMs: v, baMs: ui.tvMsBA) } }; ui.tvMsAB = v }
//    private func setTrainBA(_ v: Int) { if let core { Task { await core.updateTravel(abMs: ui.tvMsAB, baMs: v) } }; ui.tvMsBA = v }
//    private func setPacker(id: Int, newMs: Int) { if let core { Task { await core.updatePacker(id: id, ms: newMs) } }; if let i = ui.packers.firstIndex(where: { $0.id == id }) { ui.packers[i].teMs = newMs } }
//}
//








//  ContentView.swift
//
//
//import SwiftUI
//import Foundation
//import Observation
//
//// MARK: - Scenario config and policies
//public enum WaitPolicy: String, Codable, CaseIterable, Identifiable {
//    case fifo
//    case lifo
//    case random
//    public var id: Self { self }
//    var label: String {
//        switch self {
//        case .fifo: return "FIFO"
//        case .lifo: return "LIFO"
//        case .random: return "Random"
//        }
//    }
//}
//
//public struct ScenarioConfig: Identifiable, Hashable, Codable {
//    public var id: String { title }
//    let title: String
//    let description: String
//    let M: Int
//    let N: Int
//    let tvMs: Int
//    let packerTeMs: [Int]
//    let policy: WaitPolicy
//}
//
//public enum SimulationScenario: String, CaseIterable, Identifiable {
//    case balanced
//    case depositoLotaRapido
//    case producaoLenta
//    case NIgualM
//    case NPequeno
//    case NPertoDeM
//    case tvMuitoCurto
//    case tvMuitoLongo
//    case teGigante
//    case stressMAlto
//    case NEh1
//    case starvationPackerLIFO
//    case starvationPraticaTrem
//    case aleatorioJustica
//    case oscilatorio
//    case produtorDominante
//
//    public var id: Self { self }
//
//    var config: ScenarioConfig {
//        switch self {
//        case .balanced:
//            return .init(
//                title: "Básico balanceado",
//                description: "Fluxo estável; trem parte regularmente.",
//                M: 20, N: 10, tvMs: 1500,
//                packerTeMs: [300, 450, 600, 900],
//                policy: .fifo
//            )
//        case .depositoLotaRapido:
//            return .init(
//                title: "Depósito lota rápido",
//                description: "Produção ≫ consumo; empacotadores ‘dormem’ muito.",
//                M: 20, N: 10, tvMs: 3000,
//                packerTeMs: [120, 140, 160, 180, 200, 220, 240, 260],
//                policy: .fifo
//            )
//        case .producaoLenta:
//            return .init(
//                title: "Produção lenta",
//                description: "Trem aguarda juntar N com frequência.",
//                M: 20, N: 10, tvMs: 1000,
//                packerTeMs: [1500, 1700],
//                policy: .fifo
//            )
//        case .NIgualM:
//            return .init(
//                title: "N = M",
//                description: "Parte somente cheio; ciclos 0→10→0.",
//                M: 10, N: 10, tvMs: 1500,
//                packerTeMs: [300, 300, 450, 600, 750],
//                policy: .fifo
//            )
//        case .NPequeno:
//            return .init(
//                title: "N pequeno",
//                description: "Viagens frequentes; pouco bloqueio.",
//                M: 20, N: 2, tvMs: 800,
//                packerTeMs: [400, 500, 600],
//                policy: .fifo
//            )
//        case .NPertoDeM:
//            return .init(
//                title: "N perto de M",
//                description: "Lotes raros; muitos dormindo próximo de M.",
//                M: 20, N: 18, tvMs: 1000,
//                packerTeMs: [300, 350, 400, 450, 500, 550],
//                policy: .fifo
//            )
//        case .tvMuitoCurto:
//            return .init(
//                title: "tv muito curto",
//                description: "Gargalo é produção; trem pronto quase sempre.",
//                M: 20, N: 10, tvMs: 120,
//                packerTeMs: [300, 400, 600, 800, 800, 700],
//                policy: .fifo
//            )
//        case .tvMuitoLongo:
//            return .init(
//                title: "tv muito longo",
//                description: "Depósito enche; longa dormência dos empacotadores.",
//                M: 20, N: 10, tvMs: 5000,
//                packerTeMs: [280, 320, 360, 400, 440, 480],
//                policy: .fifo
//            )
//        case .teGigante:
//            return .init(
//                title: "te gigante",
//                description: "Raramente junta N; trem quase sempre parado.",
//                M: 20, N: 10, tvMs: 1000,
//                packerTeMs: [3000, 3300, 3600, 3900],
//                policy: .fifo
//            )
//        case .stressMAlto:
//            return .init(
//                title: "Stress M alto",
//                description: "Escala; invariantes estáveis em M grande.",
//                M: 100, N: 10, tvMs: 1200,
//                packerTeMs: [200,220,240,260,280,300,320,340,360,380,400,420],
//                policy: .fifo
//            )
//        case .NEh1:
//            return .init(
//                title: "Borda N=1",
//                description: "Caso PC clássico; consumo item a item.",
//                M: 20, N: 1, tvMs: 800,
//                packerTeMs: [450, 550],
//                policy: .fifo
//            )
//        case .starvationPackerLIFO:
//            return .init(
//                title: "(Demo) LIFO pode faminto",
//                description: "LIFO privilegia recém-chegados → antigos podem ficar esperando.",
//                M: 8, N: 6, tvMs: 1200,
//                packerTeMs: Array(repeating: 300, count: 8),
//                policy: .lifo
//            )
//        case .starvationPraticaTrem:
//            return .init(
//                title: "(Quase) starvation do trem",
//                description: "N muito grande vs produção lenta → espera ‘infinita’ prática.",
//                M: 40, N: 30, tvMs: 1500,
//                packerTeMs: [1800, 2000, 2200],
//                policy: .fifo
//            )
//        case .aleatorioJustica:
//            return .init(
//                title: "Aleatório (justiça imprevisível)",
//                description: "Oscilação e justiça imprevisível entre empacotadores.",
//                M: 20, N: 10, tvMs: 1200,
//                packerTeMs: [300, 350, 400, 450, 500, 550],
//                policy: .random
//            )
//        case .oscilatorio:
//            return .init(
//                title: "Oscilatório",
//                description: "Depósito oscila perto do limite; padrões de ‘dorme/retoma’.",
//                M: 20, N: 10, tvMs: 900,
//                packerTeMs: [800, 900, 1000, 1100],
//                policy: .fifo
//            )
//        case .produtorDominante:
//            return .init(
//                title: "Produtor dominante",
//                description: "Um produtor ‘domina’ inserções (te muito menor).",
//                M: 20, N: 10, tvMs: 1200,
//                packerTeMs: [120, 1200, 1400, 1600],
//                policy: .fifo
//            )
//        }
//    }
//}
//
//// MARK: - AsyncSemaphore (configurable policy)
//public actor AsyncSemaphore {
//    private var value: Int
//    private var waiters: [CheckedContinuation<Void, Never>] = []
//    private let policy: WaitPolicy
//
//    public init(_ initial: Int, policy: WaitPolicy = .fifo) {
//        self.value = initial
//        self.policy = policy
//    }
//
//    public func wait() async {
//        if value > 0 {
//            value -= 1
//            return
//        }
//        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
//            waiters.append(cont)
//        }
//    }
//
//    public func signal() {
//        if !waiters.isEmpty {
//            let cont: CheckedContinuation<Void, Never>
//            switch policy {
//            case .fifo:
//                cont = waiters.removeFirst()
//            case .lifo:
//                cont = waiters.removeLast()
//            case .random:
//                let i = Int.random(in: 0..<waiters.count)
//                cont = waiters.remove(at: i)
//            }
//            cont.resume()
//        } else {
//            value += 1
//        }
//    }
//
//    /// Somente para heurística de UI (leitura não atômica do contador)
//    public func approxValue() -> Int { value }
//}
//
//// MARK: - Depósito (protege contagem com Actor)
//public actor Deposito {
//    private(set) var caixas: Int = 0
//    func push() { caixas += 1 }
//    func pop()  { caixas -= 1 }
//    var count: Int { caixas }
//}
//
//// MARK: - Utilitários de tempo/CPU-bound
//extension Duration {
//    var secondsDouble: Double {
//        let c = self.components
//        return Double(c.seconds) + Double(c.attoseconds) / 1_000_000_000_000_000_000.0
//    }
//    var millisecondsDouble: Double { secondsDouble * 1000.0 }
//}
//
//struct SpinTimer {
//    /// CPU-bound por `durationMs` com frames ~`fps`, a própria task gera os frames.
//    static func cpuBurn(
//        durationMs: Int,
//        fps: Int = 60,
//        onFrame: @MainActor @Sendable @escaping (Double) -> Void
//    ) async {
//        let clock = ContinuousClock()
//        let start = clock.now
//        let frameInterval = Duration.nanoseconds(1_000_000_000 / max(1, fps))
//        var nextFrame = start + frameInterval // first frame after one interval
//        let deadline = start + .milliseconds(durationMs)
//
//        @inline(__always) func burnChunk() {
//            var acc = 0
//            for k in 1...2000 { acc &+= k &* k }
//            _ = acc
//        }
//
//        while clock.now < deadline {
//            burnChunk()
//            if clock.now >= nextFrame {
//                let elapsed = clock.now - start
//                let p = min(1.0, max(0.0, elapsed.millisecondsDouble / Double(durationMs)))
//                onFrame(p)
//                nextFrame += frameInterval
//            }
//            await Task.yield() // coopera com o escalonador, sem dormir
//        }
//        onFrame(1.0)
//    }
//}
//
//// MARK: - Estados para UI
//enum PackerStatus: String, Codable, Equatable {
//    case empacotando
//    case colocando
//    case dormindo
//}
//
//enum TrainStatus: Equatable, Codable {
//    case paradoAguardando(n: Int)
//    case carregando(n: Int)
//    case viajandoAParaB
//    case viajandoBParaA
//
//    var label: String {
//        switch self {
//        case .paradoAguardando(let n): return "parado (aguardando \(n) caixas em A)"
//        case .carregando(let n):       return "carregando \(n) caixas"
//        case .viajandoAParaB:          return "viajando de A para B"
//        case .viajandoBParaA:          return "viajando de B para A"
//        }
//    }
//}
//
//struct PackerViewModel: Identifiable, Hashable {
//    let id: Int
//    var status: PackerStatus = .empacotando
//    var progress: Double = 0
//    var teMs: Int
//}
//
//// MARK: - Simulation Model (MainActor)
//@MainActor
//@Observable
//final class SimulationModel {
//    // Configuração
//    let M: Int
//    let N: Int
//    let tvMs: Int
//
//    // Semáforos e depósito
//    private let empty: AsyncSemaphore
//    private let full: AsyncSemaphore
//    private let deposito: Deposito
//
//    // UI State
//    var depositoCount: Int = 0
//    var packers: [PackerViewModel] = []
//    var trainStatus: TrainStatus
//    var trainProgress: Double = 0
//
//    @ObservationIgnored private var tasks: [Task<Void, Never>] = []
//    private var started: Bool = false
//
//    init(M: Int, N: Int, tvMs: Int, packerTeMs: [Int], policy: WaitPolicy) {
//        self.M = M
//        self.N = N
//        self.tvMs = tvMs
//        self.empty = AsyncSemaphore(M, policy: policy)
//        self.full = AsyncSemaphore(0, policy: policy)
//        self.deposito = Deposito()
//        self.trainStatus = .paradoAguardando(n: N)
//        self.packers = packerTeMs.enumerated().map { idx, te in
//            PackerViewModel(id: idx + 1, status: .empacotando, progress: 0, teMs: te)
//        }
//    }
//
//    deinit {
//        for t in tasks { t.cancel() }
//    }
//
//    func start() {
//        guard !started else { return }
//        started = true
//
//        // Empacotadores
//        for idx in packers.indices {
//            let id = packers[idx].id
//            let teMs = packers[idx].teMs
//            let empty = self.empty
//            let full = self.full
//            let deposito = self.deposito
//
//            let task = Task.detached(priority: .userInitiated) { [weak self] in
//                guard let self else { return }
//                while !Task.isCancelled {
//                    // 1) Empacotar (CPU-bound + frames pela própria task)
//                    await self.updatePacker(id: id, status: .empacotando)
//                    await SpinTimer.cpuBurn(durationMs: teMs) { p in
//                        self.updatePackerProgress(id: id, p)
//                    }
//
//                    // 2) Heurística de UI — mostrar dormindo se não há espaço
//                    let approx = await empty.approxValue()
//                    if approx == 0 {
//                        await self.updatePacker(id: id, status: .dormindo)
//                    }
//
//                    // 3) Esperar vaga → inserir → sinalizar full
//                    await empty.wait()
//                    await self.updatePacker(id: id, status: .colocando)
//                    await deposito.push()
//                    let count = await deposito.count
//                    await self.setDepositoCount(count)
//                    await full.signal()
//
//                    // volta ao laço
//                }
//            }
//            tasks.append(task)
//        }
//
//        // Trem
//        let N = self.N
//        let tvMs = self.tvMs
//        let empty = self.empty
//        let full = self.full
//        let deposito = self.deposito
//
//        let trainTask = Task.detached(priority: .userInitiated) { [weak self] in
//            guard let self else { return }
//            while !Task.isCancelled {
//                // 1) Aguardar N caixas
//                await self.setTrainStatus(.paradoAguardando(n: N))
//                for _ in 0..<N { await full.wait() }
//
//                // 2) Carregar N caixas
//                await self.setTrainStatus(.carregando(n: N))
//                for _ in 0..<N {
//                    await deposito.pop()
//                    let count = await deposito.count
//                    await self.setDepositoCount(count)
//                    await empty.signal()
//                }
//
//                // 3) Viajar A → B (CPU-bound + frames pela própria task)
//                await self.setTrainStatus(.viajandoAParaB)
//                await SpinTimer.cpuBurn(durationMs: tvMs) { p in
//                    self.setTrainProgress(p)
//                }
//
//                // 4) Viajar B → A
//                await self.setTrainStatus(.viajandoBParaA)
//                await SpinTimer.cpuBurn(durationMs: tvMs) { p in
//                    self.setTrainProgress(p)
//                }
//            }
//        }
//        tasks.append(trainTask)
//    }
//
//    func stop() {
//        for t in tasks { t.cancel() }
//        tasks.removeAll()
//        started = false
//        // Reset UI state
//        depositoCount = 0
//        for i in packers.indices {
//            packers[i].status = .empacotando
//            packers[i].progress = 0
//        }
//        trainStatus = .paradoAguardando(n: N)
//        trainProgress = 0
//    }
//
//    // MARK: - UI Updates (MainActor)
//    func setDepositoCount(_ count: Int) {
//        depositoCount = count
//    }
//
//    func updatePacker(id: Int, status: PackerStatus) {
//        if let idx = packers.firstIndex(where: { $0.id == id }) {
//            packers[idx].status = status
//        }
//    }
//
//    func updatePackerProgress(id: Int, _ p: Double) {
//        if let idx = packers.firstIndex(where: { $0.id == id }) {
//            packers[idx].progress = p
//        }
//    }
//
//    func setTrainStatus(_ status: TrainStatus) {
//        trainStatus = status
//        switch status {
//        case .carregando:
//            // Reset progress when loading begins
//            trainProgress = 0
//        case .viajandoAParaB, .viajandoBParaA:
//            // Reset progress at the start of each travel leg to avoid flicker
//            trainProgress = 0
//        case .paradoAguardando:
//            // When waiting at A, ensure the rendered progress is at the A-end (0)
//            trainProgress = 0
//        }
//    }
//
//    func setTrainProgress(_ p: Double) {
//        trainProgress = p
//    }
//}
//
//// MARK: - SwiftUI
//struct ContentView: View {
//    @State private var selectedScenario: SimulationScenario = .balanced
//    @State private var isRunning: Bool = false
//    @State private var model: SimulationModel = SimulationModel(
//        M: SimulationScenario.balanced.config.M,
//        N: SimulationScenario.balanced.config.N,
//        tvMs: SimulationScenario.balanced.config.tvMs,
//        packerTeMs: SimulationScenario.balanced.config.packerTeMs,
//        policy: SimulationScenario.balanced.config.policy
//    )
//
//    @State var time: TimeInterval = 0
//
//    var body: some View {
//        VStack(spacing: 16) {
//            header
//            animation
//            packersGrid
//            Spacer(minLength: 8)
//        }
//        .padding()
//        .onAppear {
//            if isRunning { model.start() }
//        }
//        .onChange(of: selectedScenario) { _, newValue in
//            // If running, restart with the new scenario
//            if isRunning {
//                model.stop()
//                model = buildModel(from: newValue)
//                model.start()
//            }
//        }
//        .toolbar {
//            ToolbarItem(placement: .primaryAction) {
//                HStack(spacing: 8) {
//                    Picker("Cenário", selection: $selectedScenario) {
//                        ForEach(SimulationScenario.allCases) { s in
//                            Text(s.config.title).tag(s)
//                        }
//                    }
//                    .pickerStyle(.menu)
//
//                    if isRunning {
//                        Button {
//                            model.stop()
//                            isRunning = false
//                        } label: {
//                            Label("Parar", systemImage: "stop.fill")
//                        }
//                    } else {
//                        Button {
//                            model = buildModel(from: selectedScenario)
//                            model.start()
//                            isRunning = true
//                        } label: {
//                            Label("Iniciar", systemImage: "play.fill")
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    private func buildModel(from scenario: SimulationScenario) -> SimulationModel {
//        let cfg = scenario.config
//        return SimulationModel(M: cfg.M, N: cfg.N, tvMs: cfg.tvMs, packerTeMs: cfg.packerTeMs, policy: cfg.policy)
//    }
//
//    private var header: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(selectedScenario.config.title)
//                .font(.title2).bold()
//            Text(selectedScenario.config.description)
//                .font(.subheadline)
//                .foregroundStyle(.secondary)
//            Text("Depósito: \(model.depositoCount)/\(model.M)")
//                .font(.headline)
//            ProgressView(value: Double(model.depositoCount), total: Double(model.M))
//            HStack(spacing: 12) {
//                Chip(text: "N = \(model.N)")
//                Chip(text: "tv = \(model.tvMs) ms")
//                Chip(text: "Empacotadores: \(model.packers.count)")
//                Text("Timer: \(time)")
//            }
//        }.onAppear {
//            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
//                Task { @MainActor in
//                    time += 0.1
//                }
//            })
//        }
//    }
//
//    private var trainPanel: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Trem: \(model.trainStatus.label)")
//                .font(.title3)
//            ProgressView(value: trainProgress)
//        }
//        .padding()
//        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
//    }
//
//    var trainProgress: Double {
//        return model.trainStatus == .viajandoBParaA ? 1 - model.trainProgress : model.trainProgress
//    }
//
//    var trainDirection: CGFloat {
//        return model.trainStatus == .viajandoBParaA ? -1 : 1
//    }
//
//    private var animation: some View {
//        GeometryReader { geo in
//            let totalW = geo.size.width
//            let leftDockW = max(180.0, totalW * 0.1)
//            let rightDockW = max(220.0, totalW * 0.1)
//            let trainW: CGFloat = 92
//            let trainH: CGFloat = 92
//
//            let trackStart = leftDockW
//            let trackEnd   = totalW - rightDockW - trainW
//            let x = trackStart + max(0, trackEnd - trackStart) * trainProgress
//            let baselineY: CGFloat = 80
//
//            ZStack(alignment: .topLeading) {
//                // Left: depósito
//                DepositView(count: model.depositoCount, capacity: model.M, color: .blue)
//                    .frame(width: leftDockW, height: 120)
//                    .position(x: leftDockW / 2, y: baselineY)
//
//                // Right: destino
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(Color.green)
//                    .frame(width: rightDockW, height: 120)
//                    .position(x: totalW - rightDockW / 2, y: baselineY)
//
//                // Train at linear position
//                Image(.train)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: trainW, height: trainH)
//                    .scaleEffect(x: trainDirection, y: 1)
//                    .position(x: x + trainW / 2, y: baselineY)
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//        }
//        .frame(height: 200)
//    }
//
//    private var packersGrid: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Empacotadores")
//                .font(.headline)
//            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
//                ForEach(model.packers) { p in
//                    VStack(alignment: .leading, spacing: 8) {
//                        HStack {
//                            Text("E\(p.id)").bold()
//                            Spacer()
//                            Text(statusLabel(for: p.status))
//                                .foregroundStyle(.secondary)
//                        }
//                        PackerAnimationView(status: p.status, progress: p.progress)
//                            .frame(height: 56)
//                            .animation(.easeInOut(duration: 0.2), value: p.status)
//                        ProgressView(value: p.progress)
//                        HStack {
//                            Text("te: \(p.teMs) ms")
//                                .font(.caption)
//                                .foregroundStyle(.secondary)
//                            Spacer()
//                        }
//                    }
//                    .padding()
//                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
//                }
//            }
//        }
//    }
//
//    private func statusLabel(for s: PackerStatus) -> String {
//        switch s {
//        case .empacotando: return "empacotando"
//        case .colocando:   return "colocando"
//        case .dormindo:    return "dormindo (depósito cheio)"
//        }
//    }
//}
//
//struct Chip: View {
//    let text: String
//    var body: some View {
//        Text(text)
//            .font(.caption)
//            .padding(.horizontal, 8)
//            .padding(.vertical, 4)
//            .background(Color.accentColor.opacity(0.15))
//            .foregroundStyle(.primary)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//struct PackerAnimationView: View {
//    let status: PackerStatus
//    let progress: Double
//
//    var body: some View {
//        GeometryReader { geo in
//            let w = geo.size.width
//            let h = geo.size.height
//            ZStack {
//                // Conveyor belt background
//                BeltView(active: status != .dormindo)
//                    .frame(height: h * 0.42)
//                    .offset(y: h * 0.28)
//
//                // Moving box reflecting current status/progress
//                TimelineView(.animation) { ctx in
//                    let t = ctx.date.timeIntervalSinceReferenceDate
//                    let boxW = min(56, w * 0.22)
//                    let boxH = min(36, h * 0.60)
//                    let baseY = h * 0.28
//
//                    var posX: CGFloat = 12
//                    var posY: CGFloat = baseY
//                    var scale: CGFloat = 1.0
//
//                    switch status {
//                    case .empacotando:
//                        let travel = max(0, w - boxW - 24)
//                        posX = 12 + travel * progress
//                        posY = baseY - CGFloat(sin(progress * .pi)) * h * 0.06
//                    case .colocando:
//                        posX = (w - boxW) / 2
//                        posY = baseY - CGFloat(progress) * h * 0.42
//                    case .dormindo:
//                        posX = (w - boxW) / 2
//                        posY = baseY
//                        scale = 1.0 + 0.02 * CGFloat(sin(t * 1.2))
//                    }
//
//                    return RoundedRectangle(cornerRadius: 6, style: .continuous)
//                        .fill(status == .dormindo ? Color.gray.opacity(0.6) : Color.orange)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 6, style: .continuous)
//                                .stroke(Color.black.opacity(0.15), lineWidth: 1)
//                        )
//                        .frame(width: boxW, height: boxH)
//                        .position(x: posX + boxW / 2, y: posY)
//                        .scaleEffect(scale)
//                        .shadow(color: .black.opacity(0.10), radius: 3, x: 0, y: 2)
//                }
//
//                // Piston/press animating while packing
//                if status == .empacotando {
//                    PistonView(phase: progress)
//                        .frame(width: 22)
//                        .offset(x: -6, y: -h * 0.06)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .transition(.opacity)
//                }
//
//                // Zzz indicator when sleeping
//                if status == .dormindo {
//                    ZzzView()
//                        .frame(maxWidth: .infinity, alignment: .trailing)
//                        .padding(.trailing, 8)
//                        .offset(y: -h * 0.10)
//                        .transition(.opacity)
//                }
//            }
//            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
//            .overlay(
//                RoundedRectangle(cornerRadius: 10, style: .continuous)
//                    .stroke(.black.opacity(0.06), lineWidth: 1)
//            )
//        }
//    }
//}
//
//private struct BeltView: View {
//    let active: Bool
//    var body: some View {
//        TimelineView(.animation) { ctx in
//            let t = ctx.date.timeIntervalSinceReferenceDate
//            let phase = CGFloat(t * (active ? 1.6 : 0))
//            Canvas { context, size in
//                // Belt base
//                let rect = CGRect(origin: .zero, size: size)
//                let basePath = Path(roundedRect: rect, cornerRadius: 6)
//                context.fill(basePath, with: .color(Color(white: 0.16)))
//
//                // Moving vertical stripes
//                let stripeW: CGFloat = 12
//                let count = Int(size.width / stripeW) + 4
//                let offset = (phase.truncatingRemainder(dividingBy: 1)) * stripeW
//                for i in -2..<(count) {
//                    let x = CGFloat(i) * stripeW - offset
//                    let stripeRect = CGRect(x: x, y: 0, width: stripeW * 0.55, height: size.height)
//                    let stripePath = Path(stripeRect)
//                    context.fill(stripePath, with: .color(Color(white: 0.32)))
//                }
//
//                // Top highlight
//                let highlightRect = CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.18)
//                let highlightPath = Path(highlightRect)
//                context.fill(highlightPath, with: .linearGradient(
//                    Gradient(colors: [Color.white.opacity(0.25), .clear]),
//                    startPoint: CGPoint(x: 0, y: 0),
//                    endPoint: CGPoint(x: 0, y: size.height * 0.18)
//                ))
//            }
//        }
//        .opacity(active ? 1.0 : 0.55)
//    }
//}
//
//private struct PistonView: View {
//    let phase: Double // 0..1
//    var body: some View {
//        GeometryReader { geo in
//            let h = geo.size.height
//            let travel = h * 0.5 * CGFloat(sin(phase * .pi))
//            ZStack(alignment: .top) {
//                RoundedRectangle(cornerRadius: 3, style: .continuous)
//                    .fill(Color.gray.opacity(0.5))
//                    .frame(width: 4)
//                    .frame(maxHeight: .infinity)
//                RoundedRectangle(cornerRadius: 3, style: .continuous)
//                    .fill(Color.accentColor)
//                    .frame(width: 20, height: 10)
//                    .offset(y: travel)
//                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//            }
//        }
//    }
//}
//
//private struct ZzzView: View {
//    var body: some View {
//        TimelineView(.animation) { ctx in
//            let t = ctx.date.timeIntervalSinceReferenceDate
//            let y = -6 - 4 * sin(t * 1.1)
//            let alpha = 0.5 + 0.4 * sin(t * 0.8)
//            HStack(spacing: 2) {
//                Text("Z").font(.caption2).opacity(alpha * 0.6)
//                Text("Z").font(.caption).opacity(alpha * 0.8)
//                Text("Z").font(.subheadline).bold().opacity(alpha)
//            }
//            .offset(y: y)
//            .foregroundStyle(.secondary)
//        }
//    }
//}
//
//private struct DepositView: View {
//    let count: Int
//    let capacity: Int
//    var color: Color = .blue
//
//    var body: some View {
//        GeometryReader { geo in
//            let pad: CGFloat = 8
//            let w = geo.size.width
//            let h = geo.size.height
//
//            let bg = RoundedRectangle(cornerRadius: 8, style: .continuous)
//            ZStack {
//                bg.fill(color)
//                bg.stroke(Color.black.opacity(0.12), lineWidth: 1)
//
//                Canvas { context, size in
//                    // Compute a responsive grid that fits up to `capacity` boxes, based on Canvas size
//                    let availableW = max(0, size.width)
//                    let availableH = max(0, size.height)
//                    let targetBox: CGFloat = 12
//                    let spacing: CGFloat = 4
//                    let cols = max(1, Int(floor((availableW + spacing) / (targetBox + spacing))))
//                    let rows = max(1, Int(ceil(Double(capacity) / Double(cols))))
//                    let boxW = (availableW - CGFloat(max(0, cols - 1)) * spacing) / CGFloat(cols)
//                    let boxH = (availableH - CGFloat(max(0, rows - 1)) * spacing) / CGFloat(rows)
//                    let boxSize = max(2, min(boxW, boxH))
//
//                    // Center the grid within the Canvas area
//                    let gridW = CGFloat(cols) * boxSize + CGFloat(max(0, cols - 1)) * spacing
//                    let gridH = CGFloat(rows) * boxSize + CGFloat(max(0, rows - 1)) * spacing
//                    let startX = (availableW - gridW) / 2
//                    let startY = (availableH - gridH) / 2
//
//                    let total = min(max(0, count), max(0, capacity))
//                    guard total > 0 else { return }
//
//                    for i in 0..<total {
//                        // Fill top-to-bottom, left-to-right (top-leading start)
//                        let row = i / cols
//                        let col = i % cols
//                        let x = startX + CGFloat(col) * (boxSize + spacing)
//                        let y = startY + CGFloat(row) * (boxSize + spacing)
//                        let rect = CGRect(x: x, y: y, width: boxSize, height: boxSize).integral
//                        let path = Path(roundedRect: rect, cornerRadius: boxSize * 0.18)
//                        context.fill(path, with: .color(.orange))
//                        context.stroke(path, with: .color(.black.opacity(0.2)), lineWidth: 1)
//                    }
//                }
//                .animation(.easeInOut(duration: 0.2), value: count)
//                .padding(pad)
//                .allowsHitTesting(false)
//            }
//        }
//        .accessibilityLabel("Depósito")
//        .accessibilityValue("\(count) de \(capacity) caixas")
//    }
//}
//

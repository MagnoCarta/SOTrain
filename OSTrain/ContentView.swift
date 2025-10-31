import SwiftUI
import Foundation
import Observation


// MARK: - SwiftUI
struct ContentView: View {
    private enum UIMode: String, CaseIterable, Identifiable { case scenarios, laboratory; var id: String { rawValue } }
    @State private var uiMode: UIMode = .scenarios

    @State private var selectedScenario: SimulationScenario = .balanced
    @State private var isRunning: Bool = false
    @State private var model: SimulationModel = SimulationModel(
        M: SimulationScenario.balanced.config.M,
        N: SimulationScenario.balanced.config.N,
        tvMs: SimulationScenario.balanced.config.tvMs,
        packerTeMs: SimulationScenario.balanced.config.packerTeMs,
        policy: SimulationScenario.balanced.config.policy
    )

    @State var time: TimeInterval = 0

    @State private var labM: Int = SimulationScenario.balanced.config.M
    @State private var labN: Int = SimulationScenario.balanced.config.N
    @State private var labTv: Int = SimulationScenario.balanced.config.tvMs
    @State private var labPackers: [PackerViewModel] = SimulationScenario.balanced.config.packerTeMs.enumerated().map { idx, te in
        PackerViewModel(id: idx + 1, name: "E\(idx + 1)", status: .empacotando, progress: 0, teMs: te)
    }
    @State private var showAddPackerSheet: Bool = false
    @State private var newPackerName: String = ""
    @State private var newPackerTeMs: Int = 500

    var body: some View {
        VStack(spacing: 16) {
            if uiMode == .scenarios { header } else { labHeader }
            scene
            Spacer(minLength: 8)
        }
        .padding()
        .onAppear {
            if isRunning { model.start() }
        }
        .onChange(of: selectedScenario) { _, newValue in
            // If running, restart with the new scenario
            if isRunning {
                model.stop()
                model = buildModel(from: newValue)
                model.start()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Modo", selection: $uiMode) {
                    Text("Scenarios").tag(UIMode.scenarios)
                    Text("Laboratory").tag(UIMode.laboratory)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
            }
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 8) {
                    if uiMode == .scenarios {
                        Picker("Cenário", selection: $selectedScenario) {
                            ForEach(SimulationScenario.allCases) { s in
                                Text(s.config.title).tag(s)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    if isRunning {
                        Button {
                            model.stop()
                            isRunning = false
                        } label: {
                            Label("Parar", systemImage: "stop.fill")
                        }
                    } else {
                        Button {
                            if uiMode == .scenarios {
                                model = buildModel(from: selectedScenario)
                            } else {
                                // Build from lab values and lab packers
                                let packerTeMs = labPackers.map { $0.teMs }
                                model = SimulationModel(
                                    M: labM,
                                    N: labN,
                                    tvMs: labTv,
                                    packerTeMs: packerTeMs,
                                    policy: .fifo
                                )
                                // Apply names to model's packers
                                for i in model.packers.indices {
                                    if i < labPackers.count {
                                        model.packers[i].name = labPackers[i].name
                                    }
                                }
                            }
                            model.start()
                            isRunning = true
                        } label: {
                            Label("Iniciar", systemImage: "play.fill")
                        }
                    }
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                if uiMode == .laboratory {
                    Button {
                        newPackerName = ""
                        newPackerTeMs = 500
                        showAddPackerSheet = true
                    } label: {
                        Label("Adicionar Empacotador", systemImage: "plus")
                    }
                    .disabled(isRunning == false && uiMode == .laboratory && labPackers.count >= 32)
                }
            }
        }
        .sheet(isPresented: $showAddPackerSheet) {
            NavigationStack {
                Form {
                    Section("Empacotador") {
                        TextField("Nome", text: $newPackerName)
                        Stepper(value: $newPackerTeMs, in: 50...6000, step: 50) {
                            Text("te = \(newPackerTeMs) ms")
                        }
                    }
                }
                .navigationTitle("Novo Empacotador")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showAddPackerSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Adicionar") {
                            if uiMode == .laboratory {
                                if isRunning {
                                    model.addPacker(name: newPackerName, teMs: newPackerTeMs)
                                } else {
                                    let newId = (labPackers.map { $0.id }.max() ?? 0) + 1
                                    labPackers.append(PackerViewModel(id: newId, name: newPackerName.isEmpty ? "E\(newId)" : newPackerName, status: .empacotando, progress: 0, teMs: newPackerTeMs))
                                }
                            }
                            showAddPackerSheet = false
                        }
                    }
                }
            }
        }
    }

    private func buildModel(from scenario: SimulationScenario) -> SimulationModel {
        let cfg = scenario.config
        return SimulationModel(M: cfg.M, N: cfg.N, tvMs: cfg.tvMs, packerTeMs: cfg.packerTeMs, policy: cfg.policy)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedScenario.config.title)
                .font(.title2).bold()
            Text(selectedScenario.config.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Depósito: \(model.depositoCount)/\(model.M)")
                .font(.headline)
            ProgressView(value: Double(model.depositoCount), total: Double(model.M))
            HStack(spacing: 12) {
                Chip(text: "N = \(model.N)")
                Chip(text: "tv = \(model.tvMs) ms")
                Chip(text: "Empacotadores: \(model.packers.count)")
                Text("Timer: \(time)")
            }
        }.onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                Task { @MainActor in
                    time += 0.1
                }
            })
        }
    }

    private var labHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Laboratory")
                .font(.title2).bold()
            Text("Defina M, N e tv antes de iniciar. Você pode adicionar/remover empacotadores a qualquer momento neste modo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Stepper(value: $labM, in: 1...200) { Text("M = \(labM)") }
                Stepper(value: $labN, in: 1...200) { Text("N = \(labN)") }
                Stepper(value: $labTv, in: 50...10000, step: 50) { Text("tv = \(labTv) ms") }
            }
            Text("Depósito: \(model.depositoCount)/\(model.M)")
                .font(.headline)
            ProgressView(value: Double(model.depositoCount), total: Double(model.M))
            HStack(spacing: 12) {
                Chip(text: "N = \(uiMode == .scenarios ? model.N : labN)")
                Chip(text: "tv = \(uiMode == .scenarios ? model.tvMs : labTv) ms")
                Chip(text: "Empacotadores: \(uiMode == .laboratory && !isRunning ? labPackers.count : model.packers.count)")
                Text("Timer: \(time)")
            }
        }
    }

    private func statusLabel(for s: PackerStatus) -> String {
        switch s {
        case .empacotando: return "empacotando"
        case .colocando:   return "colocando"
        case .dormindo:    return "dormindo (depósito cheio)"
        }
    }

    var trainProgress: Double {
        return model.trainStatus == .viajandoBParaA ? 1 - model.trainProgress : model.trainProgress
    }

    var trainDirection: CGFloat {
        return model.trainStatus == .viajandoBParaA ? -1 : 1
    }

    private var scene: some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let totalH = geo.size.height
            let leftRadius: CGFloat = 60
            let rightRadius: CGFloat = 60
            let margin: CGFloat = 16
            let leftCenter = CGPoint(x: max(leftRadius + margin, totalW * 0.12), y: 100)
            let rightCenter = CGPoint(x: totalW - max(rightRadius + margin, totalW * 0.12), y: 100)
            let sourcePile = CGPoint(x: leftCenter.x + leftRadius + 180, y: leftCenter.y + 120)

            // Train parameters
            let t = trainProgress.clamped(to: 0...1)
            let startX = leftCenter.x + leftRadius
            let endX = rightCenter.x - rightRadius
            let x = startX + (endX - startX) * t
            let baseY: CGFloat = min(leftCenter.y, rightCenter.y)
            let arcHeight: CGFloat = 80
            let y = baseY - arcHeight * 4 * t * (1 - t)

            ZStack {
                // Infinite boxes pile (source)
                BoxPileView(center: sourcePile, rows: 3, cols: 5, spacing: 6)
                    .opacity(0.9)

                // Left: circular deposit (fills with boxes)
                CircularDepositView(count: model.depositoCount, capacity: model.M, radius: leftRadius)
                    .position(leftCenter)

                // Right: static circular destination filled with boxes (does not change)
                CircularDepositView(count: model.M, capacity: model.M, radius: rightRadius)
                    .position(rightCenter)
                    .opacity(0.7)

                // Human packers walking from pile to deposit
                let data: [PackerViewModel] = (uiMode == .laboratory && !isRunning) ? labPackers : model.packers
                ForEach(data) { p in
                    let progress = p.progress.clamped(to: 0...1)
                    let hx = sourcePile.x + (leftCenter.x - sourcePile.x) * progress
                    let hy = sourcePile.y + (leftCenter.y - sourcePile.y) * progress
                    ZStack {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 32, weight: .regular))
                            .foregroundStyle(p.status == .dormindo ? .secondary : .primary)
                        // Show the carried box while packing, placing, and also while sleeping (box ready to deposit)
                        if p.status == .colocando || p.status == .empacotando || p.status == .dormindo {
                            Image(systemName: "shippingbox")
                                .font(.system(size: 20))
                                .offset(x: -12, y: -28)
                        }
                        // Add a subtle sleep indicator when dormant
                        if p.status == .dormindo {
                            Image(systemName: "zzz")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .offset(x: 14, y: -26)
                        }
                    }
                    .position(x: hx, y: hy)
                    // Slow down to make both forward and return trips clearly animated
                    .animation(.linear(duration: 0.9), value: p.progress)
                }

                // Train moving along a parabola
                Image(.train)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .scaleEffect(x: trainDirection, y: 1)
                    .position(x: x + 46, y: y)
                    .shadow(radius: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 260)
    }
}

private struct CircularDepositView: View {
    let count: Int
    let capacity: Int
    let radius: CGFloat
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: radius * 2, height: radius * 2)
                .overlay(
                    Circle().stroke(.secondary.opacity(0.3), lineWidth: 1)
                )
            // Fill with boxes proportionally
            let boxCount = max(0, min(count, capacity))
            let grid = Int(ceil(sqrt(Double(max(1, capacity)))))
            let cell = (radius * 2 - 16) / CGFloat(grid)
            let startX = -((CGFloat(grid) * cell) - cell) / 2
            let startY = -((CGFloat(grid) * cell) - cell) / 2
            ForEach(0..<boxCount, id: \.self) { i in
                let r = i / grid
                let c = i % grid
                Image(systemName: "shippingbox")
                    .font(.system(size: max(10, cell * 0.6)))
                    .foregroundStyle(.orange)
                    .position(x: startX + CGFloat(c) * cell + radius, y: startY + CGFloat(r) * cell + radius)
            }
        }
        .frame(width: radius * 2, height: radius * 2)
    }
}

private struct BoxPileView: View {
    let center: CGPoint
    let rows: Int
    let cols: Int
    let spacing: CGFloat
    var body: some View {
        ZStack {
            ForEach(0..<(rows*cols), id: \.self) { i in
                let r = i / cols
                let c = i % cols
                Image(systemName: "shippingbox")
                    .foregroundStyle(.orange)
                    .position(x: center.x + CGFloat(c - cols/2) * spacing * 2,
                              y: center.y + CGFloat(r - rows/2) * spacing * 2)
            }
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

struct Chip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


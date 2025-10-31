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
            animation
            packersSection
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

    private var packersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Empacotadores")
                    .font(.headline)
                Spacer()
                if uiMode == .laboratory {
                    Button {
                        newPackerName = ""
                        newPackerTeMs = 500
                        showAddPackerSheet = true
                    } label: {
                        Label("Adicionar", systemImage: "plus")
                    }
                    .disabled(isRunning == false && uiMode == .laboratory && labPackers.count >= 32)
                }
            }
            packersGrid
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

    private var packersGrid: some View {
        let data: [PackerViewModel] = (uiMode == .laboratory && !isRunning) ? labPackers : model.packers
        return VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                ForEach(data) { p in
                    ZStack(alignment: .topTrailing) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(p.name).bold()
                                Spacer()
                                Text(statusLabel(for: p.status))
                                    .foregroundStyle(.secondary)
                            }
                            PackerAnimationView(status: p.status, progress: p.progress)
                                .frame(height: 56)
                                .animation(.easeInOut(duration: 0.2), value: p.status)
                            ProgressView(value: p.progress)
                            HStack {
                                Text("te: \(p.teMs) ms")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                        if uiMode == .laboratory {
                            Button {
                                if isRunning {
                                    model.removePacker(id: p.id)
                                } else {
                                    if let idx = labPackers.firstIndex(where: { $0.id == p.id }) { labPackers.remove(at: idx) }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(6)
                        }
                    }
                }
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

    private var trainPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trem: \(model.trainStatus.label)")
                .font(.title3)
            ProgressView(value: trainProgress)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    var trainProgress: Double {
        return model.trainStatus == .viajandoBParaA ? 1 - model.trainProgress : model.trainProgress
    }

    var trainDirection: CGFloat {
        return model.trainStatus == .viajandoBParaA ? -1 : 1
    }

    private var animation: some View {
        GeometryReader { geo in
            let totalW = geo.size.width
            let leftDockW = max(180.0, totalW * 0.1)
            let rightDockW = max(220.0, totalW * 0.1)
            let trainW: CGFloat = 92
            let trainH: CGFloat = 92

            let trackStart = leftDockW
            let trackEnd   = totalW - rightDockW - trainW
            let x = trackStart + max(0, trackEnd - trackStart) * trainProgress
            let baselineY: CGFloat = 80

            ZStack(alignment: .topLeading) {
                // Left: depósito
                DepositView(count: model.depositoCount, capacity: model.M, color: .blue)
                    .frame(width: leftDockW, height: 120)
                    .position(x: leftDockW / 2, y: baselineY)

                // Right: destino
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green)
                    .frame(width: rightDockW, height: 120)
                    .position(x: totalW - rightDockW / 2, y: baselineY)

                // Train at linear position
                Image(.train)
                    .resizable()
                    .scaledToFit()
                    .frame(width: trainW, height: trainH)
                    .scaleEffect(x: trainDirection, y: 1)
                    .position(x: x + trainW / 2, y: baselineY)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 200)
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

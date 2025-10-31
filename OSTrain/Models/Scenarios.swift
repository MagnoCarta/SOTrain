//
//  Scenarios.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

public enum SimulationScenario: String, CaseIterable, Identifiable {
    case balanced
    case depositoLotaRapido
    case producaoLenta
    case NIgualM
    case NPequeno
    case NPertoDeM
    case tvMuitoCurto
    case tvMuitoLongo
    case teGigante
    case stressMAlto
    case NEh1
    case starvationPackerLIFO
    case starvationPraticaTrem
    case aleatorioJustica
    case oscilatorio
    case produtorDominante

    public var id: Self { self }

    var config: ScenarioConfig {
        switch self {
        case .balanced:
            return .init(
                title: "Básico balanceado",
                description: "Fluxo estável; trem parte regularmente.",
                M: 20, N: 10, tvMs: 1500,
                packerTeMs: [300, 450, 600, 900],
                policy: .fifo
            )
        case .depositoLotaRapido:
            return .init(
                title: "Depósito lota rápido",
                description: "Produção ≫ consumo; empacotadores ‘dormem’ muito.",
                M: 20, N: 10, tvMs: 3000,
                packerTeMs: [120, 140, 160, 180, 200, 220, 240, 260],
                policy: .fifo
            )
        case .producaoLenta:
            return .init(
                title: "Produção lenta",
                description: "Trem aguarda juntar N com frequência.",
                M: 20, N: 10, tvMs: 1000,
                packerTeMs: [1500, 1700],
                policy: .fifo
            )
        case .NIgualM:
            return .init(
                title: "N = M",
                description: "Parte somente cheio; ciclos 0→10→0.",
                M: 10, N: 10, tvMs: 1500,
                packerTeMs: [300, 300, 450, 600, 750],
                policy: .fifo
            )
        case .NPequeno:
            return .init(
                title: "N pequeno",
                description: "Viagens frequentes; pouco bloqueio.",
                M: 20, N: 2, tvMs: 800,
                packerTeMs: [400, 500, 600],
                policy: .fifo
            )
        case .NPertoDeM:
            return .init(
                title: "N perto de M",
                description: "Lotes raros; muitos dormindo próximo de M.",
                M: 20, N: 18, tvMs: 1000,
                packerTeMs: [300, 350, 400, 450, 500, 550],
                policy: .fifo
            )
        case .tvMuitoCurto:
            return .init(
                title: "tv muito curto",
                description: "Gargalo é produção; trem pronto quase sempre.",
                M: 20, N: 10, tvMs: 120,
                packerTeMs: [300, 400, 600, 800, 800, 700],
                policy: .fifo
            )
        case .tvMuitoLongo:
            return .init(
                title: "tv muito longo",
                description: "Depósito enche; longa dormência dos empacotadores.",
                M: 20, N: 10, tvMs: 5000,
                packerTeMs: [280, 320, 360, 400, 440, 480],
                policy: .fifo
            )
        case .teGigante:
            return .init(
                title: "te gigante",
                description: "Raramente junta N; trem quase sempre parado.",
                M: 20, N: 10, tvMs: 1000,
                packerTeMs: [3000, 3300, 3600, 3900],
                policy: .fifo
            )
        case .stressMAlto:
            return .init(
                title: "Stress M alto",
                description: "Escala; invariantes estáveis em M grande.",
                M: 100, N: 10, tvMs: 1200,
                packerTeMs: [200,220,240,260,280,300,320,340,360,380,400,420],
                policy: .fifo
            )
        case .NEh1:
            return .init(
                title: "Borda N=1",
                description: "Caso PC clássico; consumo item a item.",
                M: 20, N: 1, tvMs: 800,
                packerTeMs: [450, 550],
                policy: .fifo
            )
        case .starvationPackerLIFO:
            return .init(
                title: "(Demo) LIFO Antigos ficam famintos",
                description: "LIFO privilegia recém-chegados → antigos podem ficar esperando.",
                M: 8, N: 6, tvMs: 1200,
                packerTeMs: Array(repeating: 300, count: 8),
                policy: .lifo
            )
        case .starvationPraticaTrem:
            return .init(
                title: "(Quase) starvation do trem",
                description: "N muito grande vs produção lenta → espera ‘infinita’ prática.",
                M: 40, N: 30, tvMs: 1500,
                packerTeMs: [1800, 2000, 2200],
                policy: .fifo
            )
        case .aleatorioJustica:
            return .init(
                title: "Aleatório (justiça imprevisível)",
                description: "Oscilação e justiça imprevisível entre empacotadores.",
                M: 20, N: 10, tvMs: 1200,
                packerTeMs: [300, 350, 400, 450, 500, 550],
                policy: .random
            )
        case .oscilatorio:
            return .init(
                title: "Oscilatório",
                description: "Depósito oscila perto do limite; padrões de ‘dorme/retoma’.",
                M: 20, N: 10, tvMs: 900,
                packerTeMs: [800, 900, 1000, 1100],
                policy: .fifo
            )
        case .produtorDominante:
            return .init(
                title: "Produtor dominante",
                description: "Um produtor ‘domina’ inserções (te muito menor).",
                M: 20, N: 10, tvMs: 1200,
                packerTeMs: [120, 1200, 1400, 1600],
                policy: .fifo
            )
        }
    }
}

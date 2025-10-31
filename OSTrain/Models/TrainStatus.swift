//
//  TrainStatus.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

enum TrainStatus: Equatable, Codable {
    case paradoAguardando(n: Int)
    case carregando(n: Int)
    case viajandoAParaB
    case viajandoBParaA

    var label: String {
        switch self {
        case .paradoAguardando(let n): return "parado (aguardando \(n) caixas em A)"
        case .carregando(let n):       return "carregando \(n) caixas"
        case .viajandoAParaB:          return "viajando de A para B"
        case .viajandoBParaA:          return "viajando de B para A"
        }
    }
}

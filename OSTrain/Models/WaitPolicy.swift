//
//  WaitPolicy.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

// MARK: - Scenario config and policies
public enum WaitPolicy: String, Codable, CaseIterable, Identifiable {
    case fifo
    case lifo
    case random
    public var id: Self { self }
    var label: String {
        switch self {
        case .fifo: return "FIFO"
        case .lifo: return "LIFO"
        case .random: return "Random"
        }
    }
}

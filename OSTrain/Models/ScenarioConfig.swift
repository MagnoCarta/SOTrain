//
//  ScenarioConfig.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

public struct ScenarioConfig: Identifiable, Hashable, Codable {
    public var id: String { title }
    let title: String
    let description: String
    let M: Int
    let N: Int
    let tvMs: Int
    let packerTeMs: [Int]
    let policy: WaitPolicy
}

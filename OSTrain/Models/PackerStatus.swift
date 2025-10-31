//
//  PackerStatus.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

// MARK: - Estados para UI
enum PackerStatus: String, Codable, Equatable {
    case empacotando
    case colocando
    case dormindo
}

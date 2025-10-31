//
//  PackerViewModel.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

struct PackerViewModel: Identifiable, Hashable {
    let id: Int
    var name: String
    var status: PackerStatus = .empacotando
    var progress: Double = 0
    var teMs: Int
    
    
}

//
//  Deposito.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

// MARK: - Depósito (protege contagem com Actor)
public actor Deposito {
    private(set) var caixas: Int = 0
    func push() { caixas += 1 }
    func pop()  { caixas -= 1 }
    var count: Int { caixas }
}

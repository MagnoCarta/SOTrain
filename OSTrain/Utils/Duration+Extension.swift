//
//  Duration+Extension.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

// MARK: - Utilitários de tempo/CPU-bound
extension Duration {
    var secondsDouble: Double {
        let c = self.components
        return Double(c.seconds) + Double(c.attoseconds) / 1_000_000_000_000_000_000.0
    }
    var millisecondsDouble: Double { secondsDouble * 1000.0 }
}

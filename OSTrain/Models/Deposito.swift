//
//  Deposito.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

// MARK: - Depósito (thread-safe via lock)
public final class Deposito {
    private var caixas: Int = 0
    private let lock = NSLock()

    public init() {}

    public func push() {
        lock.lock(); caixas += 1; lock.unlock()
    }

    public func pop()  {
        lock.lock(); caixas -= 1; lock.unlock()
    }

    public var count: Int {
        lock.lock(); let c = caixas; lock.unlock(); return c
    }
}

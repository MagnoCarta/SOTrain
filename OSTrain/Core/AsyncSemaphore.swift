//
//  AsyncSemaphore.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

// MARK: - AsyncSemaphore (configurable policy)
public actor AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private let policy: WaitPolicy

    public init(_ initial: Int, policy: WaitPolicy = .fifo) {
        self.value = initial
        self.policy = policy
    }

    public func wait() async {
        if value > 0 {
            value -= 1
            return
        }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            waiters.append(cont)
        }
    }

    public func signal() {
        if !waiters.isEmpty {
            let cont: CheckedContinuation<Void, Never>
            switch policy {
            case .fifo:
                cont = waiters.removeFirst()
            case .lifo:
                cont = waiters.removeLast()
            case .random:
                let i = Int.random(in: 0..<waiters.count)
                cont = waiters.remove(at: i)
            }
            cont.resume()
        } else {
            value += 1
        }
    }

    /// Somente para heurística de UI (leitura não atômica do contador)
    public func approxValue() -> Int { value }
}

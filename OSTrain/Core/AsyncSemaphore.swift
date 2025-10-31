//
//  AsyncSemaphore.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

// MARK: - BlockingSemaphore (Dispatch/Threads)
// This replaces the actor-based AsyncSemaphore with a classic blocking implementation
// using NSCondition. The `wait()` call blocks the current thread until a permit is available.
// The `policy` is best-effort; strict fairness is not guaranteed.
public final class AsyncSemaphore {
    private let condition = NSCondition()
    private var value: Int
    private let policy: WaitPolicy

    public init(_ initial: Int, policy: WaitPolicy = .fifo) {
        self.value = initial
        self.policy = policy
    }

    public func wait() {
        condition.lock()
        while value == 0 {
            // Block this thread until a signal arrives
            condition.wait()
        }
        value -= 1
        condition.unlock()
    }

    public func signal() {
        condition.lock()
        value += 1
        // Wake one waiter; NSCondition has no direct FIFO/LIFO selection.
        condition.signal()
        condition.unlock()
    }

    /// Non-atomic snapshot for UI heuristics only
    public func approxValue() -> Int {
        condition.lock()
        let v = value
        condition.unlock()
        return v
    }
}

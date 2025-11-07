//
//  SpinTimer.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

struct SpinTimer {
    /// CPU-bound for `durationMs` and posts ~`fps` frame updates.
    /// This function is synchronous and blocks the calling thread to intentionally burn CPU.
    static func cpuBurn(
        durationMs: Int,
        fps: Int = 60,
        onFrame: @escaping (Double) -> Void
    ) {
        let durationSec = max(0.001, Double(durationMs) / 1000.0)
        let frameInterval = 1.0 / Double(max(1, fps))

        let start = CFAbsoluteTimeGetCurrent()
        var nextFrame = start + frameInterval
        let deadline = start + durationSec

        @inline(__always) func burnChunk() {
            // Small deterministic integer math to keep the core busy
            var acc: Int = 0
            for k in 1...4000 { acc &+= k &* k }
            _ = acc
        }

        while CFAbsoluteTimeGetCurrent() < deadline {
            burnChunk()
            let now = CFAbsoluteTimeGetCurrent()
            if now >= nextFrame {
                let elapsed = now - start
                let p = min(1.0, max(0.0, elapsed / durationSec))
                DispatchQueue.main.async { onFrame(p) }
                nextFrame += frameInterval
            }
            // Cooperate a little with the scheduler without sleeping
            Darwin.sched_yield()
        }
        DispatchQueue.main.async { onFrame(1.0) }
    }
}


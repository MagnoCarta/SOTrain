//
//  SpinTimer.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import Foundation

struct SpinTimer {
    /// CPU-bound por `durationMs` com frames ~`fps`, a própria task gera os frames.
    static func cpuBurn(
        durationMs: Int,
        fps: Int = 60,
        onFrame: @MainActor @Sendable @escaping (Double) -> Void
    ) async {
        let clock = ContinuousClock()
        let start = clock.now
        let frameInterval = Duration.nanoseconds(1_000_000_000 / max(1, fps))
        var nextFrame = start + frameInterval // first frame after one interval
        let deadline = start + .milliseconds(durationMs)

        @inline(__always) func burnChunk() {
            var acc = 0
            for k in 1...2000 { acc &+= k &* k }
            _ = acc
        }

        while clock.now < deadline {
            burnChunk()
            if clock.now >= nextFrame {
                let elapsed = clock.now - start
                let p = min(1.0, max(0.0, elapsed.millisecondsDouble / Double(durationMs)))
                onFrame(p)
                nextFrame += frameInterval
            }
            await Task.yield() // coopera com o escalonador, sem dormir
        }
        onFrame(1.0)
    }
}

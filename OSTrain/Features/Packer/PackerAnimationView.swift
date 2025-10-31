//
//  PackerAnimationView.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import SwiftUI
import Foundation

struct PackerAnimationView: View {
    let status: PackerStatus
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Conveyor belt background
                BeltView(active: status != .dormindo)
                    .frame(height: h * 0.42)
                    .offset(y: h * 0.28)

                // Moving box reflecting current status/progress
                TimelineView(.animation) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let boxW = min(56, w * 0.22)
                    let boxH = min(36, h * 0.60)
                    let baseY = h * 0.28

                    var posX: CGFloat = 12
                    var posY: CGFloat = baseY
                    var scale: CGFloat = 1.0

                    switch status {
                    case .empacotando:
                        let travel = max(0, w - boxW - 24)
                        posX = 12 + travel * progress
                        posY = baseY - CGFloat(sin(progress * .pi)) * h * 0.06
                    case .colocando:
                        posX = (w - boxW) / 2
                        posY = baseY - CGFloat(progress) * h * 0.42
                    case .dormindo:
                        posX = (w - boxW) / 2
                        posY = baseY
                        scale = 1.0 + 0.02 * CGFloat(sin(t * 1.2))
                    }

                    return RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(status == .dormindo ? Color.gray.opacity(0.6) : Color.orange)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.black.opacity(0.15), lineWidth: 1)
                        )
                        .frame(width: boxW, height: boxH)
                        .position(x: posX + boxW / 2, y: posY)
                        .scaleEffect(scale)
                        .shadow(color: .black.opacity(0.10), radius: 3, x: 0, y: 2)
                }

                // Piston/press animating while packing
                if status == .empacotando {
                    PistonView(phase: progress)
                        .frame(width: 22)
                        .offset(x: -6, y: -h * 0.06)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }

                // Zzz indicator when sleeping
                if status == .dormindo {
                    ZzzView()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 8)
                        .offset(y: -h * 0.10)
                        .transition(.opacity)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.black.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

private struct BeltView: View {
    let active: Bool
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let phase = CGFloat(t * (active ? 1.6 : 0))
            Canvas { context, size in
                // Belt base
                let rect = CGRect(origin: .zero, size: size)
                let basePath = Path(roundedRect: rect, cornerRadius: 6)
                context.fill(basePath, with: .color(Color(white: 0.16)))

                // Moving vertical stripes
                let stripeW: CGFloat = 12
                let count = Int(size.width / stripeW) + 4
                let offset = (phase.truncatingRemainder(dividingBy: 1)) * stripeW
                for i in -2..<(count) {
                    let x = CGFloat(i) * stripeW - offset
                    let stripeRect = CGRect(x: x, y: 0, width: stripeW * 0.55, height: size.height)
                    let stripePath = Path(stripeRect)
                    context.fill(stripePath, with: .color(Color(white: 0.32)))
                }

                // Top highlight
                let highlightRect = CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.18)
                let highlightPath = Path(highlightRect)
                context.fill(highlightPath, with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.25), .clear]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height * 0.18)
                ))
            }
        }
        .opacity(active ? 1.0 : 0.55)
    }
}

private struct PistonView: View {
    let phase: Double // 0..1
    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let travel = h * 0.5 * CGFloat(sin(phase * .pi))
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.accentColor)
                    .frame(width: 20, height: 10)
                    .offset(y: travel)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }
}

private struct ZzzView: View {
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let y = -6 - 4 * sin(t * 1.1)
            let alpha = 0.5 + 0.4 * sin(t * 0.8)
            HStack(spacing: 2) {
                Text("Z").font(.caption2).opacity(alpha * 0.6)
                Text("Z").font(.caption).opacity(alpha * 0.8)
                Text("Z").font(.subheadline).bold().opacity(alpha)
            }
            .offset(y: y)
            .foregroundStyle(.secondary)
        }
    }
}

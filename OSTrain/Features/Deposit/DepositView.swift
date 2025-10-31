//
//  DepositView.swift
//  OSTrain
//
//  Created by Gilberto Magno on 24/10/25.
//

import SwiftUI

struct DepositView: View {
    let count: Int
    let capacity: Int
    var color: Color = .blue

    var body: some View {
        GeometryReader { geo in
            let pad: CGFloat = 8
            let _ = geo.size.width
            let _ = geo.size.height

            let bg = RoundedRectangle(cornerRadius: 8, style: .continuous)
            ZStack {
                bg.fill(color)
                bg.stroke(Color.black.opacity(0.12), lineWidth: 1)

                Canvas { context, size in
                    // Compute a responsive grid that fits up to `capacity` boxes, based on Canvas size
                    let availableW = max(0, size.width)
                    let availableH = max(0, size.height)
                    let targetBox: CGFloat = 12
                    let spacing: CGFloat = 4
                    let cols = max(1, Int(floor((availableW + spacing) / (targetBox + spacing))))
                    let rows = max(1, Int(ceil(Double(capacity) / Double(cols))))
                    let boxW = (availableW - CGFloat(max(0, cols - 1)) * spacing) / CGFloat(cols)
                    let boxH = (availableH - CGFloat(max(0, rows - 1)) * spacing) / CGFloat(rows)
                    let boxSize = max(2, min(boxW, boxH))

                    // Center the grid within the Canvas area
                    let gridW = CGFloat(cols) * boxSize + CGFloat(max(0, cols - 1)) * spacing
                    let gridH = CGFloat(rows) * boxSize + CGFloat(max(0, rows - 1)) * spacing
                    let startX = (availableW - gridW) / 2
                    let startY = (availableH - gridH) / 2

                    let total = min(max(0, count), max(0, capacity))
                    guard total > 0 else { return }

                    for i in 0..<total {
                        // Fill top-to-bottom, left-to-right (top-leading start)
                        let row = i / cols
                        let col = i % cols
                        let x = startX + CGFloat(col) * (boxSize + spacing)
                        let y = startY + CGFloat(row) * (boxSize + spacing)
                        let rect = CGRect(x: x, y: y, width: boxSize, height: boxSize).integral
                        let path = Path(roundedRect: rect, cornerRadius: boxSize * 0.18)
                        context.fill(path, with: .color(.orange))
                        context.stroke(path, with: .color(.black.opacity(0.2)), lineWidth: 1)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: count)
                .padding(pad)
                .allowsHitTesting(false)
            }
        }
        .accessibilityLabel("Depósito")
        .accessibilityValue("\(count) de \(capacity) caixas")
    }
}

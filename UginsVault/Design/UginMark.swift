//
//  UginMark.swift
//  UginsVault
//
//  Brand mark: a gold "U" cradle holding a hedron (rhombus) diamond.
//  Two pieces — `UginMark` (composed view) and `UginAppIcon` (rounded-square
//  app-icon-style wrapper with a midnight gradient background).
//

import SwiftUI

struct UginMark: View {
    var size: CGFloat = 80
    var showsGlow: Bool = true

    var body: some View {
        ZStack {
            if showsGlow {
                // Lavender bloom behind the mark
                RadialGradient(
                    colors: [Color.uv.lavender.opacity(0.35), .clear],
                    center: .center, startRadius: 0, endRadius: size * 0.55
                )
                .frame(width: size, height: size)
            }
            Canvas { ctx, _ in
                let s = size
                let goldHi = Color(hex: 0xE6C572)
                let goldLo = Color(hex: 0x9A7424)
                let gold = LinearGradient(
                    colors: [goldHi, goldLo],
                    startPoint: .top, endPoint: .bottom
                )

                // Hedron diamond — centered slightly above middle
                let cx: CGFloat = s / 2
                let cy: CGFloat = s * 0.50
                let r:  CGFloat = s * 0.20

                var diamond = Path()
                diamond.move(to: CGPoint(x: cx, y: cy - r))
                diamond.addLine(to: CGPoint(x: cx + r * 0.82, y: cy))
                diamond.addLine(to: CGPoint(x: cx, y: cy + r))
                diamond.addLine(to: CGPoint(x: cx - r * 0.82, y: cy))
                diamond.closeSubpath()
                ctx.stroke(diamond, with: .linearGradient(
                    Gradient(colors: [goldHi, goldLo]),
                    startPoint: CGPoint(x: cx, y: cy - r),
                    endPoint: CGPoint(x: cx, y: cy + r)),
                    lineWidth: s * 0.018
                )

                // Internal facet lines
                var facets = Path()
                facets.move(to: CGPoint(x: cx, y: cy - r))
                facets.addLine(to: CGPoint(x: cx, y: cy + r))
                facets.move(to: CGPoint(x: cx - r * 0.82, y: cy))
                facets.addLine(to: CGPoint(x: cx + r * 0.82, y: cy))
                ctx.stroke(facets, with: .color(goldHi.opacity(0.55)),
                           lineWidth: s * 0.007)

                // U cradle — bottom-open round-rect
                let cradleWidth  = s * 0.55
                let cradleHeight = s * 0.30
                let cradleTop    = cy - cradleHeight * 0.05
                let leftX  = cx - cradleWidth / 2
                let rightX = cx + cradleWidth / 2
                let bottomY = cradleTop + cradleHeight

                var cradle = Path()
                cradle.move(to: CGPoint(x: leftX, y: cradleTop))
                cradle.addLine(to: CGPoint(x: leftX, y: bottomY - cradleWidth / 2))
                cradle.addArc(
                    center: CGPoint(x: cx, y: bottomY - cradleWidth / 2),
                    radius: cradleWidth / 2,
                    startAngle: .degrees(180),
                    endAngle:   .degrees(0),
                    clockwise: false
                )
                cradle.addLine(to: CGPoint(x: rightX, y: cradleTop))
                ctx.stroke(cradle, with: .linearGradient(
                    Gradient(colors: [goldHi, goldLo]),
                    startPoint: CGPoint(x: cx, y: cradleTop),
                    endPoint: CGPoint(x: cx, y: bottomY)),
                    style: StrokeStyle(lineWidth: s * 0.04, lineCap: .round)
                )
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// App-icon-style wrapper: rounded square with midnight gradient + UginMark inside.
struct UginAppIcon: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: 0x1B1830), Color(hex: 0x0A0913)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            UginMark(size: size * 0.92)
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .strokeBorder(.white.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
        .accessibilityLabel("Ugin's Vault")
    }
}

#Preview {
    VStack(spacing: 32) {
        UginAppIcon(size: 144)
        UginMark(size: 96)
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.uv.bg)
    .preferredColorScheme(.dark)
}

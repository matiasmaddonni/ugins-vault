//
//  FoilSheen.swift
//  UginsVault — Presentation: Design System
//
//  Static holographic overlay for foil cards: a faint rainbow wash plus a
//  fixed diagonal highlight. Meant to be layered over a card image and
//  clipped to the same shape. Decorative only — never intercepts touches.
//
//  Performance: NO `GeometryReader` and NO blend modes. Plain gradients
//  composited with opacity render in a single pass, so adding the overlay to
//  every foil row in a stack stays cheap during scroll.
//

import SwiftUI

public struct FoilSheen: View {

    public init() {}

    private static let rainbow: [Color] = [
        Color(hex: 0x5BFFE4),
        Color(hex: 0x6BA8FF),
        Color(hex: 0xC77BFF),
        Color(hex: 0xFF7BB0),
        Color(hex: 0xFFD86B),
        Color(hex: 0x6BFF9E)
    ]

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: Self.rainbow,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.22)

            // Fixed diagonal highlight band — pure alpha, no blend.
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.32), .clear],
                startPoint: UnitPoint(x: 0.25, y: 0.0),
                endPoint:   UnitPoint(x: 0.55, y: 1.0)
            )
        }
        .allowsHitTesting(false)
    }
}

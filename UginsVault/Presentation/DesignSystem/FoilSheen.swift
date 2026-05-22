//
//  FoilSheen.swift
//  UginsVault — Presentation: Design System
//
//  Static holographic overlay for foil cards: a faint rainbow wash plus a
//  fixed specular highlight. Meant to be layered over a card image and
//  clipped to the same shape. Decorative only — never intercepts touches.
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
        GeometryReader { geo in
            LinearGradient(colors: Self.rainbow, startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.28)
                .overlay(specular(in: geo.size))
                .blendMode(.plusLighter)
        }
        .allowsHitTesting(false)
    }

    /// Fixed diagonal highlight band, slightly left of centre.
    private func specular(in size: CGSize) -> some View {
        let bandWidth = size.width * 0.55
        return LinearGradient(
            colors: [.clear, Color.white.opacity(0.45), .clear],
            startPoint: .top, endPoint: .bottom
        )
        .frame(width: bandWidth)
        .rotationEffect(.degrees(18))
        .offset(x: size.width * 0.18)
        .blendMode(.plusLighter)
    }
}

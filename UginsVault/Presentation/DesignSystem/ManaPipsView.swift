//
//  ManaPipsView.swift
//  UginsVault — Presentation: Design System
//
//  Horizontal row of small mana-coloured circles. Drives the colour-identity
//  indicator on `StackRow` (deck stacks) and on cover overlays. Renders in
//  the canonical WUBRG order so a `{R, G}` set lays out the same way every
//  time.
//

import SwiftUI

public struct ManaPipsView: View {

    private static let canonicalOrder: [ManaColor] = [
        .white, .blue, .black, .red, .green, .colorless
    ]

    public let colors: Set<ManaColor>
    public let diameter: CGFloat

    public init(colors: Set<ManaColor>, diameter: CGFloat = Layout.manaPipSmall) {
        self.colors = colors
        self.diameter = diameter
    }

    public var body: some View {
        HStack(spacing: Spacing.xs - 2) {
            ForEach(Self.canonicalOrder.filter(colors.contains), id: \.self) { color in
                Circle()
                    .fill(color.tintColor)
                    .overlay(
                        Circle().strokeBorder(Color.uv.bg, lineWidth: Layout.hairline)
                    )
                    .frame(width: diameter, height: diameter)
            }
        }
    }
}

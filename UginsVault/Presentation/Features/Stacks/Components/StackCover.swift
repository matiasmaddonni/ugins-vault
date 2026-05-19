//
//  StackCover.swift
//  UginsVault — Presentation: Stacks
//
//  Square thumbnail rendered on the leading edge of a `StackRow`. Two
//  visual modes:
//
//   • Deck — three rotated "card leaves" fanned behind each other,
//     tinted by the deck's `colors`. Evokes a sleeved deck on the table.
//   • Non-deck (binder / loan / sale / showcase / inbox) — single rounded
//     panel with the kind's SF Symbol glyph inset, kind-tinted.
//
//  Pure presentation — no SwiftData reads.
//

import SwiftUI

public struct StackCover: View {

    public let stack: Stack
    public let size: CGFloat

    public init(stack: Stack, size: CGFloat = Layout.stackCoverSize) {
        self.stack = stack
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panelLo)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )

            if stack.kind == .deck {
                deckFan
            } else {
                glyph
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Deck fan

    private var deckFan: some View {
        ZStack {
            leaf(rotation: -14, offset: -Layout.stackFanOffset, opacity: 0.55)
            leaf(rotation: 0,    offset: 0,                      opacity: 0.85)
            leaf(rotation: 14,   offset:  Layout.stackFanOffset, opacity: 1.0)
        }
    }

    private func leaf(rotation: Double, offset: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: UVRadius.sm)
            .fill(leafGradient)
            .overlay(
                RoundedRectangle(cornerRadius: UVRadius.sm)
                    .strokeBorder(Color.uv.strokeHi.opacity(0.7), lineWidth: Layout.hairline)
            )
            .frame(width: Layout.stackFanCardWidth, height: Layout.stackFanCardHeight)
            .rotationEffect(.degrees(rotation))
            .offset(x: offset)
            .opacity(opacity)
    }

    /// Linear gradient between the stack's first two colours. Falls back
    /// to gold when no colours are recorded.
    private var leafGradient: LinearGradient {
        let palette = leafColors
        return LinearGradient(
            colors: palette,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var leafColors: [Color] {
        let ordered: [ManaColor] = [.white, .blue, .black, .red, .green, .colorless]
        let selected = ordered.filter(stack.colors.contains)
        if selected.isEmpty {
            return [Color.uv.gold.opacity(0.7), Color.uv.goldLo.opacity(0.7)]
        }
        if selected.count == 1 {
            return [selected[0].tintColor.opacity(0.9), selected[0].tintColor.opacity(0.55)]
        }
        return selected.prefix(2).map { $0.tintColor.opacity(0.9) }
    }

    // MARK: - Non-deck glyph

    private var glyph: some View {
        Image(systemName: stack.kind.iconName)
            .font(.system(size: Layout.stackCoverGlyph, weight: .semibold))
            .foregroundStyle(stack.kind.accentColor)
    }
}

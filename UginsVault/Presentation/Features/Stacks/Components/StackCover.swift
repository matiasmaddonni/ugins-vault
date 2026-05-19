//
//  StackCover.swift
//  UginsVault — Presentation: Stacks
//
//  Square thumbnail rendered on the leading edge of a `StackRow`. Modes,
//  in priority order:
//
//   1. Single commander card → that one card's art, square-cropped.
//   2. 1–3 hydrated `previewCards` → fan of mini card thumbnails.
//   3. Deck with no card data → coloured "card leaves" fan tinted by
//      `stack.colors` (legacy mode).
//   4. Non-deck (binder / loan / sale / showcase / inbox) → kind glyph.
//

import SwiftUI
import Kingfisher

public struct StackCover: View {

    public let stack: Stack
    public let size: CGFloat
    public let previewCards: [Card]

    public init(
        stack: Stack,
        size: CGFloat = Layout.stackCoverSize,
        previewCards: [Card] = []
    ) {
        self.stack = stack
        self.size = size
        self.previewCards = previewCards
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panelLo)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )

            if let single = singleCommanderArt {
                KFImage(single)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: UVRadius.md))
            } else if !previewCards.isEmpty {
                cardFan
            } else if stack.kind == .deck {
                deckFan
            } else {
                glyph
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: UVRadius.md))
    }

    private var singleCommanderArt: URL? {
        guard stack.commanderCardID != nil,
              previewCards.count == 1,
              let card = previewCards.first
        else { return nil }
        return card.images.artCrop ?? card.images.normal ?? card.images.large
    }

    // MARK: - Card fan (real thumbnails)

    private var cardFan: some View {
        let cards = Array(previewCards.prefix(3))
        return ZStack {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                cardLeaf(card: card, index: index, count: cards.count)
            }
        }
    }

    private func cardLeaf(card: Card, index: Int, count: Int) -> some View {
        let rotations: [Double] = count == 1 ? [0] :
                                  count == 2 ? [-10, 10] :
                                               [-14, 0, 14]
        let offsets: [CGFloat] = count == 1 ? [0] :
                                 count == 2 ? [-Layout.stackFanOffset, Layout.stackFanOffset] :
                                              [-Layout.stackFanOffset, 0, Layout.stackFanOffset]
        let opacities: [Double] = count == 1 ? [1.0] :
                                  count == 2 ? [0.85, 1.0] :
                                               [0.55, 0.85, 1.0]

        let url = card.images.normal ?? card.images.large ?? card.images.small

        return Group {
            if let url {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.uv.panel
            }
        }
        .frame(width: Layout.stackFanCardWidth, height: Layout.stackFanCardHeight)
        .clipShape(RoundedRectangle(cornerRadius: UVRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: UVRadius.sm)
                .strokeBorder(Color.uv.strokeHi.opacity(0.7), lineWidth: Layout.hairline)
        )
        .rotationEffect(.degrees(rotations[index]))
        .offset(x: offsets[index])
        .opacity(opacities[index])
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

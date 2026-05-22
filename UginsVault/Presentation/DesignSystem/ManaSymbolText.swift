//
//  ManaSymbolText.swift
//  UginsVault — Presentation: Design System
//
//  Renders oracle / rules text with inline MTG symbols. Tokens like {R} {2}
//  {T} {X} {W/U} are drawn as small coloured pips; everything else flows as
//  text. Programmatic (no bundled font): mana colours come from
//  `ManaColor.tintColor`, generic / ability symbols are a neutral pip.
//

import SwiftUI

public struct ManaSymbolText: View {

    private enum Token: Hashable {
        case word(String)
        case symbol(String)
    }

    private let paragraphs: [[Token]]
    private let font: Font
    private let symbolSize: CGFloat

    public init(_ text: String, font: Font = .uv.body(15), symbolSize: CGFloat = Layout.manaSymbolSize) {
        self.font = font
        self.symbolSize = symbolSize
        self.paragraphs = text
            .components(separatedBy: "\n")
            .map(Self.tokenize)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, tokens in
                if !tokens.isEmpty {
                    SymbolFlow(spacing: Spacing.xs - 1, lineSpacing: Spacing.xs) {
                        ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                            view(for: token)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func view(for token: Token) -> some View {
        switch token {
        case .word(let word):
            Text(word)
                .font(font)
                .foregroundStyle(Color.uv.text)
        case .symbol(let symbol):
            ManaSymbolPip(symbol: symbol, diameter: symbolSize)
        }
    }

    /// Splits a line into word + symbol tokens. `{...}` runs become symbols;
    /// the rest is split into space-separated words (the flow re-spaces them).
    private static func tokenize(_ line: String) -> [Token] {
        var tokens: [Token] = []
        var buffer = ""
        var index = line.startIndex

        func flushWords() {
            for word in buffer.split(separator: " ", omittingEmptySubsequences: true) {
                tokens.append(.word(String(word)))
            }
            buffer.removeAll(keepingCapacity: true)
        }

        while index < line.endIndex {
            if line[index] == "{", let close = line[index...].firstIndex(of: "}") {
                flushWords()
                let inner = String(line[line.index(after: index)..<close])
                tokens.append(.symbol(inner))
                index = line.index(after: close)
            } else {
                buffer.append(line[index])
                index = line.index(after: index)
            }
        }
        flushWords()
        return tokens
    }
}

// MARK: - Pip

private struct ManaSymbolPip: View {

    let symbol: String
    let diameter: CGFloat

    var body: some View {
        let mana = ManaColor(rawValue: symbol.uppercased())
        ZStack {
            Circle().fill(mana?.tintColor ?? Color(hex: 0xB8B2A6))
            Text(symbol)
                .font(.uv.mono(diameter * 0.5, weight: .bold))
                .foregroundStyle(Color(hex: 0x1A1410))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .padding(.horizontal, 1)
        }
        .frame(width: diameter, height: diameter)
        .overlay(Circle().strokeBorder(Color.uv.bg.opacity(0.5), lineWidth: Layout.hairline))
        .accessibilityLabel(symbol)
    }
}

// MARK: - Flow layout

private struct SymbolFlow<Content: View>: View {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder let content: Content

    init(spacing: CGFloat, lineSpacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content()
    }

    var body: some View {
        FlowLayout(spacing: spacing, lineSpacing: lineSpacing) { content }
    }
}

private struct FlowLayout: SwiftUI.Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widest: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                widest = max(widest, x - spacing)
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        widest = max(widest, x - spacing)
        return CGSize(width: maxWidth.isFinite ? maxWidth : widest, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

//
//  CardFilterSheet.swift
//  UginsVault — Presentation: Collection
//
//  Multi-select filter for the Collection list. Three sections: sets,
//  colours, rarities. Apply / Clear at the bottom. Empty selections mean
//  "no constraint".
//

import SwiftUI

public struct CardFilterSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var sets: Set<String>
    @State private var colors: Set<ManaColor>
    @State private var rarities: Set<Rarity>

    private let availableSetCodes: [String]
    private let onApply: (CardFilter) -> Void

    public init(
        initialFilter: CardFilter,
        availableSetCodes: [String],
        onApply: @escaping (CardFilter) -> Void
    ) {
        self._sets = State(initialValue: initialFilter.sets)
        self._colors = State(initialValue: initialFilter.colors)
        self._rarities = State(initialValue: initialFilter.rarities)
        self.availableSetCodes = availableSetCodes
        self.onApply = onApply
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    setsSection
                    colorsSection
                    raritiesSection
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.vertical, Spacing.xl - 4)
            }
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        sets.removeAll()
                        colors.removeAll()
                        rarities.removeAll()
                    }
                    .foregroundStyle(Color.uv.muted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onApply(CardFilter(sets: sets, colors: colors, rarities: rarities))
                        dismiss()
                    }
                    .foregroundStyle(Color.uv.gold)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.uv.bg)
    }

    // MARK: - Sets

    @ViewBuilder
    private var setsSection: some View {
        if !availableSetCodes.isEmpty {
            section(title: "Sets") {
                FlowChips(values: availableSetCodes) { code in
                    chip(label: code.uppercased(), isOn: sets.contains(code)) {
                        toggleSet(code)
                    }
                }
            }
        }
    }

    // MARK: - Colours

    private var colorsSection: some View {
        section(title: "Colours") {
            FlowChips(values: ManaColor.allCases.map(\.rawValue)) { raw in
                let color = ManaColor(rawValue: raw) ?? .colorless
                chip(label: color.displayName, isOn: colors.contains(color)) {
                    toggleColor(color)
                }
            }
        }
    }

    // MARK: - Rarities

    private var raritiesSection: some View {
        section(title: "Rarity") {
            FlowChips(values: Rarity.allCases.filter { $0 != .unknown }.map(\.rawValue)) { raw in
                let rarity = Rarity(rawValue: raw) ?? .common
                chip(label: rarity.rawValue.capitalized, isOn: rarities.contains(rarity)) {
                    toggleRarity(rarity)
                }
            }
        }
    }

    // MARK: - Helpers

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .uvSectionLabel()
            content()
        }
    }

    private func chip(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.uv.body(13, weight: .medium))
                .foregroundStyle(isOn ? Color(hex: 0x1A1410) : Color.uv.text)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: UVRadius.pill)
                        .fill(isOn ? Color.uv.gold : Color.uv.panel)
                        .overlay(
                            RoundedRectangle(cornerRadius: UVRadius.pill)
                                .strokeBorder(isOn ? Color.uv.gold : Color.uv.stroke, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func toggleSet(_ value: String) {
        if sets.contains(value) { sets.remove(value) } else { sets.insert(value) }
    }

    private func toggleColor(_ value: ManaColor) {
        if colors.contains(value) { colors.remove(value) } else { colors.insert(value) }
    }

    private func toggleRarity(_ value: Rarity) {
        if rarities.contains(value) { rarities.remove(value) } else { rarities.insert(value) }
    }
}

/// Simple horizontal flow layout for chips. Wraps to the next line when
/// the next item doesn't fit. iOS 16+ adopts `Layout` for this; on
/// iOS 26 the same protocol is still supported.
private struct FlowChips<ID: Hashable, Content: View>: View {

    let values: [ID]
    let content: (ID) -> Content

    init(values: [ID], @ViewBuilder content: @escaping (ID) -> Content) {
        self.values = values
        self.content = content
    }

    var body: some View {
        FlowLayout(spacing: Spacing.sm, lineSpacing: Spacing.sm) {
            ForEach(values, id: \.self) { value in
                content(value)
            }
        }
    }
}

/// Bare-bones flow `Layout`. Lays out subviews left-to-right and wraps
/// when the current row runs out of width.
private struct FlowLayout: SwiftUI.Layout {

    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize.unspecified)
            if currentX + size.width > width {
                currentX = 0
                currentY += lineHeight + lineSpacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: width.isFinite ? width : currentX, height: currentY + lineHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: LayoutSubviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize.unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

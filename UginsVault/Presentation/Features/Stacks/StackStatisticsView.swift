//
//  StackStatisticsView.swift
//  UginsVault — Presentation: Stacks
//
//  Per-stack analytics screen (pushed from a Stack's "Stats" action).
//  Total value + colour donut + rarity bars + mana curve + top cards.
//  Pure render of a `StackStatistics` value computed by the detail VM —
//  no loading here (the data is already in memory).
//

import SwiftUI
import Kingfisher

public struct StackStatisticsView: View {

    private let title: String
    private let stats: StackStatistics
    private let currency: Currency
    private let rate: ExchangeRate?

    public init(title: String, stats: StackStatistics, currency: Currency, rate: ExchangeRate? = nil) {
        self.title = title
        self.stats = stats
        self.currency = currency
        self.rate = rate
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if stats.isEmpty {
                    emptyState
                } else {
                    summaryPanel
                    if !stats.byColor.isEmpty { colorsPanel }
                    if !stats.byRarity.isEmpty { rarityPanel }
                    if !visibleCurve.isEmpty { curvePanel }
                    if !stats.topCards.isEmpty { topCardsPanel }
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.uv.bg.ignoresSafeArea())
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(StackStatisticsAccessibilityFields.screen)
    }

    // MARK: - Summary

    private var summaryPanel: some View {
        SectionPanel(title: title) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs - 2) {
                    Text("Total value").uvSectionLabel()
                    Text(CurrencyFormatter.format(stats.totalValueUSD, currency: currency, rate: rate))
                        .font(.uv.display(22, weight: .bold))
                        .foregroundStyle(Color.uv.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: Spacing.xs - 2) {
                    Text("\(stats.cardCount) cards")
                        .font(.uv.body(14, weight: .semibold))
                        .foregroundStyle(Color.uv.text)
                    Text("\(stats.uniqueCount) unique")
                        .font(.uv.mono(12))
                        .foregroundStyle(Color.uv.muted)
                }
            }
            if let commander = stats.commander {
                commanderRow(commander)
            }
            if stats.pricedFraction < 1 {
                Text("Value covers \(Int((stats.pricedFraction * 100).rounded()))% of cards — the rest are still pricing.")
                    .font(.uv.body(11))
                    .foregroundStyle(Color.uv.muted2)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(StackStatisticsAccessibilityFields.summaryPanel)
    }

    private func commanderRow(_ commander: StackStatistics.TopCard) -> some View {
        HStack(spacing: Spacing.md) {
            thumbnail(commander.imageURL)
            VStack(alignment: .leading, spacing: Spacing.xs - 2) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "crown.fill")
                        .font(.uv.sectionLabel)
                        .foregroundStyle(Color.uv.gold)
                    Text("Commander").uvSectionLabel()
                }
                Text(commander.name)
                    .font(.uv.body(14, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)
            }
            Spacer(minLength: Spacing.sm)
            Text(commander.lineValueUSD > 0
                 ? CurrencyFormatter.format(commander.lineValueUSD, currency: currency, rate: rate)
                 : String(localized: "No price"))
                .font(.uv.mono(13, weight: .semibold))
                .foregroundStyle(commander.lineValueUSD > 0 ? Color.uv.gold : Color.uv.muted2)
        }
        .padding(.top, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(StackStatisticsAccessibilityFields.commanderRow)
    }

    // MARK: - Colors

    private var colorsPanel: some View {
        SectionPanel(title: String(localized: "Colours")) {
            HStack(spacing: Spacing.lg) {
                DonutChartView(
                    slices: stats.byColor,
                    size: Layout.dashboardDonutSize,
                    thickness: Layout.dashboardDonutThickness
                ) {
                    VStack(spacing: 0) {
                        Text("Cards").uvSectionLabel()
                        Text("\(stats.cardCount)")
                            .font(.uv.display(15, weight: .bold))
                            .foregroundStyle(Color.uv.text)
                    }
                }
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(stats.byColor) { slice in
                        HStack(spacing: Spacing.sm) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: slice.colorHex))
                                .frame(width: Layout.dashboardLegendSwatchSize,
                                       height: Layout.dashboardLegendSwatchSize)
                            Text(slice.displayName)
                                .font(.uv.body(13))
                                .foregroundStyle(Color.uv.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(count(slice))
                                .font(.uv.mono(12, weight: .medium))
                                .foregroundStyle(Color.uv.text2)
                        }
                        .accessibilityIdentifier(StackStatisticsAccessibilityFields.colorLegend(slice.id))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(StackStatisticsAccessibilityFields.colorsPanel)
    }

    // MARK: - Rarity

    private var rarityPanel: some View {
        let maxCount = stats.byRarity.map(intCount).max() ?? 1
        return SectionPanel(title: String(localized: "Rarity")) {
            VStack(spacing: Spacing.sm) {
                ForEach(stats.byRarity) { slice in
                    barRow(
                        label: slice.displayName,
                        labelWidth: Layout.statsBarLabelWidth,
                        count: intCount(slice),
                        maxCount: maxCount,
                        colorHex: slice.colorHex
                    )
                    .accessibilityIdentifier(StackStatisticsAccessibilityFields.rarityBar(slice.id))
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(StackStatisticsAccessibilityFields.rarityPanel)
    }

    // MARK: - Mana curve

    private var visibleCurve: [StackStatistics.CurveBar] {
        guard let lastNonZero = stats.manaCurve.last(where: { $0.count > 0 })?.id else { return [] }
        return stats.manaCurve.filter { $0.id <= lastNonZero }
    }

    private var curvePanel: some View {
        let bars = visibleCurve
        let maxCount = bars.map(\.count).max() ?? 1
        return SectionPanel(title: String(localized: "Mana curve")) {
            VStack(spacing: Spacing.sm) {
                ForEach(Array(bars.enumerated()), id: \.element.id) { index, bar in
                    barRow(
                        label: bar.label,
                        labelWidth: Layout.statsBarCountWidth,
                        count: bar.count,
                        maxCount: maxCount,
                        colorHex: 0xC9A24B
                    )
                    .accessibilityIdentifier(StackStatisticsAccessibilityFields.curveBar(at: index))
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(StackStatisticsAccessibilityFields.curvePanel)
    }

    // MARK: - Top cards

    private var topCardsPanel: some View {
        SectionPanel(title: String(localized: "Top cards")) {
            VStack(spacing: Spacing.md) {
                ForEach(Array(stats.topCards.enumerated()), id: \.element.id) { index, card in
                    topCardRow(card)
                        .accessibilityIdentifier(StackStatisticsAccessibilityFields.topCard(at: index))
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(StackStatisticsAccessibilityFields.topCardsPanel)
    }

    private func topCardRow(_ card: StackStatistics.TopCard) -> some View {
        HStack(spacing: Spacing.md) {
            thumbnail(card.imageURL)
            VStack(alignment: .leading, spacing: Spacing.xs - 2) {
                Text(card.name)
                    .font(.uv.body(14, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)
                Text("\(card.setCode.uppercased()) · #\(card.collectorNumber)")
                    .font(.uv.mono(11))
                    .foregroundStyle(Color.uv.muted)
            }
            Spacer(minLength: Spacing.sm)
            VStack(alignment: .trailing, spacing: Spacing.xs - 2) {
                Text(CurrencyFormatter.format(card.lineValueUSD, currency: currency, rate: rate))
                    .font(.uv.mono(13, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
                if card.quantity > 1 {
                    Text("×\(card.quantity)")
                        .font(.uv.mono(11))
                        .foregroundStyle(Color.uv.muted2)
                }
            }
        }
    }

    // MARK: - Pieces

    private func barRow(label: String, labelWidth: CGFloat, count: Int, maxCount: Int, colorHex: UInt32) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(label)
                .font(.uv.body(12))
                .foregroundStyle(Color.uv.text)
                .lineLimit(1)
                .frame(width: labelWidth, alignment: .leading)
            GeometryReader { geo in
                let frac = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                let width = count > 0 ? max(geo.size.width * frac, Layout.statsBarThickness) : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.uv.panelLo)
                    Capsule().fill(Color(hex: colorHex)).frame(width: width)
                }
            }
            .frame(height: Layout.statsBarThickness)
            Text("\(count)")
                .font(.uv.mono(12, weight: .medium))
                .foregroundStyle(Color.uv.text2)
                .frame(width: Layout.statsBarCountWidth, alignment: .trailing)
        }
    }

    private func thumbnail(_ url: URL?) -> some View {
        Group {
            if let url {
                KFImage(url)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(
                        width: Layout.statsTopCardThumbWidth, height: Layout.statsTopCardThumbHeight)))
                    .scaleFactor(displayScale)
                    .cacheOriginalImage()
                    .placeholder { thumbnailPlaceholder }
                    .fade(duration: 0.15)
                    .resizable()
                    .scaledToFill()
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: Layout.statsTopCardThumbWidth, height: Layout.statsTopCardThumbHeight)
        .clipShape(RoundedRectangle(cornerRadius: UVRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: UVRadius.sm)
                .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
        )
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Color.uv.panelLo
            Image(systemName: "rectangle.portrait")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.uv.muted2)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: Layout.heroIcon, weight: .medium))
                .foregroundStyle(Color.uv.muted)
            Text("Nothing to chart yet")
                .font(.uv.display(16, weight: .semibold))
                .foregroundStyle(Color.uv.text)
            Text("Add cards to this stack to see its breakdown.")
                .font(.uv.body(12))
                .foregroundStyle(Color.uv.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }

    // MARK: - Helpers

    @Environment(\.displayScale) private var displayScale

    private func intCount(_ slice: FormatSlice) -> Int {
        NSDecimalNumber(decimal: slice.valueUSD).intValue
    }

    private func count(_ slice: FormatSlice) -> String {
        "\(intCount(slice))"
    }
}

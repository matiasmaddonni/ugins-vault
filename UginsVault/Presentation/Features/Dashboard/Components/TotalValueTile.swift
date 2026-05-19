//
//  TotalValueTile.swift
//  UginsVault — Presentation: Dashboard
//
//  Hero tile (left, 1.4fr in the prototype grid). Displays the total
//  collection value, week-over-week delta pill + signed dollar delta,
//  and a 30-day sparkline.
//

import SwiftUI

public struct TotalValueTile: View {

    public let totalValueUSD: Decimal
    public let weekDeltaUSD: Decimal
    public let weekDeltaPct: Double
    public let monthSparkline: [Decimal]
    public let currency: Currency

    public init(
        totalValueUSD: Decimal,
        weekDeltaUSD: Decimal,
        weekDeltaPct: Double,
        monthSparkline: [Decimal],
        currency: Currency
    ) {
        self.totalValueUSD = totalValueUSD
        self.weekDeltaUSD = weekDeltaUSD
        self.weekDeltaPct = weekDeltaPct
        self.monthSparkline = monthSparkline
        self.currency = currency
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm - 2) {
            headerRow
            valueText
            deltaRow
            SparklineView(points: monthSparkline)
                .frame(height: Layout.dashboardSparklineHeight)
                .padding(.top, Spacing.xs)
                .accessibilityIdentifier(DashboardAccessibilityFields.sparkline)
        }
        .padding(.horizontal, Spacing.lg - 2)
        .padding(.top, Spacing.lg - 2)
        .padding(.bottom, Spacing.md - 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color.uv.panelHi, Color.uv.panel],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.lg)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(DashboardAccessibilityFields.totalValueTile)
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Total value")
                .uvSectionLabel()
            Spacer()
            Text("30d")
                .font(.uv.mono(10))
                .foregroundStyle(Color.uv.muted)
        }
    }

    private var valueText: some View {
        Text(CurrencyFormatter.format(totalValueUSD, currency: currency))
            .font(.uv.display(30, weight: .bold))
            .foregroundStyle(Color.uv.text)
            .tracking(-0.6)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .accessibilityIdentifier(DashboardAccessibilityFields.totalValueLabel)
    }

    private var deltaRow: some View {
        let isUp = weekDeltaPct >= 0
        let tone: Color = isUp ? Color.uv.up : Color.uv.down
        let arrow = isUp ? "arrow.up" : "arrow.down"
        return HStack(spacing: Spacing.sm - 2) {
            HStack(spacing: Spacing.xs - 1) {
                Image(systemName: arrow)
                    .font(.system(size: 10, weight: .semibold))
                Text(String(format: "%@%.1f%%", isUp ? "+" : "", weekDeltaPct))
                    .font(.uv.mono(10.5, weight: .semibold))
            }
            .foregroundStyle(tone)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(tone.opacity(0.18))
            )

            Text(signedMoney)
                .font(.uv.mono(10.5))
                .foregroundStyle(tone)
            Text("· this week")
                .font(.uv.mono(10.5))
                .foregroundStyle(Color.uv.muted)
        }
        .accessibilityIdentifier(DashboardAccessibilityFields.totalDeltaLabel)
    }

    private var signedMoney: String {
        var absoluteValue = weekDeltaUSD
        if absoluteValue < 0 {
            absoluteValue *= -1
        }
        let body = CurrencyFormatter.format(absoluteValue, currency: currency)
        let prefix = weekDeltaUSD >= 0 ? "+" : "-"
        return "\(prefix)\(body)"
    }
}

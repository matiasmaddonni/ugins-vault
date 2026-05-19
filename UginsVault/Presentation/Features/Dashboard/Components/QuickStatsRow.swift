//
//  QuickStatsRow.swift
//  UginsVault — Presentation: Dashboard
//
//  4-up grid at the bottom of the Dashboard: Total / Unique / Foils /
//  Avg. Layout collapses to 2-up on accessibility text sizes via
//  `LazyVGrid` because four bold numbers don't fit otherwise.
//

import SwiftUI

public struct QuickStatsRow: View {

    public let stats: CollectionStats
    public let currency: Currency

    public init(stats: CollectionStats, currency: Currency) {
        self.stats = stats
        self.currency = currency
    }

    public var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4),
                  spacing: Spacing.sm) {
            QuickStatCard(
                key: "total",
                label: "Total",
                value: thousands(stats.totalCards),
                sublabel: "cards"
            )
            QuickStatCard(
                key: "unique",
                label: "Unique",
                value: thousands(stats.uniqueCards),
                sublabel: "cards"
            )
            QuickStatCard(
                key: "foils",
                label: "Foils",
                value: thousands(stats.foils),
                sublabel: "owned"
            )
            QuickStatCard(
                key: "avg",
                label: "Avg",
                value: CurrencyFormatter.format(stats.avgValueUSD, currency: currency),
                sublabel: "per card"
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(DashboardAccessibilityFields.quickStatsRow)
    }

    private func thousands(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }
}

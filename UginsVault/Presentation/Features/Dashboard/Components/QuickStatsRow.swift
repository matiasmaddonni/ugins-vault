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
    public let rate: ExchangeRate?

    public init(stats: CollectionStats, currency: Currency, rate: ExchangeRate? = nil) {
        self.stats = stats
        self.currency = currency
        self.rate = rate
    }

    public var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Layout.dashboardRowSpacing), count: 3),
                  spacing: Layout.dashboardRowSpacing) {
            QuickStatCard(
                key: "total",
                label: "Total",
                value: thousands(stats.totalCards),
                sublabel: "in collection"
            )
            QuickStatCard(
                key: "unique",
                label: "Unique",
                value: thousands(stats.uniqueCards),
                sublabel: "printings"
            )
            QuickStatCard(
                key: "foils",
                label: "Foils",
                value: thousands(stats.foils),
                sublabel: "owned"
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(DashboardAccessibilityFields.quickStatsRow)
    }

    private func thousands(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }
}

//
//  ByFormatPanel.swift
//  UginsVault — Presentation: Dashboard
//
//  Value-by-format donut + legend wrapped in a SectionPanel.
//

import SwiftUI

public struct ByFormatPanel: View {

    public let slices: [FormatSlice]
    public let currency: Currency
    public let rate: ExchangeRate?

    public init(slices: [FormatSlice], currency: Currency, rate: ExchangeRate? = nil) {
        self.slices = slices
        self.currency = currency
        self.rate = rate
    }

    public var body: some View {
        SectionPanel(title: String(localized: "Value by format")) {
            HStack(spacing: Spacing.lg) {
                DonutChartView(
                    slices: slices,
                    size: Layout.dashboardDonutSize,
                    thickness: Layout.dashboardDonutThickness
                ) {
                    VStack(spacing: 0) {
                        Text("Total")
                            .uvSectionLabel()
                        Text(CurrencyFormatter.format(total, currency: currency, rate: rate))
                            .font(.uv.display(15, weight: .bold))
                            .foregroundStyle(Color.uv.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                            .frame(maxWidth: Layout.dashboardDonutSize - Layout.dashboardDonutThickness * 2 - Spacing.sm)
                    }
                }
                legend
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(DashboardAccessibilityFields.byFormatPanel)
    }

    private var total: Decimal {
        slices.reduce(.zero) { $0 + $1.valueUSD }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(slices) { slice in
                HStack(spacing: Spacing.sm) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: slice.colorHex))
                        .frame(
                            width: Layout.dashboardLegendSwatchSize,
                            height: Layout.dashboardLegendSwatchSize
                        )
                    Text(slice.displayName)
                        .font(.uv.body(13))
                        .foregroundStyle(Color.uv.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(CurrencyFormatter.format(slice.valueUSD, currency: currency, rate: rate))
                        .font(.uv.mono(12, weight: .medium))
                        .foregroundStyle(Color.uv.text2)
                }
                .accessibilityIdentifier(DashboardAccessibilityFields.formatSlice(slice.id))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

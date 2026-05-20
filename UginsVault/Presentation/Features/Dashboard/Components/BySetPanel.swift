//
//  BySetPanel.swift
//  UginsVault — Presentation: Dashboard
//
//  Value-by-set horizontal bars wrapped in a SectionPanel. Each bar
//  is the proportion of total value held by that set, gold-gradient
//  filled, with a per-bar entry-delay so they "wipe in" on appear.
//

import SwiftUI

public struct BySetPanel: View {

    public let bars: [SetBar]
    public let currency: Currency
    public let rate: ExchangeRate?

    @State private var animateProgress: Bool = false

    public init(bars: [SetBar], currency: Currency, rate: ExchangeRate? = nil) {
        self.bars = bars
        self.currency = currency
        self.rate = rate
    }

    public var body: some View {
        SectionPanel(title: String(localized: "Value by set")) {
            VStack(alignment: .leading, spacing: Spacing.md - 2) {
                ForEach(Array(bars.enumerated()), id: \.element.id) { index, bar in
                    barRow(index: index, bar: bar)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(DashboardAccessibilityFields.bySetPanel)
        .onAppear {
            animateProgress = true
        }
    }

    private var total: Decimal {
        bars.reduce(.zero) { $0 + $1.valueUSD }
    }

    private func barRow(index: Int, bar: SetBar) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                HStack(spacing: Spacing.xs + 2) {
                    Text(bar.code.uppercased())
                        .font(.uv.mono(12))
                        .foregroundStyle(Color.uv.muted)
                    Text(bar.name)
                        .font(.uv.body(12.5))
                        .foregroundStyle(Color.uv.text)
                }
                Spacer()
                Text(CurrencyFormatter.format(bar.valueUSD, currency: currency, rate: rate))
                    .font(.uv.mono(11.5, weight: .medium))
                    .foregroundStyle(Color.uv.text2)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.uv.panelLo)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.uv.goldLo, Color.uv.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * fraction(of: bar))
                        .animation(
                            .easeOut(duration: 0.5).delay(0.05 * Double(index)),
                            value: animateProgress
                        )
                }
            }
            .frame(height: Layout.dashboardSetBarHeight)
        }
        .accessibilityIdentifier(DashboardAccessibilityFields.setBar(at: index))
    }

    private func fraction(of bar: SetBar) -> CGFloat {
        guard total > 0, animateProgress else { return 0 }
        let ratio = NSDecimalNumber(decimal: bar.valueUSD).doubleValue
                  / NSDecimalNumber(decimal: total).doubleValue
        return CGFloat(min(max(ratio, 0), 1))
    }
}

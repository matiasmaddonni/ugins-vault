//
//  CardDetailView.swift
//  UginsVault — Presentation: CardDetail
//
//  Single-card screen. Hero image + name + type line + oracle text +
//  prices block. Pushed onto the Collection navigation stack on row tap.
//

import SwiftUI
import Kingfisher

public struct CardDetailView: View {

    private let card: Card
    private let displayCurrency: Currency

    public init(card: Card, displayCurrency: Currency) {
        self.card = card
        self.displayCurrency = displayCurrency
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                hero
                header
                oracleBlock
                pricesBlock
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.vertical, Spacing.lg)
        }
        .background(Color.uv.bg.ignoresSafeArea())
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero

    private var hero: some View {
        Group {
            if let url = card.images.hero {
                KFImage(url)
                    .placeholder { heroPlaceholder }
                    .fade(duration: 0.2)
                    .resizable()
                    .scaledToFit()
            } else {
                heroPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: UVRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: UVRadius.lg)
                .strokeBorder(Color.uv.stroke, lineWidth: 1)
        )
    }

    private var heroPlaceholder: some View {
        ZStack {
            Color.uv.panel
            Image(systemName: "rectangle.portrait")
                .font(.system(size: Layout.heroIcon, weight: .regular))
                .foregroundStyle(Color.uv.muted2)
        }
        .aspectRatio(488 / 680, contentMode: .fit)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(card.name)
                .font(.uv.display(24, weight: .semibold))
                .foregroundStyle(Color.uv.text)

            Text(card.typeLine)
                .font(.uv.body(14, weight: .medium))
                .foregroundStyle(Color.uv.text2)

            HStack(spacing: Spacing.sm) {
                Text(card.setName)
                    .font(.uv.mono(12))
                    .foregroundStyle(Color.uv.muted)

                Circle()
                    .fill(Color.uv.muted.opacity(0.5))
                    .frame(width: 3, height: 3)

                Text("#\(card.collectorNumber)")
                    .font(.uv.mono(12))
                    .foregroundStyle(Color.uv.muted)

                if card.rarity != .unknown {
                    Circle()
                        .fill(Color.uv.muted.opacity(0.5))
                        .frame(width: 3, height: 3)

                    Text(card.rarity.rawValue.uppercased())
                        .font(.uv.mono(11, weight: .semibold))
                        .foregroundStyle(Color.uv.gold)
                }
            }
        }
    }

    // MARK: - Oracle text

    @ViewBuilder
    private var oracleBlock: some View {
        if let text = card.oracleText, !text.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Rules text")
                    .uvSectionLabel()
                Text(text)
                    .font(.uv.body(15))
                    .foregroundStyle(Color.uv.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: UVRadius.md)
                    .fill(Color.uv.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: UVRadius.md)
                            .strokeBorder(Color.uv.stroke, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Prices

    private var pricesBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Prices")
                .uvSectionLabel()

            VStack(spacing: 0) {
                ForEach(Array(priceRows.enumerated()), id: \.offset) { index, row in
                    HStack {
                        Text(row.label)
                            .font(.uv.body(14, weight: .medium))
                            .foregroundStyle(Color.uv.text)

                        Spacer()

                        Text(row.value)
                            .font(.uv.mono(14, weight: .semibold))
                            .foregroundStyle(Color.uv.gold)
                    }
                    .padding(.horizontal, Spacing.rowHorizontal)
                    .padding(.vertical, Spacing.rowVertical)

                    if index != priceRows.count - 1 {
                        Rectangle()
                            .fill(Color.uv.stroke.opacity(0.6))
                            .frame(height: Layout.hairline)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: UVRadius.md)
                    .fill(Color.uv.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: UVRadius.md)
                            .strokeBorder(Color.uv.stroke, lineWidth: 1)
                    )
            )
        }
    }

    private struct PriceRow: Hashable {
        let label: String
        let value: String
    }

    private var priceRows: [PriceRow] {
        var rows: [PriceRow] = []
        if let usd = card.prices.usd {
            rows.append(.init(label: "Nonfoil", value: CurrencyFormatter.format(usd, currency: displayCurrency)))
        }
        if let foil = card.prices.usdFoil {
            rows.append(.init(label: "Foil", value: CurrencyFormatter.format(foil, currency: displayCurrency)))
        }
        if let etched = card.prices.usdEtched {
            rows.append(.init(label: "Etched", value: CurrencyFormatter.format(etched, currency: displayCurrency)))
        }
        if rows.isEmpty {
            rows.append(.init(label: "Nonfoil", value: "—"))
        }
        return rows
    }
}

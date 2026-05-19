//
//  CardRowView.swift
//  UginsVault — Presentation: Collection
//
//  List row showing a card thumbnail + name + set + USD price.
//

import SwiftUI
import Kingfisher

struct CardRowView: View {

    let card: Card
    let displayCurrency: Currency

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            thumbnail

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(card.name)
                    .font(.uv.body(15, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)

                Text(card.typeLine)
                    .font(.uv.body(12))
                    .foregroundStyle(Color.uv.muted)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    Text("\(card.setCode.uppercased()) · #\(card.collectorNumber)")
                        .font(.uv.mono(11))
                        .foregroundStyle(Color.uv.muted2)

                    if let price = card.prices.usdPrice(for: .nonfoil) {
                        Text(CurrencyFormatter.format(price, currency: displayCurrency))
                            .font(.uv.mono(11, weight: .semibold))
                            .foregroundStyle(Color.uv.gold)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.sm)
    }

    private var thumbnail: some View {
        Group {
            if let url = card.images.thumbnail {
                KFImage(url)
                    .placeholder { thumbnailPlaceholder }
                    .fade(duration: 0.15)
                    .resizable()
                    .scaledToFill()
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: 48, height: 68)
        .clipShape(RoundedRectangle(cornerRadius: UVRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: UVRadius.sm)
                .strokeBorder(Color.uv.stroke, lineWidth: 1)
        )
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Color.uv.panel
            Image(systemName: "rectangle.portrait")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.uv.muted2)
        }
    }
}

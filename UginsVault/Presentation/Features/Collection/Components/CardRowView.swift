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
    var rate: ExchangeRate? = nil
    var price: Decimal? = nil
    var isFetching: Bool = false

    @Environment(\.displayScale) private var displayScale

    /// Downsample target — Kingfisher decodes to this on its background queue
    /// and caches the small bitmap, so scrolling / re-filtering the list never
    /// re-decodes a full 488px JPG on the main actor.
    private static let pointSize = CGSize(
        width: Layout.collectionRowThumbWidth,
        height: Layout.collectionRowThumbHeight
    )

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

                    if let price {
                        Text(CurrencyFormatter.format(price, currency: displayCurrency, rate: rate))
                            .font(.uv.mono(11, weight: .semibold))
                            .foregroundStyle(Color.uv.gold)
                    } else if isFetching {
                        Text("Fetching…")
                            .font(.uv.mono(11))
                            .foregroundStyle(Color.uv.muted2)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.sm)
    }

    private var thumbnail: some View {
        Group {
            if let url = card.images.listThumbnail {
                KFImage(url)
                    .setProcessor(DownsamplingImageProcessor(size: Self.pointSize))
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
        .frame(width: Layout.collectionRowThumbWidth, height: Layout.collectionRowThumbHeight)
        .clipShape(RoundedRectangle(cornerRadius: UVRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: UVRadius.sm)
                .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
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

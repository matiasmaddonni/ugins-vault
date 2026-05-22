//
//  CollectionItemThumbnail.swift
//  UginsVault — Presentation: Stacks
//
//  Small image used on every `StackDetailView` card row. Renders the
//  Scryfall art-crop thumbnail when the joined `Card` is available;
//  falls back to a panel-tinted placeholder for unresolved items.
//

import SwiftUI
import Kingfisher

public struct CollectionItemThumbnail: View {

    public let card: Card?
    public let isFoil: Bool

    @Environment(\.displayScale) private var displayScale

    /// Target point size for the row thumbnail. Kingfisher downsamples the
    /// full Scryfall image to this on its background queue and caches the
    /// small bitmap — so first display + re-filters don't re-decode a 488px
    /// JPG on the main actor (the freeze when opening / searching the picker).
    private static let pointSize = CGSize(
        width: Layout.stackDetailRowThumbWidth,
        height: Layout.stackDetailRowThumbHeight
    )

    public init(card: Card?, isFoil: Bool = false) {
        self.card = card
        self.isFoil = isFoil
    }

    public var body: some View {
        Group {
            if let url = card?.images.listThumbnail {
                KFImage(url)
                    .setProcessor(DownsamplingImageProcessor(size: Self.pointSize))
                    .scaleFactor(displayScale)
                    .cacheOriginalImage()
                    .placeholder { placeholder }
                    .fade(duration: 0.15)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: Layout.stackDetailRowThumbWidth, height: Layout.stackDetailRowThumbHeight)
        .overlay {
            if isFoil {
                FoilSheen()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: UVRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: UVRadius.sm)
                .strokeBorder(isFoil ? Color.uv.gold.opacity(0.6) : Color.uv.stroke, lineWidth: Layout.hairline)
        )
    }

    private var placeholder: some View {
        ZStack {
            Color.uv.panelLo
            Image(systemName: "rectangle.portrait")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.uv.muted2)
        }
    }
}

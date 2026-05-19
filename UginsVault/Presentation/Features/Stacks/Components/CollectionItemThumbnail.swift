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

    public init(card: Card?) {
        self.card = card
    }

    public var body: some View {
        Group {
            if let url = card?.images.thumbnail {
                KFImage(url)
                    .placeholder { placeholder }
                    .fade(duration: 0.15)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: Layout.stackDetailRowThumbWidth, height: Layout.stackDetailRowThumbHeight)
        .clipShape(RoundedRectangle(cornerRadius: UVRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: UVRadius.sm)
                .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
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

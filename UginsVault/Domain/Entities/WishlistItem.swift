//
//  WishlistItem.swift
//  UginsVault — Domain layer
//
//  A card the user wants to acquire. The wishlist is intentionally
//  self-contained: each entry snapshots the display fields + a USD
//  price captured at add-time, so wishlisted cards do NOT need to live
//  in the local catalogue (they're usually added straight from a
//  Scryfall search).
//

import Foundation

public struct WishlistItem: Identifiable, Hashable, Sendable {

    /// Scryfall printing id — also the catalogue `Card.id` when the card
    /// happens to be owned. Used as the wishlist's logical key.
    public let id: UUID
    public let name: String
    public let typeLine: String
    public let setCode: String
    public let setName: String
    public let collectorNumber: String
    public let thumbnailURL: URL?
    /// USD price snapshot taken when the card was added. `nil` when the
    /// source had no price.
    public let usdPrice: Decimal?
    public let addedAt: Date

    public init(
        id: UUID,
        name: String,
        typeLine: String,
        setCode: String,
        setName: String,
        collectorNumber: String,
        thumbnailURL: URL? = nil,
        usdPrice: Decimal? = nil,
        addedAt: Date = .init()
    ) {
        self.id = id
        self.name = name
        self.typeLine = typeLine
        self.setCode = setCode
        self.setName = setName
        self.collectorNumber = collectorNumber
        self.thumbnailURL = thumbnailURL
        self.usdPrice = usdPrice
        self.addedAt = addedAt
    }
}

public extension WishlistItem {

    /// Builds a wishlist entry from a catalogue / search `Card`,
    /// snapshotting the fields the wishlist row renders + the nonfoil
    /// USD price.
    init(card: Card, addedAt: Date = .init()) {
        self.init(
            id: card.id,
            name: card.name,
            typeLine: card.typeLine,
            setCode: card.setCode,
            setName: card.setName,
            collectorNumber: card.collectorNumber,
            thumbnailURL: card.images.thumbnail,
            usdPrice: nil,
            addedAt: addedAt
        )
    }
}

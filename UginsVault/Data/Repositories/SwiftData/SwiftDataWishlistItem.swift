//
//  SwiftDataWishlistItem.swift
//  UginsVault — Data layer / SwiftData
//
//  Persistence shape for Domain `WishlistItem`. Flat fields — `URL` and
//  `Decimal` persist natively (same as `SwiftDataCard`). Mapped by
//  `WishlistItemMapper`.
//

import Foundation
import SwiftData

@Model
public final class SwiftDataWishlistItem {

    @Attribute(.unique) public var id: UUID
    public var name: String
    public var typeLine: String
    public var setCode: String
    public var setName: String
    public var collectorNumber: String
    public var thumbnailURL: URL?
    public var usdPrice: Decimal?
    public var addedAt: Date

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

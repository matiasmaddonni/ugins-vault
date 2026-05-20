//
//  WishlistItemMapper.swift
//  UginsVault — Data layer / SwiftData
//
//  Bridges Domain `WishlistItem` <-> persisted `SwiftDataWishlistItem`.
//

import Foundation

extension WishlistItem {

    init(from model: SwiftDataWishlistItem) {
        self.init(
            id: model.id,
            name: model.name,
            typeLine: model.typeLine,
            setCode: model.setCode,
            setName: model.setName,
            collectorNumber: model.collectorNumber,
            thumbnailURL: model.thumbnailURL,
            usdPrice: model.usdPrice,
            addedAt: model.addedAt
        )
    }
}

extension SwiftDataWishlistItem {

    convenience init(from item: WishlistItem) {
        self.init(
            id: item.id,
            name: item.name,
            typeLine: item.typeLine,
            setCode: item.setCode,
            setName: item.setName,
            collectorNumber: item.collectorNumber,
            thumbnailURL: item.thumbnailURL,
            usdPrice: item.usdPrice,
            addedAt: item.addedAt
        )
    }

    /// In-place update used when re-adding an existing card (refreshes
    /// the price/image snapshot without losing the original `addedAt`).
    func apply(_ item: WishlistItem) {
        name = item.name
        typeLine = item.typeLine
        setCode = item.setCode
        setName = item.setName
        collectorNumber = item.collectorNumber
        thumbnailURL = item.thumbnailURL
        usdPrice = item.usdPrice
    }
}

//
//  SwiftDataPriceSnapshot.swift
//  UginsVault — Data layer / SwiftData
//
//  Persistence shape for `PriceSnapshot`. Lives in the Data layer so
//  the Domain stays SwiftData-free. Mapped by
//  `PriceSnapshotMapper`.
//

import Foundation
import SwiftData

@Model
public final class SwiftDataPriceSnapshot {

    @Attribute(.unique) public var id: UUID
    public var cardID: UUID
    public var sourceRaw: String
    public var date: Date
    public var currencyRaw: String
    public var retail: Decimal

    public init(
        id: UUID,
        cardID: UUID,
        sourceRaw: String,
        date: Date,
        currencyRaw: String,
        retail: Decimal
    ) {
        self.id = id
        self.cardID = cardID
        self.sourceRaw = sourceRaw
        self.date = date
        self.currencyRaw = currencyRaw
        self.retail = retail
    }
}

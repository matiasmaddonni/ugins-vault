//
//  PriceSnapshot.swift
//  UginsVault — Domain layer / Pricing
//
//  One source's retail price for one card on one day. We persist many
//  of these per card (every source × every day in the rolling 30-day
//  window) so the Dashboard can compute deltas + sparklines without
//  any further network calls.
//

import Foundation

public struct PriceSnapshot: Identifiable, Equatable, Hashable, Codable, Sendable {

    public let id: UUID
    public let cardID: UUID
    public let source: PriceSource
    public let date: Date          // calendar day (00:00 UTC)
    public let currency: Currency  // matches `source.nativeCurrency`
    public let retail: Decimal     // signed positive

    public init(
        id: UUID = UUID(),
        cardID: UUID,
        source: PriceSource,
        date: Date,
        currency: Currency,
        retail: Decimal
    ) {
        self.id = id
        self.cardID = cardID
        self.source = source
        self.date = date
        self.currency = currency
        self.retail = retail
    }
}

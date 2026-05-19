//
//  CardPrices.swift
//  UginsVault — Domain layer
//
//  Latest snapshot of prices Scryfall publishes per printing. All values
//  are nullable — not every card sells in every currency, and Scryfall
//  drops the field when there's no data point.
//
//  v0.2 stores USD-denominated values verbatim. v0.3 will introduce
//  conversion rates on top of this struct.
//

import Foundation

public struct CardPrices: Codable, Hashable, Sendable {

    public let usd:       Decimal?
    public let usdFoil:   Decimal?
    public let usdEtched: Decimal?
    public let eur:       Decimal?
    public let eurFoil:   Decimal?
    public let tix:       Decimal?

    public init(
        usd: Decimal? = nil,
        usdFoil: Decimal? = nil,
        usdEtched: Decimal? = nil,
        eur: Decimal? = nil,
        eurFoil: Decimal? = nil,
        tix: Decimal? = nil
    ) {
        self.usd       = usd
        self.usdFoil   = usdFoil
        self.usdEtched = usdEtched
        self.eur       = eur
        self.eurFoil   = eurFoil
        self.tix       = tix
    }

    public static let zero = CardPrices()

    /// Returns the best available price for the given finish in USD.
    /// Falls back to the next-best USD field when the requested finish
    /// has no quote.
    public func usdPrice(for finish: Finish) -> Decimal? {
        switch finish {
        case .nonfoil: return usd ?? usdFoil ?? usdEtched
        case .foil:    return usdFoil ?? usd ?? usdEtched
        case .etched:  return usdEtched ?? usdFoil ?? usd
        }
    }
}

public struct PriceSnapshot: Codable, Hashable, Sendable {

    public let date: Date
    public let currency: Currency
    public let value: Decimal

    public init(date: Date, currency: Currency, value: Decimal) {
        self.date = date
        self.currency = currency
        self.value = value
    }
}

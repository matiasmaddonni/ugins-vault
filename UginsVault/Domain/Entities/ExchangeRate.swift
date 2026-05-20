//
//  ExchangeRate.swift
//  UginsVault — Domain layer
//
//  Single quote: how many `quote`-units one `base`-unit buys, sampled
//  at `fetchedAt`. The FX repo caches one of these per quote currency
//  with a 4-hour TTL (configurable later).
//

import Foundation

public struct ExchangeRate: Equatable, Hashable, Codable, Sendable {

    public let base: Currency
    public let quote: Currency
    public let rate: Decimal       // amount of `quote` per 1 unit of `base`
    public let fetchedAt: Date
    public let source: Source

    public enum Source: String, Codable, Sendable {
        case dolarapiBlue       // dolarapi.com.ar — blue dollar feed (USD→ARS)
        case frankfurter        // frankfurter.app — ECB rates (USD→EUR etc)
        case manual             // user-supplied override (Settings)
        case identity           // base == quote → rate 1.0
    }

    public init(
        base: Currency,
        quote: Currency,
        rate: Decimal,
        fetchedAt: Date,
        source: Source
    ) {
        self.base = base
        self.quote = quote
        self.rate = rate
        self.fetchedAt = fetchedAt
        self.source = source
    }
}

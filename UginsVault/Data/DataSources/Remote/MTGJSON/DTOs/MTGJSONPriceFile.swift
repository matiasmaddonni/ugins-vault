//
//  MTGJSONPriceFile.swift
//  UginsVault — Data layer / MTGJSON DTOs
//
//  Top-level shape of the AllPricesToday.json file. MTGJSON wraps
//  every payload in `{ "meta": {...}, "data": {...} }`. The `data`
//  dictionary maps card UUIDs (Scryfall ids) → per-format price
//  blocks. We only decode `paper.<source>.retail.normal` /
//  `retail.foil` — every other branch is skipped at parse time.
//
//  Reference: https://mtgjson.com/data-models/all-prices-today/
//

import Foundation

public struct MTGJSONPriceFileMeta: Decodable, Sendable {
    public let date: String     // ISO date "2026-05-19"
    public let version: String?
}

/// Per-card payload (`data[<uuid>]`).
///
/// Shape we care about:
///   { "paper": { "cardkingdom": { "retail": { "normal": { "2026-05-19": 5.99 } } } } }
public struct MTGJSONCardPrices: Decodable, Sendable {
    public let paper: [String: MTGJSONSourcePrices]?
}

public struct MTGJSONSourcePrices: Decodable, Sendable {
    public let retail: MTGJSONFinishPrices?
    public let currency: String?
}

public struct MTGJSONFinishPrices: Decodable, Sendable {
    public let normal: [String: Double]?     // date → price
    public let foil: [String: Double]?
    public let etched: [String: Double]?
}

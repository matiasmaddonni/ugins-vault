//
//  Card.swift
//  UginsVault — Domain layer
//
//  Canonical card record. One row per Scryfall printing — `id` is the
//  Scryfall printing id (per set / collector number / language), and
//  `oracleID` groups every printing of the same rules text.
//
//  v0.2 collapses "Oracle" and "Printing" into this single entity to
//  keep the seeder simple. If we ever need richer grouping queries
//  (e.g. "show me every printing of Lightning Bolt"), we'll add a
//  dedicated `OracleEntry` type without changing this shape.
//

import Foundation

public struct Card: Identifiable, Hashable, Codable, Sendable {

    // MARK: - Identifiers

    /// Scryfall printing id. Unique per (set, collector number, language, finish set).
    public let id: UUID
    /// Scryfall oracle id. Groups printings that share rules text.
    public let oracleID: UUID

    // MARK: - Oracle

    public let name: String
    public let typeLine: String
    public let oracleText: String?
    public let manaCost: String?
    public let cmc: Double
    public let colors: Set<ManaColor>
    public let colorIdentity: Set<ManaColor>

    // MARK: - Printing

    public let rarity: Rarity
    public let setCode: String
    public let setName: String
    public let collectorNumber: String
    public let language: String          // ISO-ish: "en", "es", "ja", ...
    public let releasedAt: Date?
    public let finishes: Set<Finish>
    public let images: CardImages
    public let prices: CardPrices

    public init(
        id: UUID,
        oracleID: UUID,
        name: String,
        typeLine: String,
        oracleText: String? = nil,
        manaCost: String? = nil,
        cmc: Double = 0,
        colors: Set<ManaColor> = [],
        colorIdentity: Set<ManaColor> = [],
        rarity: Rarity = .unknown,
        setCode: String,
        setName: String,
        collectorNumber: String,
        language: String = "en",
        releasedAt: Date? = nil,
        finishes: Set<Finish> = [.nonfoil],
        images: CardImages = CardImages(),
        prices: CardPrices = .zero
    ) {
        self.id = id
        self.oracleID = oracleID
        self.name = name
        self.typeLine = typeLine
        self.oracleText = oracleText
        self.manaCost = manaCost
        self.cmc = cmc
        self.colors = colors
        self.colorIdentity = colorIdentity
        self.rarity = rarity
        self.setCode = setCode
        self.setName = setName
        self.collectorNumber = collectorNumber
        self.language = language
        self.releasedAt = releasedAt
        self.finishes = finishes
        self.images = images
        self.prices = prices
    }
}

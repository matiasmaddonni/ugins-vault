//
//  StackStatistics.swift
//  UginsVault — Domain layer
//
//  Pure, testable per-stack analytics computed from a stack's items, the
//  joined `Card`s, and the latest price per card. Drives the per-stack
//  Statistics screen. No frameworks — colour hexes live here as raw
//  `UInt32` (same convention as `FormatSlice`) so Presentation can build
//  `Color`s without the Domain importing SwiftUI.
//
//  Distributions (colour / rarity / mana curve) are by CARD COUNT so they
//  stay meaningful even before prices land; value is surfaced separately in
//  the total + the top-cards list. The donut slices reuse `FormatSlice`,
//  whose `valueUSD` here carries the COUNT (the chart only needs relative
//  magnitudes).
//

import Foundation

public struct StackStatistics: Equatable, Sendable {

    // MARK: - Nested

    /// One bar of the mana curve. `id` is the converted-mana-cost bucket
    /// (0…6, with 7 meaning "7+"); lands are excluded.
    public struct CurveBar: Identifiable, Equatable, Sendable {
        public let id: Int
        public let label: String
        public let count: Int

        public init(id: Int, label: String, count: Int) {
            self.id = id
            self.label = label
            self.count = count
        }
    }

    /// A high-value row in the "Top cards" list.
    public struct TopCard: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let name: String
        public let setCode: String
        public let collectorNumber: String
        public let imageURL: URL?
        public let quantity: Int
        public let unitValueUSD: Decimal

        public init(
            id: UUID,
            name: String,
            setCode: String,
            collectorNumber: String,
            imageURL: URL?,
            quantity: Int,
            unitValueUSD: Decimal
        ) {
            self.id = id
            self.name = name
            self.setCode = setCode
            self.collectorNumber = collectorNumber
            self.imageURL = imageURL
            self.quantity = quantity
            self.unitValueUSD = unitValueUSD
        }

        public var lineValueUSD: Decimal { unitValueUSD * Decimal(quantity) }
    }

    // MARK: - Stored

    public let totalValueUSD: Decimal
    public let cardCount: Int          // sum of quantities
    public let uniqueCount: Int        // distinct rows
    public let byColor: [FormatSlice]
    public let byRarity: [FormatSlice]
    public let manaCurve: [CurveBar]
    public let topCards: [TopCard]
    /// The deck's pinned commander, when one is set and its row is present.
    /// Its value is ALSO included in `totalValueUSD` / the breakdowns — this
    /// just surfaces it so the user sees it counted.
    public let commander: TopCard?
    /// Fraction of the stack (by quantity) that has a usable price — drives a
    /// "prices still loading" hint when < 1.
    public let pricedFraction: Double

    public init(
        totalValueUSD: Decimal,
        cardCount: Int,
        uniqueCount: Int,
        byColor: [FormatSlice],
        byRarity: [FormatSlice],
        manaCurve: [CurveBar],
        topCards: [TopCard],
        commander: TopCard?,
        pricedFraction: Double
    ) {
        self.totalValueUSD = totalValueUSD
        self.cardCount = cardCount
        self.uniqueCount = uniqueCount
        self.byColor = byColor
        self.byRarity = byRarity
        self.manaCurve = manaCurve
        self.topCards = topCards
        self.commander = commander
        self.pricedFraction = pricedFraction
    }

    public var isEmpty: Bool { cardCount == 0 }

    public static let empty = StackStatistics(
        totalValueUSD: 0, cardCount: 0, uniqueCount: 0,
        byColor: [], byRarity: [], manaCurve: [], topCards: [], commander: nil, pricedFraction: 0
    )
}

// MARK: - Builder

public extension StackStatistics {

    /// Builds the analytics for one stack. Pure: same inputs → same output.
    /// - Parameters:
    ///   - items: the stack's rows.
    ///   - cardsByID: joined cards (rows without a hydrated card still count
    ///     toward totals but can't contribute colour/rarity/curve buckets).
    ///   - priceMap: latest retail (USD) per card id.
    ///   - topCount: how many high-value rows to surface.
    static func make(
        items: [CollectionItem],
        cardsByID: [UUID: Card],
        priceMap: [UUID: Decimal],
        commanderCardID: UUID? = nil,
        topCount: Int = 5
    ) -> StackStatistics {
        guard !items.isEmpty else { return .empty }

        var total: Decimal = 0
        var cardCount = 0
        var pricedCount = 0
        var colorCounts: [ColorBucket: Int] = [:]
        var rarityCounts: [RarityBucket: Int] = [:]
        var curveCounts: [Int: Int] = [:]
        var tops: [TopCard] = []

        for item in items {
            let qty = item.quantity
            cardCount += qty

            let price = priceMap[item.cardID]
            if let price {
                total += price * Decimal(qty)
                pricedCount += qty
            }

            guard let card = cardsByID[item.cardID] else { continue }

            colorCounts[ColorBucket(for: card), default: 0] += qty
            rarityCounts[RarityBucket(for: card.rarity), default: 0] += qty

            if !card.typeLine.lowercased().contains("land") {
                let bucket = min(Int(card.cmc.rounded()), 7)
                curveCounts[bucket, default: 0] += qty
            }

            if let price, price > 0 {
                tops.append(TopCard(
                    id: card.id,
                    name: card.name,
                    setCode: card.setCode,
                    collectorNumber: card.collectorNumber,
                    imageURL: card.images.listThumbnail,
                    quantity: qty,
                    unitValueUSD: price
                ))
            }
        }

        let byColor = ColorBucket.allCases.compactMap { bucket -> FormatSlice? in
            guard let count = colorCounts[bucket], count > 0 else { return nil }
            return FormatSlice(id: bucket.id, displayName: bucket.displayName,
                               valueUSD: Decimal(count), colorHex: bucket.colorHex)
        }

        let byRarity = RarityBucket.allCases.compactMap { bucket -> FormatSlice? in
            guard let count = rarityCounts[bucket], count > 0 else { return nil }
            return FormatSlice(id: bucket.id, displayName: bucket.displayName,
                               valueUSD: Decimal(count), colorHex: bucket.colorHex)
        }

        let manaCurve = (0...7).map { bucket in
            CurveBar(id: bucket, label: bucket == 7 ? "7+" : "\(bucket)",
                     count: curveCounts[bucket] ?? 0)
        }

        let topCards = tops
            .sorted { $0.lineValueUSD > $1.lineValueUSD }
            .prefix(topCount)
            .map { $0 }

        let pricedFraction = cardCount > 0 ? Double(pricedCount) / Double(cardCount) : 0

        var commander: TopCard?
        if let commanderCardID,
           let item = items.first(where: { $0.cardID == commanderCardID }),
           let card = cardsByID[commanderCardID] {
            commander = TopCard(
                id: card.id,
                name: card.name,
                setCode: card.setCode,
                collectorNumber: card.collectorNumber,
                imageURL: card.images.listThumbnail,
                quantity: item.quantity,
                unitValueUSD: priceMap[commanderCardID] ?? 0
            )
        }

        return StackStatistics(
            totalValueUSD: total,
            cardCount: cardCount,
            uniqueCount: items.count,
            byColor: byColor,
            byRarity: byRarity,
            manaCurve: manaCurve,
            topCards: topCards,
            commander: commander,
            pricedFraction: pricedFraction
        )
    }
}

// MARK: - Buckets

private enum ColorBucket: String, CaseIterable {
    case white, blue, black, red, green, multicolor, colorless

    init(for card: Card) {
        let colors = card.colors.subtracting([.colorless])
        if colors.count > 1 { self = .multicolor; return }
        switch colors.first {
        case .white: self = .white
        case .blue:  self = .blue
        case .black: self = .black
        case .red:   self = .red
        case .green: self = .green
        default:     self = .colorless
        }
    }

    var id: String { "color_\(rawValue)" }

    var displayName: String {
        switch self {
        case .white:      return String(localized: "White")
        case .blue:       return String(localized: "Blue")
        case .black:      return String(localized: "Black")
        case .red:        return String(localized: "Red")
        case .green:      return String(localized: "Green")
        case .multicolor: return String(localized: "Multicolor")
        case .colorless:  return String(localized: "Colorless")
        }
    }

    var colorHex: UInt32 {
        switch self {
        case .white:      return 0xF1E9C8
        case .blue:       return 0x6BA8D8
        case .black:      return 0x6B5D7A
        case .red:        return 0xD87858
        case .green:      return 0x6FA67A
        case .multicolor: return 0xC9A24B
        case .colorless:  return 0xC7C2B5
        }
    }
}

private enum RarityBucket: String, CaseIterable {
    case common, uncommon, rare, mythic, other

    init(for rarity: Rarity) {
        switch rarity {
        case .common:   self = .common
        case .uncommon: self = .uncommon
        case .rare:     self = .rare
        case .mythic:   self = .mythic
        case .special, .bonus, .unknown: self = .other
        }
    }

    var id: String { "rarity_\(rawValue)" }

    var displayName: String {
        switch self {
        case .common:   return String(localized: "Common")
        case .uncommon: return String(localized: "Uncommon")
        case .rare:     return String(localized: "Rare")
        case .mythic:   return String(localized: "Mythic")
        case .other:    return String(localized: "Other")
        }
    }

    var colorHex: UInt32 {
        switch self {
        case .common:   return 0xB8B2A6
        case .uncommon: return 0x9FB7C9
        case .rare:     return 0xD7B45A
        case .mythic:   return 0xD87858
        case .other:    return 0x6B5D7A
        }
    }
}

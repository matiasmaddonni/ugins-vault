//
//  CardQuery.swift
//  UginsVault — Domain layer
//
//  Combined search + filter + sort + pagination parameters consumed by
//  `CardRepository.refresh(_:)`. Bundles everything so views/VMs hand
//  the repository a single value type instead of a long arg list.
//

import Foundation

public struct CardQuery: Equatable, Sendable {

    public var text: String
    public var sort: CardSortOption
    public var filter: CardFilter
    public var offset: Int
    public var limit: Int

    public init(
        text: String = "",
        sort: CardSortOption = .nameAscending,
        filter: CardFilter = .empty,
        offset: Int = 0,
        limit: Int = 200
    ) {
        self.text = text
        self.sort = sort
        self.filter = filter
        self.offset = offset
        self.limit = limit
    }

    public static let recent = CardQuery()

    /// Returns a copy of this query with the offset advanced by `limit`
    /// rows, for "load more" pagination.
    public func nextPage() -> CardQuery {
        var copy = self
        copy.offset += limit
        return copy
    }
}

public enum CardSortOption: String, CaseIterable, Codable, Sendable, Identifiable {
    case nameAscending
    case priceDescending
    case releasedAtDescending
    case setCodeAscending

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .nameAscending:         return String(localized: "Name (A–Z)")
        case .priceDescending:       return String(localized: "Price (high → low)")
        case .releasedAtDescending:  return String(localized: "Newest first")
        case .setCodeAscending:      return String(localized: "Set")
        }
    }
}

public struct CardFilter: Equatable, Sendable {

    public var sets:     Set<String>     // Lowercased set codes
    public var colors:   Set<ManaColor>
    public var rarities: Set<Rarity>

    public init(
        sets: Set<String> = [],
        colors: Set<ManaColor> = [],
        rarities: Set<Rarity> = []
    ) {
        self.sets = sets
        self.colors = colors
        self.rarities = rarities
    }

    public static let empty = CardFilter()

    public var isEmpty: Bool {
        sets.isEmpty && colors.isEmpty && rarities.isEmpty
    }

    /// In-memory matcher used by the repository when a SwiftData
    /// `#Predicate` can't express the constraint (e.g. CSV-encoded
    /// colour sets).
    public func matches(_ card: Card) -> Bool {
        if !sets.isEmpty, !sets.contains(card.setCode.lowercased()) {
            return false
        }
        if !colors.isEmpty, !colors.isSubset(of: card.colors) {
            return false
        }
        if !rarities.isEmpty, !rarities.contains(card.rarity) {
            return false
        }
        return true
    }
}

//
//  SwiftDataCardRepository.swift
//  UginsVault — Data layer / SwiftData
//
//  `CardRepository` backed by SwiftData. Holds a `ModelContainer` and
//  works exclusively on its `mainContext` — appropriate because the
//  protocol is `@MainActor`. Background writes that need their own
//  context will go through `ModelActor` in a future iteration.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
public final class SwiftDataCardRepository: CardRepository {

    // MARK: - Observable state

    public private(set) var cards: [Card] = []
    public private(set) var isWriting: Bool = false

    // MARK: - Dependencies

    @ObservationIgnored private let modelContainer: ModelContainer
    @ObservationIgnored private var context: ModelContext { modelContainer.mainContext }

    // MARK: - Init

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Reads

    public func totalCount() async throws -> Int {
        let descriptor = FetchDescriptor<SwiftDataCard>()
        return try context.fetchCount(descriptor)
    }

    public func count(matching query: CardQuery) async throws -> Int {
        if query.filter.colors.isEmpty {
            var descriptor = FetchDescriptor<SwiftDataCard>(
                predicate: Self.makePredicate(for: query)
            )
            descriptor.fetchLimit = Int.max
            return try context.fetchCount(descriptor)
        }
        return try fetch(query: query, applyPagination: false).count
    }

    @discardableResult
    public func refresh(_ query: CardQuery) async throws -> [Card] {
        let loaded = try fetch(query: query, applyPagination: true)
        self.cards = loaded
        return loaded
    }

    public func card(id: UUID) async throws -> Card? {
        var descriptor = FetchDescriptor<SwiftDataCard>(
            predicate: #Predicate<SwiftDataCard> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first.map(Card.init(from:))
    }

    /// Distinct lowercase set codes currently in the catalogue, sorted.
    /// Used by the filter sheet to populate its set list.
    public func availableSetCodes() async throws -> [String] {
        let descriptor = FetchDescriptor<SwiftDataCard>(
            sortBy: [SortDescriptor(\.setCode, order: .forward)]
        )
        let codes = try context.fetch(descriptor).map(\.setCode)
        return Array(Set(codes)).sorted()
    }

    // MARK: - Writes

    public func save(_ cards: [Card]) async throws {
        guard !cards.isEmpty else { return }
        isWriting = true
        defer { isWriting = false }

        for card in cards {
            let cardID = card.id
            var descriptor = FetchDescriptor<SwiftDataCard>(
                predicate: #Predicate<SwiftDataCard> { $0.id == cardID }
            )
            descriptor.fetchLimit = 1

            if let existing = try context.fetch(descriptor).first {
                existing.apply(card)
            } else {
                context.insert(SwiftDataCard(from: card))
            }
        }

        try context.save()
    }

    public func delete(id: UUID) async throws {
        isWriting = true
        defer { isWriting = false }

        var descriptor = FetchDescriptor<SwiftDataCard>(
            predicate: #Predicate<SwiftDataCard> { $0.id == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
            cards.removeAll { $0.id == id }
        }
    }

    public func deleteAll() async throws {
        isWriting = true
        defer { isWriting = false }

        try context.delete(model: SwiftDataCard.self)
        try context.save()
        cards = []
    }

    // MARK: - Private

    /// Runs the predicate / sort that SwiftData can express natively,
    /// post-filters for colour membership (CSV-encoded so the `#Predicate`
    /// macro can't reach it cleanly), then trims to the requested
    /// offset/limit window.
    private func fetch(query: CardQuery, applyPagination: Bool) throws -> [Card] {
        var descriptor = FetchDescriptor<SwiftDataCard>(
            predicate: Self.makePredicate(for: query),
            sortBy: Self.sortDescriptors(for: query.sort)
        )

        if applyPagination, query.filter.colors.isEmpty {
            descriptor.fetchOffset = max(0, query.offset)
            descriptor.fetchLimit = max(1, query.limit)
            return try context.fetch(descriptor).map(Card.init(from:))
        }

        descriptor.fetchLimit = Int.max
        let allMatching = try context.fetch(descriptor).map(Card.init(from:))
        let colourFiltered = query.filter.colors.isEmpty
            ? allMatching
            : allMatching.filter { query.filter.colors.isSubset(of: $0.colors) }

        guard applyPagination else { return colourFiltered }
        let start = max(0, query.offset)
        guard start < colourFiltered.count else { return [] }
        let end = min(colourFiltered.count, start + max(1, query.limit))
        return Array(colourFiltered[start..<end])
    }

    private static func makePredicate(for query: CardQuery) -> Predicate<SwiftDataCard>? {
        let text = query.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercaseSets = Set(query.filter.sets.map { $0.lowercased() })
        let rarityRaws = Set(query.filter.rarities.map(\.rawValue))

        let hasText    = !text.isEmpty
        let hasSets    = !lowercaseSets.isEmpty
        let hasRarity  = !rarityRaws.isEmpty

        switch (hasText, hasSets, hasRarity) {
        case (false, false, false):
            return nil

        case (true, false, false):
            return #Predicate<SwiftDataCard> { card in
                card.name.localizedStandardContains(text)
            }

        case (false, true, false):
            return #Predicate<SwiftDataCard> { card in
                lowercaseSets.contains(card.setCode)
            }

        case (false, false, true):
            return #Predicate<SwiftDataCard> { card in
                rarityRaws.contains(card.rarityRaw)
            }

        case (true, true, false):
            return #Predicate<SwiftDataCard> { card in
                card.name.localizedStandardContains(text) &&
                lowercaseSets.contains(card.setCode)
            }

        case (true, false, true):
            return #Predicate<SwiftDataCard> { card in
                card.name.localizedStandardContains(text) &&
                rarityRaws.contains(card.rarityRaw)
            }

        case (false, true, true):
            return #Predicate<SwiftDataCard> { card in
                lowercaseSets.contains(card.setCode) &&
                rarityRaws.contains(card.rarityRaw)
            }

        case (true, true, true):
            return #Predicate<SwiftDataCard> { card in
                card.name.localizedStandardContains(text) &&
                lowercaseSets.contains(card.setCode) &&
                rarityRaws.contains(card.rarityRaw)
            }
        }
    }

    private static func sortDescriptors(for option: CardSortOption) -> [SortDescriptor<SwiftDataCard>] {
        switch option {
        case .nameAscending:
            return [SortDescriptor(\.name, order: .forward)]

        case .priceDescending:
            return [
                SortDescriptor(\.priceUSD, order: .reverse),
                SortDescriptor(\.name, order: .forward)
            ]

        case .releasedAtDescending:
            return [
                SortDescriptor(\.releasedAt, order: .reverse),
                SortDescriptor(\.name, order: .forward)
            ]

        case .setCodeAscending:
            return [
                SortDescriptor(\.setCode, order: .forward),
                SortDescriptor(\.collectorNumber, order: .forward)
            ]
        }
    }
}

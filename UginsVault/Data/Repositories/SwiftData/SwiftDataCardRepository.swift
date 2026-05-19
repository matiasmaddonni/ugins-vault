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
    @ObservationIgnored private let pageLimit: Int

    // MARK: - Init

    public init(modelContainer: ModelContainer, pageLimit: Int = 200) {
        self.modelContainer = modelContainer
        self.pageLimit = pageLimit
    }

    // MARK: - Reads

    public func totalCount() async throws -> Int {
        let descriptor = FetchDescriptor<SwiftDataCard>()
        return try context.fetchCount(descriptor)
    }

    @discardableResult
    public func refresh(query: String) async throws -> [Card] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var descriptor = FetchDescriptor<SwiftDataCard>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        descriptor.fetchLimit = pageLimit

        if !trimmed.isEmpty {
            descriptor.predicate = #Predicate<SwiftDataCard> { model in
                model.name.localizedStandardContains(trimmed)
            }
        }

        let models = try context.fetch(descriptor)
        let loaded = models.map(Card.init(from:))
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

    public func deleteAll() async throws {
        isWriting = true
        defer { isWriting = false }

        try context.delete(model: SwiftDataCard.self)
        try context.save()
        cards = []
    }
}

//
//  SwiftDataCollectionItemRepository.swift
//  UginsVault — Data layer / SwiftData
//
//  `CollectionItemRepository` backed by SwiftData via `@ModelActor`.
//  Owns its own background `ModelContext` (per Architecture.md's "actor
//  only for shared mutable state" rule — SwiftData's `ModelContext` is
//  exactly that). All fetches + saves run off the main actor; the actor
//  serialises access to the context.
//
//  Domain entities (`CollectionItem`) are `Sendable` value types, so no
//  `@Model`-bound references leak across the actor boundary.
//

import Foundation
import SwiftData

@ModelActor
public actor SwiftDataCollectionItemRepository: CollectionItemRepository {

    // MARK: - Reads

    public func items(in stackID: UUID) async throws -> [CollectionItem] {
        let descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            predicate: #Predicate<SwiftDataCollectionItem> { $0.stackID == stackID },
            sortBy: [SortDescriptor(\.acquiredAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(CollectionItem.init(from:))
    }

    public func cardCount(in stackID: UUID) async throws -> Int {
        try await items(in: stackID).reduce(0) { $0 + $1.quantity }
    }

    public func uniqueCount(in stackID: UUID) async throws -> Int {
        let descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            predicate: #Predicate<SwiftDataCollectionItem> { $0.stackID == stackID }
        )
        return try modelContext.fetchCount(descriptor)
    }

    public func item(id: UUID) async throws -> CollectionItem? {
        var descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            predicate: #Predicate<SwiftDataCollectionItem> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.map(CollectionItem.init(from:))
    }

    public func allItems() async throws -> [CollectionItem] {
        let descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            sortBy: [SortDescriptor(\.acquiredAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(CollectionItem.init(from:))
    }

    // MARK: - Writes

    public func save(_ item: CollectionItem) async throws {
        let itemID = item.id
        var descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            predicate: #Predicate<SwiftDataCollectionItem> { $0.id == itemID }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(item)
        } else {
            modelContext.insert(SwiftDataCollectionItem(from: item))
        }
        try modelContext.save()
    }

    public func save(_ items: [CollectionItem]) async throws {
        guard !items.isEmpty else { return }

        // ONE fetch of the existing rows up front (keyed by id) instead of a
        // fetch-per-item — a per-item descriptor in the loop turns a fresh
        // restore into hundreds of synchronous round trips and freezes the
        // app on launch.
        let existing = try modelContext.fetch(FetchDescriptor<SwiftDataCollectionItem>())
        var byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for item in items {
            if let row = byID[item.id] {
                row.apply(item)
            } else {
                let row = SwiftDataCollectionItem(from: item)
                modelContext.insert(row)
                byID[item.id] = row
            }
        }
        try modelContext.save()   // one write for the whole batch
    }

    public func delete(id: UUID) async throws {
        var descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            predicate: #Predicate<SwiftDataCollectionItem> { $0.id == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }

    public func deleteAll(in stackID: UUID) async throws {
        try modelContext.delete(
            model: SwiftDataCollectionItem.self,
            where: #Predicate<SwiftDataCollectionItem> { $0.stackID == stackID }
        )
        try modelContext.save()
    }

    public func deleteAll() async throws {
        try modelContext.delete(model: SwiftDataCollectionItem.self)
        try modelContext.save()
    }
}

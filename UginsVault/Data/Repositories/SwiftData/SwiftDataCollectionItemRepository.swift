//
//  SwiftDataCollectionItemRepository.swift
//  UginsVault — Data layer / SwiftData
//
//  `CollectionItemRepository` backed by SwiftData. Mainactor-isolated;
//  works on the shared container's `mainContext`.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
public final class SwiftDataCollectionItemRepository: CollectionItemRepository {

    public private(set) var isWriting: Bool = false

    @ObservationIgnored private let modelContainer: ModelContainer
    @ObservationIgnored private var context: ModelContext { modelContainer.mainContext }

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Reads

    public func items(in stackID: UUID) async throws -> [CollectionItem] {
        let descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            predicate: #Predicate<SwiftDataCollectionItem> { $0.stackID == stackID },
            sortBy: [SortDescriptor(\.acquiredAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(CollectionItem.init(from:))
    }

    public func cardCount(in stackID: UUID) async throws -> Int {
        try await items(in: stackID).reduce(0) { $0 + $1.quantity }
    }

    public func uniqueCount(in stackID: UUID) async throws -> Int {
        let descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            predicate: #Predicate<SwiftDataCollectionItem> { $0.stackID == stackID }
        )
        return try context.fetchCount(descriptor)
    }

    public func item(id: UUID) async throws -> CollectionItem? {
        var descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            predicate: #Predicate<SwiftDataCollectionItem> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first.map(CollectionItem.init(from:))
    }

    public func allItems() async throws -> [CollectionItem] {
        let descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            sortBy: [SortDescriptor(\.acquiredAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(CollectionItem.init(from:))
    }

    // MARK: - Writes

    public func save(_ item: CollectionItem) async throws {
        isWriting = true
        defer { isWriting = false }

        let itemID = item.id
        var descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            predicate: #Predicate<SwiftDataCollectionItem> { $0.id == itemID }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.apply(item)
        } else {
            context.insert(SwiftDataCollectionItem(from: item))
        }
        try context.save()
    }

    public func save(_ items: [CollectionItem]) async throws {
        guard !items.isEmpty else { return }
        isWriting = true
        defer { isWriting = false }

        // ONE fetch of the existing rows up front (keyed by id) instead of a
        // fetch-per-item — a per-item descriptor in the loop turns a fresh
        // restore into hundreds of synchronous main-actor round trips and
        // freezes the app on launch.
        let existing = try context.fetch(FetchDescriptor<SwiftDataCollectionItem>())
        var byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for item in items {
            if let row = byID[item.id] {
                row.apply(item)
            } else {
                let row = SwiftDataCollectionItem(from: item)
                context.insert(row)
                byID[item.id] = row
            }
        }
        try context.save()   // one write for the whole batch
    }

    public func delete(id: UUID) async throws {
        isWriting = true
        defer { isWriting = false }

        var descriptor = FetchDescriptor<SwiftDataCollectionItem>(
            predicate: #Predicate<SwiftDataCollectionItem> { $0.id == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }

    public func deleteAll(in stackID: UUID) async throws {
        isWriting = true
        defer { isWriting = false }

        try context.delete(
            model: SwiftDataCollectionItem.self,
            where: #Predicate<SwiftDataCollectionItem> { $0.stackID == stackID }
        )
        try context.save()
    }

    public func deleteAll() async throws {
        isWriting = true
        defer { isWriting = false }

        try context.delete(model: SwiftDataCollectionItem.self)
        try context.save()
    }
}

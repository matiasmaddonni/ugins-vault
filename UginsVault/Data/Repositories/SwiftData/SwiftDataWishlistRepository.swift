//
//  SwiftDataWishlistRepository.swift
//  UginsVault — Data layer / SwiftData
//
//  `WishlistRepository` backed by SwiftData on the shared
//  `ModelContainer`'s `mainContext`. Mirrors `SwiftDataStackRepository`.
//

import Foundation
import SwiftData

@MainActor
public final class SwiftDataWishlistRepository: WishlistRepository {

    private let modelContainer: ModelContainer
    private var context: ModelContext { modelContainer.mainContext }

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Reads

    @discardableResult
    public func refresh() async throws -> [WishlistItem] {
        let descriptor = FetchDescriptor<SwiftDataWishlistItem>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(WishlistItem.init(from:))
    }

    public func contains(id: UUID) async throws -> Bool {
        var descriptor = FetchDescriptor<SwiftDataWishlistItem>(
            predicate: #Predicate<SwiftDataWishlistItem> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetchCount(descriptor) > 0
    }

    // MARK: - Writes

    public func add(_ item: WishlistItem) async throws {
        let itemID = item.id
        var descriptor = FetchDescriptor<SwiftDataWishlistItem>(
            predicate: #Predicate<SwiftDataWishlistItem> { $0.id == itemID }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.apply(item)
        } else {
            context.insert(SwiftDataWishlistItem(from: item))
        }
        try context.save()
    }

    public func remove(id: UUID) async throws {
        var descriptor = FetchDescriptor<SwiftDataWishlistItem>(
            predicate: #Predicate<SwiftDataWishlistItem> { $0.id == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }
}

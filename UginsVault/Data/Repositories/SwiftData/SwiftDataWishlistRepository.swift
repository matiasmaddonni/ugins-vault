//
//  SwiftDataWishlistRepository.swift
//  UginsVault — Data layer / SwiftData
//
//  `WishlistRepository` backed by SwiftData via `@ModelActor`. Owns
//  its own background `ModelContext`.
//

import Foundation
import SwiftData

@ModelActor
public actor SwiftDataWishlistRepository: WishlistRepository {

    // MARK: - Reads

    @discardableResult
    public func refresh() async throws -> [WishlistItem] {
        let descriptor = FetchDescriptor<SwiftDataWishlistItem>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map(WishlistItem.init(from:))
    }

    public func contains(id: UUID) async throws -> Bool {
        var descriptor = FetchDescriptor<SwiftDataWishlistItem>(
            predicate: #Predicate<SwiftDataWishlistItem> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetchCount(descriptor) > 0
    }

    // MARK: - Writes

    public func add(_ item: WishlistItem) async throws {
        let itemID = item.id
        var descriptor = FetchDescriptor<SwiftDataWishlistItem>(
            predicate: #Predicate<SwiftDataWishlistItem> { $0.id == itemID }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(item)
        } else {
            modelContext.insert(SwiftDataWishlistItem(from: item))
        }
        try modelContext.save()
    }

    public func remove(id: UUID) async throws {
        var descriptor = FetchDescriptor<SwiftDataWishlistItem>(
            predicate: #Predicate<SwiftDataWishlistItem> { $0.id == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }
}

//
//  SwiftDataCollectionItemRepositoryTests.swift
//  UginsVaultTests — Data / SwiftData
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("SwiftDataCollectionItemRepository")
@MainActor
struct SwiftDataCollectionItemRepositoryTests {

    private func makeRepository() throws -> SwiftDataCollectionItemRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataStack.self, SwiftDataCollectionItem.self,
            configurations: config
        )
        return SwiftDataCollectionItemRepository(modelContainer: container)
    }

    private func makeItem(stackID: UUID, quantity: Int = 1) -> CollectionItem {
        CollectionItem(
            cardID: UUID(),
            stackID: stackID,
            quantity: quantity,
            finish: .nonfoil,
            condition: .nearMint
        )
    }

    @Test("save inserts + items(in:) returns just that stack's rows")
    func saveAndQueryByStack() async throws {
        let repo = try makeRepository()
        let stackA = UUID()
        let stackB = UUID()

        try await repo.save(makeItem(stackID: stackA))
        try await repo.save(makeItem(stackID: stackA))
        try await repo.save(makeItem(stackID: stackB))

        let inA = try await repo.items(in: stackA)
        let inB = try await repo.items(in: stackB)

        #expect(inA.count == 2)
        #expect(inB.count == 1)
    }

    @Test("cardCount sums quantity across the stack")
    func cardCountSums() async throws {
        let repo = try makeRepository()
        let stack = UUID()

        try await repo.save(makeItem(stackID: stack, quantity: 4))
        try await repo.save(makeItem(stackID: stack, quantity: 3))

        #expect(try await repo.cardCount(in: stack) == 7)
    }

    @Test("uniqueCount returns row count regardless of quantity")
    func uniqueCount() async throws {
        let repo = try makeRepository()
        let stack = UUID()

        try await repo.save(makeItem(stackID: stack, quantity: 4))
        try await repo.save(makeItem(stackID: stack, quantity: 3))

        #expect(try await repo.uniqueCount(in: stack) == 2)
    }

    @Test("save is idempotent — updates quantity in place")
    func saveIsIdempotent() async throws {
        let repo = try makeRepository()
        let stack = UUID()
        let item = makeItem(stackID: stack, quantity: 1)
        try await repo.save(item)

        var updated = item
        updated.quantity = 5
        try await repo.save(updated)

        let loaded = try await repo.items(in: stack)
        #expect(loaded.count == 1)
        #expect(loaded.first?.quantity == 5)
    }

    @Test("delete(id:) removes a single row")
    func deleteByID() async throws {
        let repo = try makeRepository()
        let stack = UUID()
        let item = makeItem(stackID: stack)
        try await repo.save(item)

        try await repo.delete(id: item.id)

        #expect(try await repo.items(in: stack).isEmpty)
    }

    @Test("deleteAll(in:) removes only items in that stack")
    func deleteAllInStack() async throws {
        let repo = try makeRepository()
        let stackA = UUID()
        let stackB = UUID()
        try await repo.save(makeItem(stackID: stackA))
        try await repo.save(makeItem(stackID: stackA))
        try await repo.save(makeItem(stackID: stackB))

        try await repo.deleteAll(in: stackA)

        #expect(try await repo.items(in: stackA).isEmpty)
        #expect(try await repo.items(in: stackB).count == 1)
    }

    @Test("CollectionItem mapper round-trips finish, condition, language, notes")
    func mapperRoundTrips() async throws {
        let repo = try makeRepository()
        let stack = UUID()
        let item = CollectionItem(
            cardID: UUID(),
            stackID: stack,
            quantity: 2,
            finish: .foil,
            condition: .moderatelyPlayed,
            language: "es",
            acquiredAt: Date(timeIntervalSince1970: 100),
            notes: "Signed at GP Buenos Aires"
        )
        try await repo.save(item)

        let loaded = try await repo.item(id: item.id)

        #expect(loaded?.finish == .foil)
        #expect(loaded?.condition == .moderatelyPlayed)
        #expect(loaded?.language == "es")
        #expect(loaded?.notes == "Signed at GP Buenos Aires")
    }
}

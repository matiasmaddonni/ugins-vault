//
//  SwiftDataWishlistRepositoryTests.swift
//  UginsVaultTests — Data / SwiftData
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("SwiftDataWishlistRepository")
@MainActor
struct SwiftDataWishlistRepositoryTests {

    private func makeRepository() throws -> SwiftDataWishlistRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataWishlistItem.self, configurations: config)
        return SwiftDataWishlistRepository(modelContainer: container)
    }

    private func makeItem(
        id: UUID = UUID(),
        name: String = "Sheoldred, the Apocalypse",
        addedAt: Date = .init()
    ) -> WishlistItem {
        WishlistItem(
            id: id,
            name: name,
            typeLine: "Legendary Creature — Phyrexian Praetor",
            setCode: "DMU",
            setName: "Dominaria United",
            collectorNumber: "107",
            thumbnailURL: URL(string: "https://example.com/s.jpg"),
            usdPrice: Decimal(string: "85.00"),
            addedAt: addedAt
        )
    }

    @Test("Starts empty")
    func emptyStart() async throws {
        let repo = try makeRepository()
        #expect(try await repo.refresh().isEmpty)
    }

    @Test("add inserts + refresh exposes the row")
    func addInserts() async throws {
        let repo = try makeRepository()
        try await repo.add(makeItem())

        let loaded = try await repo.refresh()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Sheoldred, the Apocalypse")
        #expect(loaded.first?.usdPrice == Decimal(string: "85.00"))
    }

    @Test("add is idempotent by id")
    func addIdempotent() async throws {
        let repo = try makeRepository()
        let id = UUID()
        try await repo.add(makeItem(id: id))
        try await repo.add(makeItem(id: id, name: "Renamed"))

        let loaded = try await repo.refresh()
        #expect(loaded.count == 1)
    }

    @Test("contains reflects membership")
    func contains() async throws {
        let repo = try makeRepository()
        let id = UUID()
        #expect(try await repo.contains(id: id) == false)
        try await repo.add(makeItem(id: id))
        #expect(try await repo.contains(id: id) == true)
    }

    @Test("remove deletes the entry")
    func remove() async throws {
        let repo = try makeRepository()
        let id = UUID()
        try await repo.add(makeItem(id: id))
        try await repo.remove(id: id)

        #expect(try await repo.refresh().isEmpty)
        #expect(try await repo.contains(id: id) == false)
    }

    @Test("refresh sorts newest-added first")
    func sortsNewestFirst() async throws {
        let repo = try makeRepository()
        let older = makeItem(name: "Older", addedAt: Date(timeIntervalSince1970: 1_000))
        let newer = makeItem(name: "Newer", addedAt: Date(timeIntervalSince1970: 2_000))
        try await repo.add(older)
        try await repo.add(newer)

        let loaded = try await repo.refresh()
        #expect(loaded.map(\.name) == ["Newer", "Older"])
    }
}

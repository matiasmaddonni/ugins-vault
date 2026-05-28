//
//  SwiftDataStackRepositoryTests.swift
//  UginsVaultTests — Data / SwiftData
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("SwiftDataStackRepository")
@MainActor
struct SwiftDataStackRepositoryTests {

    private func makeRepository() throws -> SwiftDataStackRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataStack.self, SwiftDataCollectionItem.self,
            configurations: config
        )
        return SwiftDataStackRepository(modelContainer: container)
    }

    private func makeDeck(name: String = "Rakdos Scam") -> Stack {
        Stack(
            id: UUID(),
            name: name,
            kind: .deck,
            format: .modern,
            colors: [.red, .black]
        )
    }

    @Test("totalCount starts at zero")
    func emptyStart() async throws {
        let repo = try makeRepository()
        #expect(try await repo.totalCount() == 0)
    }

    @Test("save inserts + refresh exposes the row")
    func saveInserts() async throws {
        let repo = try makeRepository()
        try await repo.save(makeDeck())

        let loaded = try await repo.refresh()

        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Rakdos Scam")
        #expect(loaded.first?.format == .modern)
        #expect(loaded.first?.colors == [.red, .black])
    }

    @Test("save is idempotent by id — updates the existing row in place")
    func saveIsIdempotent() async throws {
        let repo = try makeRepository()
        let deck = makeDeck()
        try await repo.save(deck)

        var updated = deck
        updated.name = "Rakdos Scam (sideboard tweak)"
        try await repo.save(updated)

        let loaded = try await repo.refresh()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Rakdos Scam (sideboard tweak)")
    }

    @Test("delete(id:) removes a single stack")
    func deleteByIDRemovesOne() async throws {
        let repo = try makeRepository()
        let a = makeDeck(name: "A")
        let b = makeDeck(name: "B")
        try await repo.save(a)
        try await repo.save(b)
        _ = try await repo.refresh()

        try await repo.delete(id: a.id)

        let loaded = try await repo.refresh()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "B")
    }

    @Test("deleteAll wipes the stack table")
    func deleteAllWipes() async throws {
        let repo = try makeRepository()
        try await repo.save(makeDeck(name: "A"))
        try await repo.save(makeDeck(name: "B"))
        #expect(try await repo.totalCount() == 2)

        try await repo.deleteAll()

        #expect(try await repo.totalCount() == 0)
    }

    @Test("refresh sorts by sortOrder ascending then createdAt")
    func refreshSorts() async throws {
        let repo = try makeRepository()
        let earlier = Stack(name: "First", kind: .inbox, sortOrder: 1, createdAt: Date(timeIntervalSince1970: 1))
        let later   = Stack(name: "Second", kind: .inbox, sortOrder: 0, createdAt: Date(timeIntervalSince1970: 2))
        try await repo.save(earlier)
        try await repo.save(later)

        let loaded = try await repo.refresh()

        #expect(loaded.map(\.name) == ["Second", "First"])
    }

    @Test("Stack round-trips deck-only + loan-only fields")
    func stackRoundTripsAllFields() async throws {
        let repo = try makeRepository()
        let loan = Stack(
            id: UUID(),
            name: "Mariana's Birds",
            kind: .loan,
            person: "Mariana",
            since: Date(timeIntervalSince1970: 1696500000)
        )
        try await repo.save(loan)

        let loaded = try await repo.stack(id: loan.id)

        #expect(loaded?.person == "Mariana")
        #expect(loaded?.since == Date(timeIntervalSince1970: 1696500000))
        #expect(loaded?.kind == .loan)
    }
}

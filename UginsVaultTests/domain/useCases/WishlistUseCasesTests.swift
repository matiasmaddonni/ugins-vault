//
//  WishlistUseCasesTests.swift
//  UginsVaultTests — Domain / Use cases
//
//  Integration-style: the use cases run against a real in-memory
//  SwiftData wishlist repo (no bespoke mock needed for one-liners).
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("Wishlist use cases")
@MainActor
struct WishlistUseCasesTests {

    private func makeRepository() throws -> SwiftDataWishlistRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataWishlistItem.self, configurations: config)
        return SwiftDataWishlistRepository(modelContainer: container)
    }

    private func makeCard(id: UUID = UUID(), name: String = "Ragavan, Nimble Pilferer") -> Card {
        Card(
            id: id,
            oracleID: UUID(),
            name: name,
            typeLine: "Legendary Creature — Monkey Pirate",
            setCode: "MH2",
            setName: "Modern Horizons 2",
            collectorNumber: "138"
        )
    }

    @Test("Add maps a Card → wishlist entry; Get returns it")
    func addThenGet() async throws {
        let repo = try makeRepository()
        let card = makeCard()
        try await AddToWishlistUseCase(repository: repo).execute(card: card)

        let items = try await GetWishlistUseCase(repository: repo).execute()
        #expect(items.count == 1)
        #expect(items.first?.id == card.id)
        #expect(items.first?.name == card.name)
    }

    @Test("Adding the same card twice is a no-op")
    func addIdempotent() async throws {
        let repo = try makeRepository()
        let card = makeCard()
        let add = AddToWishlistUseCase(repository: repo)
        try await add.execute(card: card)
        try await add.execute(card: card)

        #expect(try await GetWishlistUseCase(repository: repo).execute().count == 1)
    }

    @Test("Membership reflects adds; Remove clears it")
    func membershipAndRemove() async throws {
        let repo = try makeRepository()
        let card = makeCard()

        #expect(try await repo.contains(id: card.id) == false)
        try await AddToWishlistUseCase(repository: repo).execute(card: card)
        #expect(try await repo.contains(id: card.id) == true)

        try await RemoveFromWishlistUseCase(repository: repo).execute(id: card.id)
        #expect(try await repo.contains(id: card.id) == false)
    }
}

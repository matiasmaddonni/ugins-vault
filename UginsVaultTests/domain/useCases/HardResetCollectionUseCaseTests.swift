//
//  HardResetCollectionUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("HardResetCollectionUseCase")
@MainActor
struct HardResetCollectionUseCaseTests {

    private struct Boom: Error {}

    private func makeRepos() throws -> (
        SwiftDataCardRepository, SwiftDataStackRepository, SwiftDataCollectionItemRepository
    ) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataCard.self, SwiftDataStack.self, SwiftDataCollectionItem.self,
            configurations: config
        )
        return (
            SwiftDataCardRepository(modelContainer: container),
            SwiftDataStackRepository(modelContainer: container),
            SwiftDataCollectionItemRepository(modelContainer: container)
        )
    }

    private func seed(
        cards: SwiftDataCardRepository,
        stacks: SwiftDataStackRepository,
        items: SwiftDataCollectionItemRepository
    ) async throws -> UUID {
        let cardID = UUID()
        let stack = Stack(name: "Deck", kind: .deck)
        try await stacks.save(stack)
        try await cards.save([Card(
            id: cardID, oracleID: UUID(), name: "Sol Ring",
            typeLine: "Artifact", setCode: "cmm", setName: "Commander Masters",
            collectorNumber: "1"
        )])
        try await items.save(CollectionItem(cardID: cardID, stackID: stack.id))
        return stack.id
    }

    @Test("wipes backend (empty PUT) + the whole local cache")
    func wipesEverything() async throws {
        let (cards, stacks, items) = try makeRepos()
        _ = try await seed(cards: cards, stacks: stacks, items: items)
        let remote = MockRemoteCollectionStore()

        let sut = HardResetCollectionUseCase(
            remote: remote, itemRepository: items,
            stackRepository: stacks, cardRepository: cards
        )
        try await sut.execute()

        // Backend got a full empty replace.
        #expect(remote.replaced?.stacks.isEmpty == true)
        #expect(remote.replaced?.items.isEmpty == true)
        // Local cache is empty.
        #expect(try await items.allItems().isEmpty)
        #expect(try await stacks.totalCount() == 0)
        #expect(try await cards.totalCount() == 0)
    }

    @Test("backend wipe failure aborts before touching local state")
    func backendFailureKeepsLocal() async throws {
        let (cards, stacks, items) = try makeRepos()
        _ = try await seed(cards: cards, stacks: stacks, items: items)
        let remote = MockRemoteCollectionStore()
        remote.replaceError = Boom()

        let sut = HardResetCollectionUseCase(
            remote: remote, itemRepository: items,
            stackRepository: stacks, cardRepository: cards
        )

        await #expect(throws: Boom.self) { try await sut.execute() }
        // Local cache untouched.
        #expect(try await items.allItems().isEmpty == false)
        #expect(try await cards.totalCount() == 1)
    }
}

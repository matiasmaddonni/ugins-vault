//
//  PushOwnedUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("PushOwnedUseCase")
@MainActor
struct PushOwnedUseCaseTests {

    final class CapturingOwnedSync: RemoteOwnedSync, @unchecked Sendable {
        private(set) var pushed: [OwnedCardCount]?
        func push(_ cards: [OwnedCardCount]) async throws { pushed = cards }
    }

    private func makeRepo() throws -> SwiftDataCollectionItemRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataCollectionItem.self, configurations: config)
        return SwiftDataCollectionItemRepository(modelContainer: container)
    }

    @Test("sums quantity per card across stacks, then pushes")
    func sumsAndPushes() async throws {
        let repo = try makeRepo()
        let cardA = UUID()
        let cardB = UUID()
        try await repo.save(CollectionItem(cardID: cardA, stackID: UUID(), quantity: 2))
        try await repo.save(CollectionItem(cardID: cardA, stackID: UUID(), quantity: 3))
        try await repo.save(CollectionItem(cardID: cardB, stackID: UUID(), quantity: 1))

        let sync = CapturingOwnedSync()
        let sut = PushOwnedUseCase(collectionItemRepository: repo, remoteOwnedSync: sync)

        let count = try await sut.execute()

        #expect(count == 2)
        let pushed = try #require(sync.pushed)
        #expect(Set(pushed.map(\.cardID)) == [cardA, cardB])
        #expect(pushed.first(where: { $0.cardID == cardA })?.quantity == 5)
        #expect(pushed.first(where: { $0.cardID == cardB })?.quantity == 1)
    }

    @Test("empty collection pushes an empty list")
    func emptyPushesEmpty() async throws {
        let repo = try makeRepo()
        let sync = CapturingOwnedSync()
        let sut = PushOwnedUseCase(collectionItemRepository: repo, remoteOwnedSync: sync)

        let count = try await sut.execute()

        #expect(count == 0)
        #expect(sync.pushed?.isEmpty == true)
    }
}

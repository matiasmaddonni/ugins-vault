//
//  MoveCollectionItemUseCaseTests.swift
//  UginsVaultTests
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("MoveCollectionItemUseCase")
@MainActor
struct MoveCollectionItemUseCaseTests {

    private func makeRepo() throws -> SwiftDataCollectionItemRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataStack.self, SwiftDataCollectionItem.self,
            configurations: config
        )
        return SwiftDataCollectionItemRepository(modelContainer: container)
    }

    private func makeItem(stackID: UUID) -> CollectionItem {
        CollectionItem(cardID: UUID(), stackID: stackID, quantity: 2)
    }

    @Test("Re-parents an item to a different stack")
    func moveReparentsItem() async throws {
        let repo = try makeRepo()
        let sut = MoveCollectionItemUseCase(itemRepository: repo)
        let stackA = UUID()
        let stackB = UUID()
        let item = makeItem(stackID: stackA)
        try await repo.save(item)

        try await sut.execute(itemID: item.id, targetStackID: stackB)

        #expect(try await repo.items(in: stackA).isEmpty)
        let inB = try await repo.items(in: stackB)
        #expect(inB.count == 1)
        #expect(inB.first?.id == item.id)
    }

    @Test("No-op when item already lives in the target stack")
    func noopWhenAlreadyInTarget() async throws {
        let repo = try makeRepo()
        let sut = MoveCollectionItemUseCase(itemRepository: repo)
        let stack = UUID()
        let item = makeItem(stackID: stack)
        try await repo.save(item)

        try await sut.execute(itemID: item.id, targetStackID: stack)

        #expect(try await repo.items(in: stack).count == 1)
    }

    @Test("Throws when the item id can't be found")
    func throwsWhenItemMissing() async throws {
        let repo = try makeRepo()
        let sut = MoveCollectionItemUseCase(itemRepository: repo)

        await #expect(throws: MoveCollectionItemError.itemNotFound) {
            try await sut.execute(itemID: UUID(), targetStackID: UUID())
        }
    }
}

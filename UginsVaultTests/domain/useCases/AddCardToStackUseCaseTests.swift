//
//  AddCardToStackUseCaseTests.swift
//  UginsVaultTests
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("AddCardToStackUseCase")
@MainActor
struct AddCardToStackUseCaseTests {

    private func makeRepo() throws -> SwiftDataCollectionItemRepository {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataStack.self, SwiftDataCollectionItem.self,
            configurations: config
        )
        return SwiftDataCollectionItemRepository(modelContainer: container)
    }

    @Test("Inserts a new row when no matching tuple exists")
    func insertsNewRow() async throws {
        let repo = try makeRepo()
        let sut = AddCardToStackUseCase(itemRepository: repo)
        let card = UUID()
        let stack = UUID()

        try await sut.execute(cardID: card, stackID: stack, quantity: 2)

        let items = try await repo.items(in: stack)
        #expect(items.count == 1)
        #expect(items.first?.cardID == card)
        #expect(items.first?.quantity == 2)
    }

    @Test("Bumps the quantity on the existing row when (cardID, finish, condition, language) match")
    func bumpsQuantityOnMatch() async throws {
        let repo = try makeRepo()
        let sut = AddCardToStackUseCase(itemRepository: repo)
        let card = UUID()
        let stack = UUID()

        try await sut.execute(cardID: card, stackID: stack, quantity: 1)
        try await sut.execute(cardID: card, stackID: stack, quantity: 3)

        let items = try await repo.items(in: stack)
        #expect(items.count == 1)
        #expect(items.first?.quantity == 4)
    }

    @Test("Splits to a second row when finish or condition differ")
    func splitsOnDifferingFinish() async throws {
        let repo = try makeRepo()
        let sut = AddCardToStackUseCase(itemRepository: repo)
        let card = UUID()
        let stack = UUID()

        try await sut.execute(cardID: card, stackID: stack, quantity: 1, finish: .nonfoil)
        try await sut.execute(cardID: card, stackID: stack, quantity: 1, finish: .foil)

        let items = try await repo.items(in: stack)
        #expect(items.count == 2)
        #expect(items.map(\.quantity).reduce(0, +) == 2)
    }

    @Test("Throws on non-positive quantity")
    func invalidQuantityThrows() async throws {
        let repo = try makeRepo()
        let sut = AddCardToStackUseCase(itemRepository: repo)

        await #expect(throws: AddCardToStackError.invalidQuantity) {
            try await sut.execute(cardID: UUID(), stackID: UUID(), quantity: 0)
        }
    }
}

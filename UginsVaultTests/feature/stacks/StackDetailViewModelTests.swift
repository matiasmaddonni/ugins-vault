//
//  StackDetailViewModelTests.swift
//  UginsVaultTests
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("StackDetailViewModel")
@MainActor
struct StackDetailViewModelTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: SwiftDataStack.self, SwiftDataCollectionItem.self,
            configurations: config
        )
    }

    private func makeSUT(stack: Stack) throws -> (
        StackDetailViewModel,
        SwiftDataCollectionItemRepository,
        MockSessionRepository
    ) {
        let container = try makeContainer()
        let itemRepo  = SwiftDataCollectionItemRepository(modelContainer: container)
        let session   = MockSessionRepository()
        let sut = StackDetailViewModel(
            stack: stack,
            itemRepository: itemRepo,
            sessionRepository: session
        )
        return (sut, itemRepo, session)
    }

    private func makeSUTWithStackRepo(stack: Stack) throws -> (
        StackDetailViewModel,
        SwiftDataStackRepository,
        SwiftDataCollectionItemRepository
    ) {
        let container = try makeContainer()
        let stackRepo = SwiftDataStackRepository(modelContainer: container)
        let itemRepo  = SwiftDataCollectionItemRepository(modelContainer: container)
        let session   = MockSessionRepository()
        let sut = StackDetailViewModel(
            stack: stack,
            itemRepository: itemRepo,
            sessionRepository: session,
            stackRepository: stackRepo
        )
        return (sut, stackRepo, itemRepo)
    }

    private func makeDeck(format: Format = .modern, colors: Set<ManaColor> = [.red]) -> Stack {
        Stack(id: UUID(), name: "Burn", kind: .deck, format: format, colors: colors)
    }

    private func makeItem(stackID: UUID, quantity: Int = 1) -> CollectionItem {
        CollectionItem(cardID: UUID(), stackID: stackID, quantity: quantity)
    }

    // MARK: - Tests

    @Test("Defaults: idle, empty items, counts zero")
    func defaultsAreEmpty() throws {
        let stack = makeDeck()
        let (sut, _, _) = try makeSUT(stack: stack)
        #expect(sut.items.isEmpty)
        #expect(sut.cardCount == 0)
        #expect(sut.uniqueCount == 0)
        #expect(sut.status == .idle)
        #expect(sut.isEmpty)
    }

    @Test("refresh loads items + computes cardCount + uniqueCount")
    func refreshHydratesCounts() async throws {
        let stack = makeDeck()
        let (sut, itemRepo, _) = try makeSUT(stack: stack)
        try await itemRepo.save(makeItem(stackID: stack.id, quantity: 4))
        try await itemRepo.save(makeItem(stackID: stack.id, quantity: 3))

        await sut.refresh()

        #expect(sut.items.count == 2)
        #expect(sut.cardCount == 7)
        #expect(sut.uniqueCount == 2)
        #expect(sut.status == .idle)
    }

    @Test("heroSubtitle prefers commander over format for decks")
    func heroSubtitleDeckPrefersCommander() throws {
        var stack = makeDeck()
        stack.commander = "Atraxa, Praetors' Voice"
        let (sut, _, _) = try makeSUT(stack: stack)
        #expect(sut.heroSubtitle == "Atraxa, Praetors' Voice")
    }

    @Test("heroSubtitle falls back to format for decks without commander")
    func heroSubtitleDeckFallsBackToFormat() throws {
        let stack = makeDeck(format: .modern)
        let (sut, _, _) = try makeSUT(stack: stack)
        #expect(sut.heroSubtitle == "Modern")
    }

    @Test("heroSubtitle shows 'On loan to <person>' for loan stacks")
    func heroSubtitleLoanPersonalized() throws {
        let stack = Stack(
            id: UUID(),
            name: "Cube night",
            kind: .loan,
            person: "Diego"
        )
        let (sut, _, _) = try makeSUT(stack: stack)
        #expect(sut.heroSubtitle == "On loan to Diego")
    }

    @Test("actions list reflects kind: deck = 4, loan = 3, sale = 4, inbox = 2")
    func kindAwareActionsList() throws {
        let deck   = Stack(id: UUID(), name: "D", kind: .deck)
        let loan   = Stack(id: UUID(), name: "L", kind: .loan)
        let sale   = Stack(id: UUID(), name: "S", kind: .sale)
        let inbox  = Stack(id: UUID(), name: "I", kind: .inbox)
        let (deckVM,  _, _) = try makeSUT(stack: deck)
        let (loanVM,  _, _) = try makeSUT(stack: loan)
        let (saleVM,  _, _) = try makeSUT(stack: sale)
        let (inboxVM, _, _) = try makeSUT(stack: inbox)

        #expect(deckVM.actions.count == 4)
        #expect(deckVM.actions.first?.id == "edit_list")
        #expect(loanVM.actions.count == 3)
        #expect(loanVM.actions.first?.id == "mark_returned")
        #expect(saleVM.actions.count == 4)
        #expect(saleVM.actions.first?.id == "mark_sold")
        #expect(inboxVM.actions.count == 2)
        #expect(inboxVM.actions.first?.id == "sort_all")
    }

    @Test("currency mirrors session")
    func currencyMirrorsSession() throws {
        let stack = makeDeck()
        let (sut, _, session) = try makeSUT(stack: stack)
        session.currency = .ars
        #expect(sut.currency == .ars)
    }

    @Test("formattedTotalValue stub renders in session currency")
    func formattedTotalValueRespectsCurrency() throws {
        let stack = makeDeck()
        let (sut, _, session) = try makeSUT(stack: stack)
        session.currency = .usd
        // No real value join in v0.3 — should render zero in the
        // active currency without crashing.
        let formatted = sut.formattedTotalValue
        #expect(!formatted.isEmpty)
    }

    @Test("deleteStack wipes the stack + every CollectionItem it owned and flips didDelete")
    func deleteStackCascadesAndFlipsDidDelete() async throws {
        let stack = makeDeck()
        let (sut, stackRepo, itemRepo) = try makeSUTWithStackRepo(stack: stack)
        try await stackRepo.save(stack)
        try await itemRepo.save(makeItem(stackID: stack.id, quantity: 4))
        try await itemRepo.save(makeItem(stackID: stack.id, quantity: 1))

        await sut.deleteStack()

        #expect(sut.didDelete)
        #expect(try await stackRepo.totalCount() == 0)
        #expect(try await itemRepo.items(in: stack.id).isEmpty)
    }

    @Test("deleteStack no-ops when no StackRepository is wired in")
    func deleteStackNoOpsWithoutStackRepo() async throws {
        let stack = makeDeck()
        let (sut, _, _) = try makeSUT(stack: stack)

        await sut.deleteStack()

        #expect(sut.didDelete == false)
    }
}

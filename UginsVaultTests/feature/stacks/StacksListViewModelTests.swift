//
//  StacksListViewModelTests.swift
//  UginsVaultTests
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("StacksListViewModel")
@MainActor
struct StacksListViewModelTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: SwiftDataStack.self, SwiftDataCollectionItem.self,
            configurations: config
        )
    }

    private func makeSUT() throws -> (
        StacksListViewModel,
        SwiftDataStackRepository,
        SwiftDataCollectionItemRepository,
        SessionStateStore
    ) {
        let container = try makeContainer()
        let stackRepo = SwiftDataStackRepository(modelContainer: container)
        let itemRepo  = SwiftDataCollectionItemRepository(modelContainer: container)
        let session   = SessionStateStore(storage: MockSessionStorage())
        let sut = StacksListViewModel(
            stackRepository: stackRepo,
            itemRepository: itemRepo,
            sessionRepository: session
        )
        return (sut, stackRepo, itemRepo, session)
    }

    private func makeStack(
        name: String,
        kind: StackKind,
        sortOrder: Int = 0,
        format: Format? = nil
    ) -> Stack {
        Stack(
            id: UUID(),
            name: name,
            kind: kind,
            sortOrder: sortOrder,
            format: format
        )
    }

    private func makeItem(stackID: UUID, quantity: Int) -> CollectionItem {
        CollectionItem(
            cardID: UUID(),
            stackID: stackID,
            quantity: quantity
        )
    }

    // MARK: - Tests

    @Test("Defaults: empty stacks, idle status, filter == all")
    func defaultsAreEmpty() throws {
        let (sut, _, _, _) = try makeSUT()
        #expect(sut.allStacks.isEmpty)
        #expect(sut.visibleStacks.isEmpty)
        #expect(sut.totalStackCount == 0)
        #expect(sut.totalCardCount == 0)
        #expect(sut.filter == .all)
        #expect(sut.isEmpty)
        #expect(sut.hasActiveFilter == false)
        #expect(sut.status == .idle)
    }

    @Test("refresh loads stacks + hydrates per-stack card counts")
    func refreshLoadsAndHydratesCounts() async throws {
        let (sut, stackRepo, itemRepo, _) = try makeSUT()
        let deck   = makeStack(name: "Burn",   kind: .deck,   sortOrder: 0, format: .modern)
        let binder = makeStack(name: "Trades", kind: .binder, sortOrder: 1)
        try await stackRepo.save(deck)
        try await stackRepo.save(binder)
        try await itemRepo.save(makeItem(stackID: deck.id,   quantity: 4))
        try await itemRepo.save(makeItem(stackID: deck.id,   quantity: 3))
        try await itemRepo.save(makeItem(stackID: binder.id, quantity: 1))

        await sut.refresh()

        #expect(sut.allStacks.count == 2)
        #expect(sut.totalStackCount == 2)
        #expect(sut.totalCardCount == 8)
        #expect(sut.cardCount(for: deck) == 7)
        #expect(sut.cardCount(for: binder) == 1)
        #expect(sut.status == .idle)
    }

    @Test("filter by kind narrows visibleStacks but keeps summary across all")
    func filterByKindKeepsSummaryAggregate() async throws {
        let (sut, stackRepo, itemRepo, _) = try makeSUT()
        let deck   = makeStack(name: "Burn",   kind: .deck,   sortOrder: 0, format: .modern)
        let binder = makeStack(name: "Trades", kind: .binder, sortOrder: 1)
        let loan   = makeStack(name: "Loaned", kind: .loan,   sortOrder: 2)
        try await stackRepo.save(deck)
        try await stackRepo.save(binder)
        try await stackRepo.save(loan)
        try await itemRepo.save(makeItem(stackID: deck.id,   quantity: 5))
        try await itemRepo.save(makeItem(stackID: binder.id, quantity: 2))
        try await itemRepo.save(makeItem(stackID: loan.id,   quantity: 1))
        await sut.refresh()

        sut.applyFilter(.kind(.deck))

        #expect(sut.visibleStacks.count == 1)
        #expect(sut.visibleStacks.first?.id == deck.id)
        // Summary line stays across every stack regardless of filter.
        #expect(sut.totalStackCount == 3)
        #expect(sut.totalCardCount == 8)
        #expect(sut.hasActiveFilter == true)
    }

    @Test("applyFilter(.all) restores the full slice")
    func applyFilterAllRestoresFull() async throws {
        let (sut, stackRepo, _, _) = try makeSUT()
        try await stackRepo.save(makeStack(name: "A", kind: .deck))
        try await stackRepo.save(makeStack(name: "B", kind: .binder))
        await sut.refresh()
        sut.applyFilter(.kind(.deck))
        #expect(sut.visibleStacks.count == 1)

        sut.applyFilter(.all)

        #expect(sut.visibleStacks.count == 2)
        #expect(sut.hasActiveFilter == false)
    }

    @Test("currency mirrors the session repository")
    func currencyMirrorsSession() throws {
        let (sut, _, _, session) = try makeSUT()
        session.saveCurrency(.eur)
        #expect(sut.currency == .eur)
    }

    @Test("availableFilters lists All + every StackKind in canonical order")
    func availableFiltersListsAllAndKinds() throws {
        let (sut, _, _, _) = try makeSUT()
        let ids = sut.availableFilters.map(\.id)
        #expect(ids == ["all", "deck", "binder", "loan", "sale", "showcase", "inbox"])
    }

    @Test("cardCount returns 0 for stacks with no items")
    func cardCountZeroForEmptyStack() async throws {
        let (sut, stackRepo, _, _) = try makeSUT()
        let empty = makeStack(name: "Empty", kind: .binder)
        try await stackRepo.save(empty)
        await sut.refresh()

        #expect(sut.cardCount(for: empty) == 0)
    }

    @Test("formattedTotalValue uses session currency")
    func formattedTotalValueUsesSessionCurrency() async throws {
        let (sut, _, _, session) = try makeSUT()
        session.saveCurrency(.usd)
        await sut.refresh()
        let usdFormatted = sut.formattedTotalValue
        #expect(usdFormatted.contains("0"))
    }

    @Test("createStack persists a deck with format+colours and refreshes the list")
    func createStackDeckPersists() async throws {
        let (sut, stackRepo, _, _) = try makeSUT()
        await sut.createStack(
            name: "Burn",
            kind: .deck,
            format: .modern,
            colors: [.red],
            commander: nil,
            person: nil
        )

        let stored = try await stackRepo.refresh()
        #expect(stored.count == 1)
        #expect(stored.first?.name == "Burn")
        #expect(stored.first?.kind == .deck)
        #expect(stored.first?.format == .modern)
        #expect(stored.first?.colors == [.red])
        #expect(sut.allStacks.count == 1)
        #expect(sut.isPresentingCreate == false)
    }

    @Test("createStack rejects an empty name")
    func createStackRejectsEmptyName() async throws {
        let (sut, stackRepo, _, _) = try makeSUT()
        await sut.createStack(name: "   ", kind: .deck)
        let stored = try await stackRepo.refresh()
        #expect(stored.isEmpty)
        #expect(sut.allStacks.isEmpty)
    }

    @Test("createStack assigns the next sortOrder after existing rows")
    func createStackBumpsSortOrder() async throws {
        let (sut, stackRepo, _, _) = try makeSUT()
        try await stackRepo.save(makeStack(name: "A", kind: .deck, sortOrder: 3))
        await sut.refresh()

        await sut.createStack(name: "B", kind: .binder)

        let stored = try await stackRepo.refresh()
        let new = stored.first { $0.name == "B" }
        #expect(new?.sortOrder == 4)
    }

    @Test("createStack clears deck-only fields when kind != .deck")
    func createStackDropsDeckFieldsForOtherKinds() async throws {
        let (sut, stackRepo, _, _) = try makeSUT()

        await sut.createStack(
            name: "Trades",
            kind: .binder,
            format: .modern,
            colors: [.red, .blue],
            commander: "Should be dropped"
        )

        let stored = try await stackRepo.refresh().first { $0.name == "Trades" }
        #expect(stored?.format == nil)
        #expect(stored?.colors.isEmpty == true)
        #expect(stored?.commander == nil)
    }

    @Test("deleteStack removes the stack + cascades the CollectionItem rows")
    func deleteStackCascades() async throws {
        let (sut, stackRepo, itemRepo, _) = try makeSUT()
        let stack = makeStack(name: "Burn", kind: .deck)
        try await stackRepo.save(stack)
        try await itemRepo.save(makeItem(stackID: stack.id, quantity: 4))
        try await itemRepo.save(makeItem(stackID: stack.id, quantity: 2))
        await sut.refresh()
        #expect(sut.allStacks.count == 1)

        await sut.deleteStack(id: stack.id)

        #expect(sut.allStacks.isEmpty)
        #expect(try await stackRepo.totalCount() == 0)
        #expect(try await itemRepo.items(in: stack.id).isEmpty)
    }

    @Test("Filter chipLabel returns the right plural per kind")
    func filterChipLabels() {
        #expect(StacksListViewModel.Filter.all.chipLabel == "All")
        #expect(StacksListViewModel.Filter.kind(.deck).chipLabel == "Decks")
        #expect(StacksListViewModel.Filter.kind(.binder).chipLabel == "Binders")
        #expect(StacksListViewModel.Filter.kind(.loan).chipLabel == "Loans")
        #expect(StacksListViewModel.Filter.kind(.sale).chipLabel == "Sales")
        #expect(StacksListViewModel.Filter.kind(.showcase).chipLabel == "Showcase")
        #expect(StacksListViewModel.Filter.kind(.inbox).chipLabel == "Unsorted")
    }
}

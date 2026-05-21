//
//  RestoreCollectionUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("RestoreCollectionUseCase")
@MainActor
struct RestoreCollectionUseCaseTests {

    // MARK: - Fixtures

    static let fixtureID = UUID(uuidString: "E25CE640-BAF5-442B-8B75-D05DD9FB20DD")!
    static let fixtureJSON = """
    {
      "object": "card",
      "id": "e25ce640-baf5-442b-8b75-d05dd9fb20dd",
      "oracle_id": "4457ed35-7c10-48c8-9776-456485fdf070",
      "name": "Lightning Bolt",
      "lang": "en",
      "mana_cost": "{R}",
      "cmc": 1.0,
      "type_line": "Instant",
      "oracle_text": "Lightning Bolt deals 3 damage to any target.",
      "colors": ["R"],
      "color_identity": ["R"],
      "set": "lea",
      "set_name": "Limited Edition Alpha",
      "collector_number": "161",
      "rarity": "common",
      "released_at": "1993-08-05",
      "finishes": ["nonfoil"],
      "image_uris": {
        "small": "https://cards.scryfall.io/small/lb.jpg",
        "normal": "https://cards.scryfall.io/normal/lb.jpg"
      },
      "prices": { "usd": "20.00", "usd_foil": null, "eur": "18.00" }
    }
    """

    private func decodeFixtureCard() throws -> ScryfallCard {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ScryfallCard.self, from: Data(Self.fixtureJSON.utf8))
    }

    // MARK: - Repos

    private func makeRepos() throws -> (SwiftDataCardRepository, SwiftDataStackRepository, SwiftDataCollectionItemRepository) {
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

    private func makeCard(id: UUID) -> Card {
        Card(id: id, oracleID: UUID(), name: "Cached", typeLine: "Instant",
             setCode: "lea", setName: "Alpha", collectorNumber: "1")
    }

    // MARK: - Tests

    @Test("mirrors server stacks + items into the local cache")
    func mirrors() async throws {
        let (cardRepo, stackRepo, itemRepo) = try makeRepos()
        let stack = Stack(name: "Deck", kind: .deck)
        let cardID = UUID()
        let item = CollectionItem(cardID: cardID, stackID: stack.id)
        try await cardRepo.save([makeCard(id: cardID)])   // already cached → no hydration

        let store = MockRemoteCollectionStore()
        store.fetchResult = RemoteCollection(stacks: [stack], items: [item])
        let client = MockScryfallClient()
        let sut = RestoreCollectionUseCase(remote: store, stackRepository: stackRepo,
                                           itemRepository: itemRepo, cardRepository: cardRepo,
                                           scryfallClient: client)

        let result = try await sut.execute()

        #expect(result.stacks.count == 1)
        #expect(try await stackRepo.refresh().count == 1)
        #expect(try await itemRepo.allItems().count == 1)
        #expect(await client.requestedIDs.isEmpty)   // card was cached
    }

    @Test("replaces pre-existing local data with the server's")
    func replaces() async throws {
        let (cardRepo, stackRepo, itemRepo) = try makeRepos()
        try await stackRepo.save(Stack(name: "Old", kind: .inbox))
        try await itemRepo.save(CollectionItem(cardID: UUID(), stackID: UUID()))

        let newStack = Stack(name: "New", kind: .binder)
        let newCardID = UUID()
        try await cardRepo.save([makeCard(id: newCardID)])
        let newItem = CollectionItem(cardID: newCardID, stackID: newStack.id)

        let store = MockRemoteCollectionStore()
        store.fetchResult = RemoteCollection(stacks: [newStack], items: [newItem])
        let sut = RestoreCollectionUseCase(remote: store, stackRepository: stackRepo,
                                           itemRepository: itemRepo, cardRepository: cardRepo,
                                           scryfallClient: MockScryfallClient())

        try await sut.execute()

        let stacks = try await stackRepo.refresh()
        let items = try await itemRepo.allItems()
        #expect(stacks.map(\.id) == [newStack.id])
        #expect(items.map(\.id) == [newItem.id])
    }

    @Test("hydrates a missing card from Scryfall by id")
    func hydratesMissingCard() async throws {
        let (cardRepo, stackRepo, itemRepo) = try makeRepos()
        let item = CollectionItem(cardID: Self.fixtureID, stackID: UUID())
        let store = MockRemoteCollectionStore()
        store.fetchResult = RemoteCollection(stacks: [], items: [item])
        let client = MockScryfallClient(collectionCards: [try decodeFixtureCard()])
        let sut = RestoreCollectionUseCase(remote: store, stackRepository: stackRepo,
                                           itemRepository: itemRepo, cardRepository: cardRepo,
                                           scryfallClient: client)

        try await sut.execute()

        #expect(try await cardRepo.card(id: Self.fixtureID) != nil)
    }

    @Test("offline hydration is best-effort — items still restored")
    func offlineHydration() async throws {
        let (cardRepo, stackRepo, itemRepo) = try makeRepos()
        let item = CollectionItem(cardID: UUID(), stackID: UUID())
        let store = MockRemoteCollectionStore()
        store.fetchResult = RemoteCollection(stacks: [], items: [item])
        let sut = RestoreCollectionUseCase(remote: store, stackRepository: stackRepo,
                                           itemRepository: itemRepo, cardRepository: cardRepo,
                                           scryfallClient: MockScryfallClient(shouldThrow: true))

        try await sut.execute()

        #expect(try await itemRepo.allItems().count == 1)
        #expect(try await cardRepo.card(id: item.cardID) == nil)
    }

    @Test("fetch error propagates")
    func fetchErrorPropagates() async throws {
        struct Boom: Error {}
        let (cardRepo, stackRepo, itemRepo) = try makeRepos()
        let store = MockRemoteCollectionStore()
        store.fetchError = Boom()
        let sut = RestoreCollectionUseCase(remote: store, stackRepository: stackRepo,
                                           itemRepository: itemRepo, cardRepository: cardRepo,
                                           scryfallClient: MockScryfallClient())

        await #expect(throws: Boom.self) {
            try await sut.execute()
        }
    }
}

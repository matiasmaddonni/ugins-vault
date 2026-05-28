//
//  ImportDeckListUseCaseTests.swift
//  UginsVaultTests — Domain
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("ImportDeckListUseCase")
@MainActor
struct ImportDeckListUseCaseTests {

    private func makeSUT() throws -> (ImportDeckListUseCase, SwiftDataCardRepository, SwiftDataCollectionItemRepository) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataCard.self, SwiftDataCollectionItem.self,
            configurations: config
        )
        let cardRepo = SwiftDataCardRepository(modelContainer: container)
        let itemRepo = SwiftDataCollectionItemRepository(modelContainer: container)
        let sut = ImportDeckListUseCase(
            cardRepository: cardRepo,
            scryfallClient: MockScryfallClient(),   // no network hits in these tests
            itemRepository: itemRepo
        )
        return (sut, cardRepo, itemRepo)
    }

    /// Local lookup rejects cards with no image, so fixtures need one.
    private func cardWithImage(_ name: String, id: UUID = UUID()) -> Card {
        Card(
            id: id, oracleID: UUID(), name: name, typeLine: "Instant",
            setCode: "lea", setName: "Alpha", collectorNumber: "1",
            images: CardImages(normal: URL(string: "https://cards.scryfall.io/normal/\(id.uuidString).jpg"))
        )
    }

    @Test("imports local hits into the stack with summed quantities")
    func importsLocalHits() async throws {
        let (sut, cardRepo, itemRepo) = try makeSUT()
        try await cardRepo.save([cardWithImage("Lightning Bolt"), cardWithImage("Counterspell")])
        let stackID = UUID()

        let result = try await sut.execute(source: "4 Lightning Bolt\n2 Counterspell", stackID: stackID)

        #expect(result.importedLines == 2)
        #expect(result.importedCards == 6)
        #expect(result.unresolved.isEmpty)

        let items = try await itemRepo.items(in: stackID)
        #expect(items.count == 2)
        #expect(items.reduce(0) { $0 + $1.quantity } == 6)
    }

    @Test("re-import SETS the quantity to the list (not additive)")
    func reimportSetsQuantity() async throws {
        let (sut, cardRepo, itemRepo) = try makeSUT()
        let boltID = UUID()
        try await cardRepo.save([cardWithImage("Lightning Bolt", id: boltID)])
        let stackID = UUID()
        try await itemRepo.save(CollectionItem(
            cardID: boltID, stackID: stackID, quantity: 1,
            finish: .nonfoil, condition: .nearMint, language: "en"
        ))

        _ = try await sut.execute(source: "3 Lightning Bolt", stackID: stackID)

        let items = try await itemRepo.items(in: stackID)
        #expect(items.count == 1)
        #expect(items.first?.quantity == 3)   // set to 3, not 1 + 3
    }

    @Test("import removes cards the list no longer contains")
    func importRemovesAbsent() async throws {
        let (sut, cardRepo, itemRepo) = try makeSUT()
        let boltID = UUID()
        let counterID = UUID()
        try await cardRepo.save([
            cardWithImage("Lightning Bolt", id: boltID),
            cardWithImage("Counterspell", id: counterID)
        ])
        let stackID = UUID()
        try await itemRepo.save(CollectionItem(cardID: boltID, stackID: stackID, quantity: 1))
        try await itemRepo.save(CollectionItem(cardID: counterID, stackID: stackID, quantity: 1))

        _ = try await sut.execute(source: "1 Lightning Bolt", stackID: stackID)

        let items = try await itemRepo.items(in: stackID)
        #expect(items.count == 1)
        #expect(items.first?.cardID == boltID)
    }

    @Test("empty source yields an empty result")
    func emptySource() async throws {
        let (sut, _, itemRepo) = try makeSUT()
        let stackID = UUID()

        let result = try await sut.execute(source: "   \n  ", stackID: stackID)

        #expect(result.importedLines == 0)
        #expect(try await itemRepo.items(in: stackID).isEmpty)
    }

    @Test("a card that resolves nowhere lands in unresolved")
    func unresolvedCard() async throws {
        let (sut, _, itemRepo) = try makeSUT()   // mock returns no batch matches + throws on named
        let stackID = UUID()

        let result = try await sut.execute(source: "1 Totally Made Up Card", stackID: stackID)

        #expect(result.importedLines == 0)
        #expect(result.unresolved == ["Totally Made Up Card"])
        #expect(try await itemRepo.items(in: stackID).isEmpty)
    }

    @Test("progress ends at total/total")
    func progressCompletes() async throws {
        let (sut, cardRepo, _) = try makeSUT()
        try await cardRepo.save([cardWithImage("Lightning Bolt")])
        let box = ProgressBox()

        _ = try await sut.execute(source: "1 Lightning Bolt", stackID: UUID()) { current, total in
            box.value = (current, total)
        }

        #expect(box.value == (1, 1))
    }
}

/// Sendable box for capturing the last progress tuple from a `@Sendable`
/// callback — the test mutates it serially, so unchecked Sendable is fine.
private final class ProgressBox: @unchecked Sendable {
    var value: (Int, Int) = (-1, -1)
}

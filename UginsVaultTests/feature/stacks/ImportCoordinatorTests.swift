//
//  ImportCoordinatorTests.swift
//  UginsVaultTests — Presentation: Stacks
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("ImportCoordinator")
@MainActor
struct ImportCoordinatorTests {

    private func makeRepos() throws -> (SwiftDataCardRepository, SwiftDataCollectionItemRepository) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SwiftDataCard.self, SwiftDataCollectionItem.self,
            configurations: config
        )
        return (
            SwiftDataCardRepository(modelContainer: container),
            SwiftDataCollectionItemRepository(modelContainer: container)
        )
    }

    private func cardWithImage(_ name: String, id: UUID = UUID()) -> Card {
        Card(
            id: id, oracleID: UUID(), name: name, typeLine: "Instant",
            setCode: "lea", setName: "Alpha", collectorNumber: "1",
            images: CardImages(normal: URL(string: "https://cards.scryfall.io/n/\(id.uuidString).jpg"))
        )
    }

    private func waitUntil(_ condition: () -> Bool, timeout: Duration = .seconds(3)) async throws {
        let start = ContinuousClock().now
        while !condition() {
            if ContinuousClock().now - start > timeout {
                Issue.record("Timed out waiting for condition")
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    @Test("empty import finishes with a zero result")
    func emptyImportFinishes() async throws {
        let (cardRepo, itemRepo) = try makeRepos()
        let coordinator = ImportCoordinator(makeUseCase: {
            ImportDeckListUseCase(cardRepository: cardRepo, scryfallClient: MockScryfallClient(), itemRepository: itemRepo)
        })

        coordinator.start(source: "", stackID: UUID(), stackName: "Deck")
        try await waitUntil { coordinator.phase == .finished }

        #expect(coordinator.result?.importedLines == 0)
    }

    @Test("a local-hit import finishes with the counts + populates the stack")
    func localHitImportFinishes() async throws {
        let (cardRepo, itemRepo) = try makeRepos()
        try await cardRepo.save([cardWithImage("Lightning Bolt")])
        let stackID = UUID()
        let coordinator = ImportCoordinator(makeUseCase: {
            ImportDeckListUseCase(cardRepository: cardRepo, scryfallClient: MockScryfallClient(), itemRepository: itemRepo)
        })

        coordinator.start(source: "2 Lightning Bolt", stackID: stackID, stackName: "Deck")
        try await waitUntil { coordinator.phase == .finished }

        #expect(coordinator.result?.importedLines == 1)
        #expect(coordinator.result?.importedCards == 2)
        #expect(coordinator.fractionComplete == 1.0)
        #expect(try await itemRepo.items(in: stackID).count == 1)
    }

    @Test("fractionComplete is zero before any progress")
    func fractionZero() throws {
        let (cardRepo, itemRepo) = try makeRepos()
        let coordinator = ImportCoordinator(makeUseCase: {
            ImportDeckListUseCase(cardRepository: cardRepo, scryfallClient: MockScryfallClient(), itemRepository: itemRepo)
        })
        #expect(coordinator.fractionComplete == 0)
    }

    @Test("dismiss clears a finished banner")
    func dismissClears() async throws {
        let (cardRepo, itemRepo) = try makeRepos()
        let coordinator = ImportCoordinator(makeUseCase: {
            ImportDeckListUseCase(cardRepository: cardRepo, scryfallClient: MockScryfallClient(), itemRepository: itemRepo)
        })

        coordinator.start(source: "", stackID: UUID(), stackName: "Deck")
        try await waitUntil { coordinator.phase == .finished }

        coordinator.dismiss()
        #expect(coordinator.phase == .idle)
        #expect(coordinator.result == nil)
    }

    @Test("start sets importing immediately; cancel resets to idle")
    func cancelResets() async throws {
        let (cardRepo, itemRepo) = try makeRepos()
        let coordinator = ImportCoordinator(makeUseCase: {
            ImportDeckListUseCase(cardRepository: cardRepo, scryfallClient: MockScryfallClient(), itemRepository: itemRepo)
        })

        coordinator.start(source: "1 Lightning Bolt", stackID: UUID(), stackName: "Deck")
        #expect(coordinator.phase == .importing)

        coordinator.cancel()
        #expect(coordinator.phase == .idle)
    }

    @Test("a second start is ignored while one is running")
    func serializesImports() async throws {
        let (cardRepo, itemRepo) = try makeRepos()
        let coordinator = ImportCoordinator(makeUseCase: {
            ImportDeckListUseCase(cardRepository: cardRepo, scryfallClient: MockScryfallClient(), itemRepository: itemRepo)
        })

        coordinator.start(source: "1 A", stackID: UUID(), stackName: "First")
        coordinator.start(source: "1 B", stackID: UUID(), stackName: "Second")   // ignored

        #expect(coordinator.stackName == "First")
        try await waitUntil { coordinator.phase == .finished }
    }
}

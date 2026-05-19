//
//  ImportDeckListUseCase.swift
//  UginsVault — Domain layer
//
//  Takes a parsed Moxfield/Arena/MTGO deck list and materialises every
//  line into the user's catalogue + the target Stack. Resolution order
//  per line:
//
//   1. Local lookup by (name, setCode) — uses the existing
//      `CardRepository.refresh(_:)` text query.
//   2. Scryfall `/cards/named?exact=<name>[&set=<set>]` fallback.
//   3. Persist the resolved `Card` so the next import is a local hit.
//   4. Create / increment the `CollectionItem` via
//      `AddCardToStackUseCase`.
//
//  Returns a structured `ImportResult` the UI uses for the post-import
//  toast ("Imported N · skipped M").
//

import Foundation

@MainActor
public final class ImportDeckListUseCase {

    public struct ImportResult: Sendable, Equatable {
        public var importedLines: Int      // lines successfully added
        public var importedCards: Int      // total quantity inserted
        public var unresolved: [String]    // names we couldn't resolve

        public init(importedLines: Int = 0, importedCards: Int = 0, unresolved: [String] = []) {
            self.importedLines = importedLines
            self.importedCards = importedCards
            self.unresolved = unresolved
        }
    }

    // MARK: - Dependencies

    private let cardRepository: CardRepository
    private let scryfallClient: any ScryfallClientProtocol
    private let addCardToStack: AddCardToStackUseCase

    public init(
        cardRepository: CardRepository,
        scryfallClient: any ScryfallClientProtocol,
        addCardToStack: AddCardToStackUseCase
    ) {
        self.cardRepository = cardRepository
        self.scryfallClient = scryfallClient
        self.addCardToStack = addCardToStack
    }

    // MARK: - Execute

    /// Imports `source` text into `stackID`. Progress callback fires
    /// after every line — useful for a "(3 / 60)" sheet spinner.
    public func execute(
        source: String,
        stackID: UUID,
        progress: ((Int, Int) -> Void)? = nil
    ) async throws -> ImportResult {

        let lines = DeckListParser.parse(source)
        var result = ImportResult()

        for (index, line) in lines.enumerated() {
            progress?(index, lines.count)

            do {
                let card = try await resolve(line: line)
                try await cardRepository.save([card])
                try await addCardToStack.execute(
                    cardID: card.id,
                    stackID: stackID,
                    quantity: line.quantity,
                    finish: line.isFoil ? .foil : .nonfoil,
                    condition: .nearMint,
                    language: card.language
                )
                result.importedLines += 1
                result.importedCards += line.quantity
            } catch {
                result.unresolved.append(line.name)
            }
        }

        progress?(lines.count, lines.count)
        return result
    }

    // MARK: - Resolution

    private func resolve(line: ParsedDeckLine) async throws -> Card {
        if let local = try await localLookup(line: line) {
            return local
        }
        let scryfall = try await scryfallClient.card(
            named: line.name,
            set: line.setCode,
            fuzzy: false
        )
        guard let card = Card(from: scryfall) else {
            throw ImportDeckListError.scryfallMappingFailed(name: line.name)
        }
        return card
    }

    private func localLookup(line: ParsedDeckLine) async throws -> Card? {
        let query = CardQuery(text: line.name, offset: 0, limit: 25)
        let candidates = try await cardRepository.refresh(query)
        let lowerName = line.name.lowercased()
        let exactMatches = candidates.filter { $0.name.lowercased() == lowerName }

        if let setCode = line.setCode?.lowercased(),
           let bySet = exactMatches.first(where: { $0.setCode.lowercased() == setCode }) {
            return bySet
        }
        return exactMatches.first
    }
}

public enum ImportDeckListError: Error, Equatable {
    case scryfallMappingFailed(name: String)
}

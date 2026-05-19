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

        // Try strictest → loosest until something resolves. We honour the
        // requested set first, then drop it (Moxfield exports use promo
        // set codes Scryfall doesn't recognise as searchable sets, e.g.
        // PZNR / PELD / PCLB), and finally fall back to a fuzzy match
        // (handles small typos + double-faced corner cases).
        let normalizedName = normalizeName(line.name)

        if let set = line.setCode,
           let card = await tryFetch(name: normalizedName, set: set, fuzzy: false) {
            return card
        }
        if let card = await tryFetch(name: normalizedName, set: nil, fuzzy: false) {
            return card
        }
        if let card = await tryFetch(name: normalizedName, set: nil, fuzzy: true) {
            return card
        }

        throw ImportDeckListError.scryfallMappingFailed(name: line.name)
    }

    private func tryFetch(name: String, set: String?, fuzzy: Bool) async -> Card? {
        do {
            let dto = try await scryfallClient.card(named: name, set: set, fuzzy: fuzzy)
            return Card(from: dto)
        } catch {
            return nil
        }
    }

    /// Moxfield exports use a single ` / ` separator for split / DFC
    /// cards (e.g. "Agadeem's Awakening / Agadeem, the Undercrypt").
    /// Scryfall stores them with ` // ` — normalise so exact lookups
    /// don't 404.
    private func normalizeName(_ name: String) -> String {
        var out = name
        if out.contains(" / "), !out.contains(" // ") {
            out = out.replacingOccurrences(of: " / ", with: " // ")
        }
        return out
    }

    private func localLookup(line: ParsedDeckLine) async throws -> Card? {
        // Direct fetch — non-mutating, so we don't trample the
        // Collection tab's observable `cards` slice from inside the
        // import loop. Pin to set when the line specifies one so we
        // never substitute a wrong printing.
        let normalizedName = normalizeName(line.name)
        guard let local = try await cardRepository.findOne(
            name: normalizedName,
            setCode: line.setCode
        ) else { return nil }

        // Treat rows imported before the DFC-mapper fix (no image URLs
        // at all) as stale — force a Scryfall refresh so the new
        // `card_faces[0].image_uris` fallback can populate them.
        if !hasAnyImage(local) {
            return nil
        }
        return local
    }

    private func hasAnyImage(_ card: Card) -> Bool {
        let urls = [
            card.images.small,
            card.images.normal,
            card.images.large,
            card.images.png,
            card.images.artCrop,
            card.images.borderCrop
        ]
        return urls.contains(where: { $0 != nil })
    }
}

public enum ImportDeckListError: Error, Equatable {
    case scryfallMappingFailed(name: String)
}

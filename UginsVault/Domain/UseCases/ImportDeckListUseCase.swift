//
//  ImportDeckListUseCase.swift
//  UginsVault — Domain layer
//
//  Materialises a parsed Moxfield/Arena/MTGO deck list into the catalogue + a
//  target Stack. Resolution is BATCHED for speed:
//
//   1. Local-first — resolve each line from the catalogue (no network).
//   2. Bulk Scryfall — the misses go to `POST /cards/collection` in chunks of
//      75 (one round-trip per chunk instead of one per card).
//   3. Fuzzy fallback — only the still-unresolved lines fall back to the
//      per-card `/cards/named?fuzzy=` path (handles typos / promo set codes /
//      DFC corner cases).
//   4. Persist — every resolved `Card` is saved in ONE batch, and the
//      `CollectionItem` rows (merged with any existing rows in the stack) are
//      saved in ONE batch.
//
//  Returns a structured `ImportResult` for the post-import summary.
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
    private let itemRepository: CollectionItemRepository

    /// Scryfall caps `/cards/collection` at 75 identifiers per request.
    private let batchSize = 75

    public init(
        cardRepository: CardRepository,
        scryfallClient: any ScryfallClientProtocol,
        itemRepository: CollectionItemRepository
    ) {
        self.cardRepository = cardRepository
        self.scryfallClient = scryfallClient
        self.itemRepository = itemRepository
    }

    // MARK: - Execute

    /// Imports `source` text into `stackID`. `progress` reports
    /// (resolved, total) as lines resolve — useful for a floating progress UI.
    public func execute(
        source: String,
        stackID: UUID,
        progress: ((Int, Int) -> Void)? = nil
    ) async throws -> ImportResult {

        let lines = DeckListParser.parse(source)
        let total = lines.count
        guard total > 0 else { return ImportResult() }
        progress?(0, total)

        var resolved: [(line: ParsedDeckLine, card: Card)] = []
        var result = ImportResult()
        var done = 0

        // 1. Local-first.
        var misses: [ParsedDeckLine] = []
        for line in lines {
            if let local = try await localLookup(line: line) {
                resolved.append((line, local))
                done += 1
                progress?(done, total)
            } else {
                misses.append(line)
            }
        }

        // 2. Bulk-resolve the misses (chunks of 75).
        var stillMissing: [ParsedDeckLine] = []
        for chunk in misses.chunked(into: batchSize) {
            let identifiers = chunk.map {
                ScryfallCardIdentifier(name: normalizeName($0.name), set: $0.setCode)
            }
            let dtos = (try? await scryfallClient.collection(identifiers: identifiers)) ?? []

            var byName: [String: Card] = [:]
            for dto in dtos where Card(from: dto) != nil {
                let card = Card(from: dto)!
                byName[card.name.lowercased()] = card
            }

            for line in chunk {
                if let card = byName[normalizeName(line.name).lowercased()] {
                    resolved.append((line, card))
                    done += 1
                    progress?(done, total)
                } else {
                    stillMissing.append(line)
                }
            }
        }

        // 3. Per-card fuzzy fallback for the remainder.
        for line in stillMissing {
            if let card = await fuzzyResolve(line: line) {
                resolved.append((line, card))
            } else {
                result.unresolved.append(line.name)
            }
            done += 1
            progress?(done, total)
        }

        // 4. Persist resolved cards in one write.
        try await cardRepository.save(dedupedCards(resolved.map(\.card)))

        // 5. Reconcile the stack to MATCH the imported list (set quantities,
        // add new, remove absent) so re-importing an edited list applies the
        // delta instead of doubling. Removals are skipped when some lines
        // didn't resolve — a flaky import never silently drops cards.
        let (upserts, deleteIDs) = try await reconcile(
            resolved: resolved,
            stackID: stackID,
            allowRemovals: result.unresolved.isEmpty
        )
        try await itemRepository.save(upserts)
        for id in deleteIDs {
            try await itemRepository.delete(id: id)
        }

        for (line, _) in resolved {
            result.importedLines += 1
            result.importedCards += line.quantity
        }
        progress?(total, total)
        return result
    }

    // MARK: - Resolution

    private func fuzzyResolve(line: ParsedDeckLine) async -> Card? {
        let name = normalizeName(line.name)
        if let card = await tryFetch(name: name, fuzzy: false) { return card }
        if let card = await tryFetch(name: name, fuzzy: true) { return card }
        return nil
    }

    private func tryFetch(name: String, fuzzy: Bool) async -> Card? {
        do {
            let dto = try await scryfallClient.card(named: name, set: nil, fuzzy: fuzzy)
            return Card(from: dto)
        } catch {
            return nil
        }
    }

    private func localLookup(line: ParsedDeckLine) async throws -> Card? {
        let normalizedName = normalizeName(line.name)
        guard let local = try await cardRepository.findOne(
            name: normalizedName,
            setCode: line.setCode
        ) else { return nil }

        // Rows imported before the DFC-mapper fix have no image URLs — treat
        // them as stale so a Scryfall refresh repopulates them.
        return hasAnyImage(local) ? local : nil
    }

    /// Moxfield uses a single ` / ` separator for split / DFC cards; Scryfall
    /// stores ` // `. Normalise so exact lookups don't 404.
    private func normalizeName(_ name: String) -> String {
        var out = name
        if out.contains(" / "), !out.contains(" // ") {
            out = out.replacingOccurrences(of: " / ", with: " // ")
        }
        return out
    }

    private func hasAnyImage(_ card: Card) -> Bool {
        [card.images.small, card.images.normal, card.images.large,
         card.images.png, card.images.artCrop, card.images.borderCrop]
            .contains { $0 != nil }
    }

    // MARK: - Persistence helpers

    private func dedupedCards(_ cards: [Card]) -> [Card] {
        var seen = Set<UUID>()
        return cards.filter { seen.insert($0.id).inserted }
    }

    private struct ItemKey: Hashable {
        let cardID: UUID
        let finish: Finish
        let condition: CardCondition
        let language: String
    }

    /// Diffs the resolved list against the stack's current rows: SET each
    /// desired quantity (not add), insert new rows, and — when `allowRemovals`
    /// — remove rows the list no longer contains. Returns only changed rows.
    private func reconcile(
        resolved: [(line: ParsedDeckLine, card: Card)],
        stackID: UUID,
        allowRemovals: Bool
    ) async throws -> (upserts: [CollectionItem], deleteIDs: [UUID]) {

        func key(for item: CollectionItem) -> ItemKey {
            ItemKey(cardID: item.cardID, finish: item.finish, condition: item.condition, language: item.language)
        }

        var desired: [ItemKey: Int] = [:]
        for (line, card) in resolved {
            let key = ItemKey(cardID: card.id, finish: line.isFoil ? .foil : .nonfoil,
                              condition: .nearMint, language: card.language)
            desired[key, default: 0] += line.quantity
        }

        let existing = try await itemRepository.items(in: stackID)
        var existingByKey: [ItemKey: CollectionItem] = [:]
        for item in existing { existingByKey[key(for: item)] = item }

        var upserts: [CollectionItem] = []
        for (key, qty) in desired {
            if var item = existingByKey[key] {
                if item.quantity != qty {
                    item.quantity = qty
                    upserts.append(item)
                }
            } else {
                upserts.append(CollectionItem(
                    cardID: key.cardID, stackID: stackID, quantity: qty,
                    finish: key.finish, condition: .nearMint,
                    language: key.language, acquiredAt: Date()
                ))
            }
        }

        let deleteIDs = allowRemovals
            ? existing.filter { desired[key(for: $0)] == nil }.map(\.id)
            : []

        return (upserts, deleteIDs)
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

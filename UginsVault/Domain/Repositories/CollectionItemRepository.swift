//
//  CollectionItemRepository.swift
//  UginsVault — Domain layer
//
//  Tracks per-user ownership rows: how many copies of which Scryfall
//  printing live in which Stack, and with which finish/condition.
//  Card-level metadata (name, type, image, prices) is fetched separately
//  from `CardRepository`.
//

import Foundation

public protocol CollectionItemRepository: AnyObject, Sendable {

    // MARK: - Reads

    /// All items in a given stack, newest-first.
    func items(in stackID: UUID) async throws -> [CollectionItem]

    /// Sum of `quantity` for every item in a stack. Drives the
    /// "14 cards" subtitle on Stack rows + hero card.
    func cardCount(in stackID: UUID) async throws -> Int

    /// Number of unique items (`COUNT(*)`) in a stack. Drives the
    /// "9 unique" subtitle on the Stack detail hero.
    func uniqueCount(in stackID: UUID) async throws -> Int

    /// Looks up a single item by id.
    func item(id: UUID) async throws -> CollectionItem?

    /// Returns every item across every stack — used for cross-stack
    /// aggregates (Stacks tab summary line).
    func allItems() async throws -> [CollectionItem]

    // MARK: - Writes

    /// Inserts or updates by `CollectionItem.id`. Idempotent.
    func save(_ item: CollectionItem) async throws

    /// Inserts or updates a batch in a single write. Idempotent by id.
    /// Used by bulk paths (deck import) to avoid a save per row.
    func save(_ items: [CollectionItem]) async throws

    /// Removes a single item by id.
    func delete(id: UUID) async throws

    /// Removes every item in a given stack — used when the parent Stack
    /// is deleted.
    func deleteAll(in stackID: UUID) async throws

    /// Wipes the whole ownership table. Used by tests + Settings → Reset.
    func deleteAll() async throws
}

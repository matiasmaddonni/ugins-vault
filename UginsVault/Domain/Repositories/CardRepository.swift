//
//  CardRepository.swift
//  UginsVault — Domain layer
//
//  Read + write surface over the local card catalogue. The Domain layer
//  declares the contract — the Data layer ships the SwiftData-backed
//  implementation, and the Composition layer wires them together.
//

import Foundation
import Observation

@MainActor
public protocol CardRepository: AnyObject, Observable {

    // MARK: - Observable state

    /// Most recent slice of cards loaded into memory. Bumped by `refresh()`.
    /// Views observe this property to re-render.
    var cards: [Card] { get }

    /// `true` while a write batch is in flight. Surfaces in Settings /
    /// Splash for a "Seeding…" spinner.
    var isWriting: Bool { get }

    // MARK: - Reads

    /// Total number of rows in the catalogue.
    func totalCount() async throws -> Int

    /// Loads cards matching the query. Empty / whitespace query → recent.
    /// Implementations may cap the result count (default ~200 for v0.2).
    @discardableResult
    func refresh(query: String) async throws -> [Card]

    /// Looks up a single card by Scryfall printing id.
    func card(id: UUID) async throws -> Card?

    // MARK: - Writes

    /// Inserts or updates a batch of cards. Idempotent by `Card.id`.
    func save(_ cards: [Card]) async throws

    /// Wipes the catalogue. Used by Settings → Reset (future) and tests.
    func deleteAll() async throws
}

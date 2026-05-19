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

    /// Most recent slice of cards loaded into memory. Bumped by `refresh(_:)`.
    /// Views observe this property to re-render.
    var cards: [Card] { get }

    /// `true` while a write batch is in flight. Surfaces in Settings /
    /// Splash for a "Seeding…" spinner.
    var isWriting: Bool { get }

    // MARK: - Reads

    /// Total number of rows in the catalogue (unfiltered).
    func totalCount() async throws -> Int

    /// Total number of rows matching the supplied `query` (text + filter,
    /// ignoring offset/limit). Drives "n of N" labels + pagination stop.
    func count(matching query: CardQuery) async throws -> Int

    /// Loads cards matching the query, replaces the in-memory `cards`
    /// slice, and returns it. With a non-zero `offset`, callers are
    /// responsible for appending instead of replacing.
    @discardableResult
    func refresh(_ query: CardQuery) async throws -> [Card]

    /// Looks up a single card by Scryfall printing id.
    func card(id: UUID) async throws -> Card?

    /// Distinct lowercase set codes currently in the catalogue. Used by
    /// the filter sheet to populate its picker.
    func availableSetCodes() async throws -> [String]

    // MARK: - Writes

    /// Inserts or updates a batch of cards. Idempotent by `Card.id`.
    func save(_ cards: [Card]) async throws

    /// Wipes the catalogue. Used by Settings → Reset (future) and tests.
    func deleteAll() async throws
}

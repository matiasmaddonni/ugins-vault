//
//  ScryfallClientProtocol.swift
//  UginsVault — Data layer / Scryfall
//
//  Surface consumed by repositories + seeders. Concrete implementation
//  lives in `ScryfallClient` (actor with throttle); tests inject a mock
//  conforming to this protocol.
//

import Foundation

public protocol ScryfallClientProtocol: Actor {

    /// Returns the list of available bulk-data dumps. Pick the
    /// `oracle_cards` entry to seed the local catalogue on first launch.
    func bulkDataIndex() async throws -> [ScryfallBulkData]

    /// Returns a single card by its Scryfall UUID.
    func card(id: UUID) async throws -> ScryfallCard

    /// Returns a single card by name. `fuzzy` enables Scryfall's
    /// approximate-match endpoint (`/cards/named?fuzzy=`).
    func card(named: String, fuzzy: Bool) async throws -> ScryfallCard
}

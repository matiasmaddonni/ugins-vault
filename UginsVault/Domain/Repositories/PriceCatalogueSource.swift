//
//  PriceCatalogueSource.swift
//  UginsVault — Domain layer
//
//  Remote source the `SyncPricesUseCase` pulls from. The Data layer
//  ships a backend (API) implementation; tests inject a stub.
//

import Foundation

public protocol PriceCatalogueSource: AnyObject, Sendable {

    /// Streams a batch of snapshots for the given card-id allow-list.
    /// Implementations are free to filter on-the-fly to keep memory
    /// pressure low — the use case passes the catalogue's full set
    /// of owned printing ids so we don't bother decoding rows for
    /// cards the user doesn't have.
    ///
    /// - Parameter ownedCardIDs: scryfall printing ids to keep.
    ///   When empty, returns an empty array (no-op — we never want
    ///   the full ~60K card universe).
    /// - Returns: every snapshot the source has, across each
    ///   `PriceSource` × every date present in the payload.
    func fetchSnapshots(ownedCardIDs: Set<UUID>) async throws -> [PriceSnapshot]

    /// Pulls the FULL price history (every day available, optionally
    /// clamped to `windowStart`) for the owned allow-list. Backs the
    /// first-launch bootstrap so the Dashboard has real history at once.
    func fetchFullHistory(ownedCardIDs: Set<UUID>, windowStart: Date?) async throws -> [PriceSnapshot]
}

public extension PriceCatalogueSource {

    /// Default: fall back to the lighter today-only fetch. The MTGJSON
    /// implementation overrides this with the streamed full dump; test
    /// stubs inherit the cheap default.
    func fetchFullHistory(ownedCardIDs: Set<UUID>, windowStart: Date?) async throws -> [PriceSnapshot] {
        try await fetchSnapshots(ownedCardIDs: ownedCardIDs)
    }
}

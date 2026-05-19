//
//  PriceCatalogueSource.swift
//  UginsVault — Domain layer
//
//  Remote source the `SyncPricesUseCase` pulls from. The Data layer
//  ships an MTGJSON-backed implementation; tests inject a stub.
//

import Foundation

@MainActor
public protocol PriceCatalogueSource: AnyObject {

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
}

//
//  PriceRepository.swift
//  UginsVault — Domain layer
//
//  Local price history. Writes come from `SyncPricesUseCase`, reads
//  power Card Detail + Dashboard. v0.5 keeps the rolling window
//  fixed at 30 days — older rows are pruned on every sync.
//

import Foundation
import Observation

@MainActor
public protocol PriceRepository: AnyObject, Observable {

    // MARK: - Observable state

    /// Timestamp of the last completed sync. `nil` before the first
    /// run. Settings → Data renders it as "Last synced: …".
    var lastSyncedAt: Date? { get }

    /// `true` while a write batch is in flight. UI uses it to disable
    /// the manual refresh button.
    var isWriting: Bool { get }

    // MARK: - Reads

    /// Most recent snapshot for a (card, source) pair. `nil` when the
    /// source doesn't list the card yet.
    func latest(cardID: UUID, source: PriceSource) async throws -> PriceSnapshot?

    /// Every snapshot in the window for a (card, source) pair, oldest
    /// first. Used for sparkline + week-delta math.
    func history(
        cardID: UUID,
        source: PriceSource,
        since: Date
    ) async throws -> [PriceSnapshot]

    /// Latest snapshot per card for a source. Used by the Dashboard
    /// total-value aggregator when it prefers MTGJSON over Scryfall.
    func latestByCard(source: PriceSource) async throws -> [UUID: PriceSnapshot]

    // MARK: - Writes

    /// Upserts the batch by `(cardID, source, date)` and prunes rows older
    /// than `keepingSince`.
    func upsert(
        _ snapshots: [PriceSnapshot],
        keepingSince: Date
    ) async throws

    /// Marks the sync clock — called once per successful import batch.
    func markSyncCompleted(at date: Date) async throws

    /// Wipes every snapshot + clears the sync timestamp. Used by
    /// Settings → Data → Reset.
    func deleteAll() async throws

    /// Every snapshot for `source` on/after `since`, oldest first. One
    /// fetch for the whole window — powers the Dashboard sparkline +
    /// movers without an N-per-card round trip.
    func allSince(source: PriceSource, since: Date) async throws -> [PriceSnapshot]
}

public extension PriceRepository {

    /// Default no-history implementation so lightweight test doubles
    /// don't have to implement it. The SwiftData repo overrides with a
    /// real windowed fetch.
    func allSince(source: PriceSource, since: Date) async throws -> [PriceSnapshot] { [] }
}

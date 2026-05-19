//
//  SyncPricesUseCase.swift
//  UginsVault — Domain layer
//
//  Orchestrates a single end-to-end price refresh: intersect the
//  remote source with the user's owned cards, persist the resulting
//  `PriceSnapshot` batch through `PriceRepository`, prune anything
//  older than the rolling window, and stamp the sync timestamp.
//
//  Wi-Fi gating + background-task scheduling live a layer up — this
//  use case assumes the caller has already decided it's safe to fetch.
//

import Foundation

@MainActor
public final class SyncPricesUseCase {

    public struct Progress: Sendable, Equatable {
        public let phase: Phase
        public let importedCount: Int

        public enum Phase: Sendable, Equatable {
            case fetching          // network in flight
            case parsing           // decoding the JSON dump
            case persisting        // writing into SwiftData
            case pruning           // deleting stale rows
            case finished
        }
    }

    public enum SyncError: Error, Equatable, LocalizedError {
        case noOwnedCards
        case sourceFailed(message: String)

        public var errorDescription: String? {
            switch self {
            case .noOwnedCards:
                return "Your catalogue is empty — nothing to price."
            case .sourceFailed(let message):
                return message
            }
        }
    }

    // MARK: - Dependencies

    private let priceRepository: PriceRepository
    private let cardRepository: CardRepository
    private let priceSource: PriceCatalogueSource
    private let historyWindow: TimeInterval

    public init(
        priceRepository: PriceRepository,
        cardRepository: CardRepository,
        priceSource: PriceCatalogueSource,
        historyWindow: TimeInterval = 30 * 24 * 60 * 60
    ) {
        self.priceRepository = priceRepository
        self.cardRepository = cardRepository
        self.priceSource = priceSource
        self.historyWindow = historyWindow
    }

    // MARK: - Execute

    /// Runs one full sync. `progress` fires on every phase change so a
    /// loading screen can show "Downloading…" → "Parsing…" → "Saving…".
    /// Returns the total number of snapshots persisted.
    @discardableResult
    public func execute(
        progress: ((Progress) -> Void)? = nil
    ) async throws -> Int {

        // 1. Intersect with owned catalogue.
        let owned = try await ownedCardIDs()
        guard !owned.isEmpty else {
            throw SyncError.noOwnedCards
        }

        // 2. Fetch + parse.
        progress?(.init(phase: .fetching, importedCount: 0))
        let snapshots: [PriceSnapshot]
        do {
            progress?(.init(phase: .parsing, importedCount: 0))
            snapshots = try await priceSource.fetchSnapshots(ownedCardIDs: owned)
        } catch {
            throw SyncError.sourceFailed(message: error.localizedDescription)
        }

        // 3. Persist + prune.
        progress?(.init(phase: .persisting, importedCount: snapshots.count))
        let cutoff = Date().addingTimeInterval(-historyWindow)
        try await priceRepository.upsert(snapshots, keepingSince: cutoff)

        progress?(.init(phase: .pruning, importedCount: snapshots.count))
        try await priceRepository.markSyncCompleted(at: Date())

        progress?(.init(phase: .finished, importedCount: snapshots.count))
        return snapshots.count
    }

    // MARK: - Helpers

    private func ownedCardIDs() async throws -> Set<UUID> {
        // We don't yet expose a "give me every id" call on
        // `CardRepository` — for v0.5 use the existing
        // `refresh(_:)` page-walker. 1K-card collections fit in a
        // single page; >1K → grow this into a streaming `ids()`
        // method on the repo.
        let query = CardQuery(text: "", offset: 0, limit: 10_000)
        let cards = try await cardRepository.refresh(query)
        return Set(cards.map(\.id))
    }
}

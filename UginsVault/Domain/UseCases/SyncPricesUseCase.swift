//
//  SyncPricesUseCase.swift
//  UginsVault — Domain layer
//
//  One end-to-end price refresh against the backend (the single source of
//  truth):
//    1. push the owned list so the backend ingest covers those cards.
//    2. fetch backend prices for the owned set.
//    3. persist + prune the rolling window + stamp the sync clock.
//
//  Cards the backend hasn't ingested yet simply have no price until its
//  ingest runs. Wi-Fi gating + scheduling live a layer up.
//

import Foundation

@MainActor
public final class SyncPricesUseCase {

    public struct Progress: Sendable, Equatable {
        public let phase: Phase
        public let importedCount: Int

        public enum Phase: Sendable, Equatable {
            case fetching
            case parsing
            case persisting
            case pruning
            case finished
        }
    }

    public enum SyncError: Error, Equatable, LocalizedError {
        case noOwnedCards
        case unauthorized
        case sourceFailed(message: String)

        public var errorDescription: String? {
            switch self {
            case .noOwnedCards:
                return "Your catalogue is empty — nothing to price."
            case .unauthorized:
                return "Your session expired — sign in again."
            case .sourceFailed(let message):
                return message
            }
        }
    }

    // MARK: - Dependencies

    private let priceRepository: PriceRepository
    private let collectionItemRepository: CollectionItemRepository
    private let backendSource: PriceCatalogueSource
    private let pushOwned: PushOwnedUseCase
    private let historyWindow: TimeInterval

    public init(
        priceRepository: PriceRepository,
        collectionItemRepository: CollectionItemRepository,
        backendSource: PriceCatalogueSource,
        pushOwned: PushOwnedUseCase,
        historyWindow: TimeInterval = 35 * 24 * 60 * 60
    ) {
        self.priceRepository = priceRepository
        self.collectionItemRepository = collectionItemRepository
        self.backendSource = backendSource
        self.pushOwned = pushOwned
        self.historyWindow = historyWindow
    }

    // MARK: - Execute

    /// Light refresh — current window from the backend.
    @discardableResult
    public func execute(progress: ((Progress) -> Void)? = nil) async throws -> Int {
        try await run(fullHistory: false, progress: progress)
    }

    /// First-launch bootstrap — wider backend window so the Dashboard has real
    /// history immediately.
    @discardableResult
    public func executeFullHistory(progress: ((Progress) -> Void)? = nil) async throws -> Int {
        try await run(fullHistory: true, progress: progress)
    }

    // MARK: - Orchestration

    private func run(fullHistory: Bool, progress: ((Progress) -> Void)?) async throws -> Int {
        let owned = try await ownedCardIDs()
        guard !owned.isEmpty else { throw SyncError.noOwnedCards }

        // Push owned so the backend ingest covers them. Best-effort: ingest is
        // async server-side, and we still want to read whatever prices exist.
        _ = try? await pushOwned.execute()

        let cutoff = Date().addingTimeInterval(-historyWindow)

        progress?(.init(phase: .fetching, importedCount: 0))
        let snapshots: [PriceSnapshot]
        do {
            progress?(.init(phase: .parsing, importedCount: 0))
            snapshots = fullHistory
                ? try await backendSource.fetchFullHistory(ownedCardIDs: owned, windowStart: cutoff)
                : try await backendSource.fetchSnapshots(ownedCardIDs: owned)
        } catch PriceSourceError.unauthorized {
            throw SyncError.unauthorized
        } catch {
            throw SyncError.sourceFailed(message: error.localizedDescription)
        }

        progress?(.init(phase: .persisting, importedCount: snapshots.count))
        try await priceRepository.upsert(snapshots, keepingSince: cutoff)

        progress?(.init(phase: .pruning, importedCount: snapshots.count))
        try await priceRepository.markSyncCompleted(at: Date())

        progress?(.init(phase: .finished, importedCount: snapshots.count))
        return snapshots.count
    }

    // MARK: - Helpers

    private func ownedCardIDs() async throws -> Set<UUID> {
        let owned = (try? await collectionItemRepository.allItems()) ?? []
        return Set(owned.map(\.cardID))
    }
}

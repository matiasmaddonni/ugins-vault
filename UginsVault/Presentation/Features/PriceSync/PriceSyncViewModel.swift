//
//  PriceSyncViewModel.swift
//  UginsVault — Presentation: PriceSync
//
//  Drives the price-sync loading screen and the manual "Refresh
//  prices" button in Settings. Owns the Wi-Fi gate, the staged boot
//  flow (seed catalogue if empty → sync MTGJSON prices), and the
//  progress mirror the view binds to.
//

import Foundation
import Observation

@MainActor
@Observable
public final class PriceSyncViewModel {

    // MARK: - Status

    public enum Status: Equatable {
        case idle
        case waitingForWiFi
        case seeding(savedSoFar: Int)
        case fetching
        case parsing
        case persisting
        case pruning
        case finished(importedCount: Int)
        case failed(message: String)
    }

    // MARK: - Observed state

    public private(set) var status: Status = .idle
    public var isWiFiAlertPresented: Bool = false

    // MARK: - Dependencies

    @ObservationIgnored private let useCase: SyncPricesUseCase
    @ObservationIgnored private let seedCatalogue: SeedCatalogueUseCase
    @ObservationIgnored private let cardRepository: CardRepository
    @ObservationIgnored private let reachability: NetworkReachability
    @ObservationIgnored private let seedQuery: String
    /// When `true` the boot/refresh sync pulls the FULL price-history
    /// dump (so the Dashboard has real movers immediately). Background +
    /// pull-to-refresh stay on the lighter today-only path.
    @ObservationIgnored private let fullHistory: Bool

    public init(
        useCase: SyncPricesUseCase,
        seedCatalogue: SeedCatalogueUseCase,
        cardRepository: CardRepository,
        reachability: NetworkReachability,
        seedQuery: String = "set:fdn",
        fullHistory: Bool = true
    ) {
        self.useCase = useCase
        self.seedCatalogue = seedCatalogue
        self.cardRepository = cardRepository
        self.reachability = reachability
        self.seedQuery = seedQuery
        self.fullHistory = fullHistory
    }

    // MARK: - Intents

    /// Boot sync. Three phases, any of which can short-circuit:
    ///   1. Wi-Fi gate — bail to the Wi-Fi alert if no.
    ///   2. Seed the local catalogue from Scryfall when empty
    ///      (Foundations on first launch). Without this the MTGJSON
    ///      owned-cards intersection produces zero rows + the user
    ///      stares at a "catalogue empty" error.
    ///   3. Sync MTGJSON prices for the seeded cards.
    public func sync() async {
        guard reachability.isOnWiFi else {
            status = .waitingForWiFi
            isWiFiAlertPresented = true
            return
        }

        do {
            if try await cardRepository.totalCount() == 0 {
                status = .seeding(savedSoFar: 0)
                try await seedCatalogue.execute(query: seedQuery) { [weak self] progress in
                    self?.status = .seeding(savedSoFar: progress.savedCount)
                }
            }
        } catch {
            status = .failed(message: error.localizedDescription)
            return
        }

        do {
            let progressHandler: (SyncPricesUseCase.Progress) -> Void = { [weak self] progress in
                self?.applyProgress(progress)
            }
            let count = fullHistory
                ? try await useCase.executeFullHistory(progress: progressHandler)
                : try await useCase.execute(progress: progressHandler)
            status = .finished(importedCount: count)
        } catch let error as SyncPricesUseCase.SyncError {
            status = .failed(message: error.localizedDescription)
        } catch {
            status = .failed(message: error.localizedDescription)
        }
    }

    public func dismissWiFiAlert() {
        isWiFiAlertPresented = false
        status = .idle
    }

    /// Lets the user move on without prices when sync fails. The
    /// Root view's `onFinish` treats this exactly like a normal
    /// completion + advances to Home.
    public func skip() {
        status = .finished(importedCount: 0)
    }

    // MARK: - Helpers

    private func applyProgress(_ progress: SyncPricesUseCase.Progress) {
        switch progress.phase {
        case .fetching:   status = .fetching
        case .parsing:    status = .parsing
        case .persisting: status = .persisting
        case .pruning:    status = .pruning
        case .finished:   status = .finished(importedCount: progress.importedCount)
        }
    }

    // MARK: - Derived

    /// Localized one-line description of the current status.
    public var statusCopy: String {
        switch status {
        case .idle:                       return String(localized: "Preparing…")
        case .waitingForWiFi:             return String(localized: "Wi-Fi required")
        case .seeding(let savedSoFar):    return String(localized: "Building catalogue — \(savedSoFar) cards")
        case .fetching:                   return String(localized: "Downloading pricing data…")
        case .parsing:                    return String(localized: "Reading price snapshots…")
        case .persisting:                 return String(localized: "Saving to your vault…")
        case .pruning:                    return String(localized: "Tidying up old data…")
        case .finished:                   return String(localized: "Done")
        case .failed(let msg):            return msg
        }
    }

    public var isFinished: Bool {
        if case .finished = status { return true }
        return false
    }

    public var isFailed: Bool {
        if case .failed = status { return true }
        return false
    }
}

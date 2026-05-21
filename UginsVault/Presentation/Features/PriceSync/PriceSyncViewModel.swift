//
//  PriceSyncViewModel.swift
//  UginsVault — Presentation: PriceSync
//
//  Drives the price-sync loading screen and the manual "Refresh prices"
//  button in Settings. Owns the Wi-Fi gate + the progress mirror the view
//  binds to. The catalogue is no longer seeded here — it fills from the cards
//  the user adds/imports — so an empty collection finishes cleanly.
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
    @ObservationIgnored private let reachability: NetworkReachability
    /// When `true` the boot/refresh sync pulls the FULL price-history window
    /// (so the Dashboard has real movers immediately). Background +
    /// pull-to-refresh stay on the lighter today-only path.
    @ObservationIgnored private let fullHistory: Bool

    public init(
        useCase: SyncPricesUseCase,
        reachability: NetworkReachability,
        fullHistory: Bool = true
    ) {
        self.useCase = useCase
        self.reachability = reachability
        self.fullHistory = fullHistory
    }

    // MARK: - Intents

    /// Boot / manual price sync. Wi-Fi gated. An empty collection finishes
    /// cleanly (nothing to price) instead of erroring.
    public func sync() async {
        guard reachability.isOnWiFi else {
            status = .waitingForWiFi
            isWiFiAlertPresented = true
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
        } catch SyncPricesUseCase.SyncError.noOwnedCards {
            status = .finished(importedCount: 0)
        } catch {
            status = .failed(message: error.localizedDescription)
        }
    }

    public func dismissWiFiAlert() {
        isWiFiAlertPresented = false
        status = .idle
    }

    /// Lets the user move on without prices when sync fails. The Root view's
    /// `onFinish` treats this exactly like a normal completion + advances Home.
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

    public var statusCopy: String {
        switch status {
        case .idle:                return String(localized: "Preparing…")
        case .waitingForWiFi:      return String(localized: "Wi-Fi required")
        case .fetching:            return String(localized: "Downloading pricing data…")
        case .parsing:             return String(localized: "Reading price snapshots…")
        case .persisting:          return String(localized: "Saving to your vault…")
        case .pruning:             return String(localized: "Tidying up old data…")
        case .finished:            return String(localized: "Done")
        case .failed(let msg):     return msg
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

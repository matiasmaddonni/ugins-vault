//
//  DashboardViewModel.swift
//  UginsVault — Presentation: Dashboard
//
//  Drives the Dashboard tab. Reads the latest `DashboardSnapshot` from
//  the injected `DashboardRepository`, mirrors the active display
//  currency from the `SessionRepository`, and exposes the loading /
//  loaded / error transitions the view binds to.
//

import Foundation
import Observation

@MainActor
@Observable
public final class DashboardViewModel {

    // MARK: - Status

    public enum Status: Equatable {
        case idle
        case loading
        case loaded
        case error(message: String)
    }

    // MARK: - Observed state

    public private(set) var snapshot: DashboardSnapshot?
    public private(set) var status: Status = .idle
    public private(set) var currency: Currency

    /// `true` when the last price sync failed for a reason worth showing the
    /// user (network / server). Auth expiry routes to login instead.
    public private(set) var syncFailed: Bool = false

    // MARK: - Dependencies

    @ObservationIgnored private let repository: DashboardRepository
    @ObservationIgnored private let sessionRepository: SessionRepository
    @ObservationIgnored private let syncPrices: SyncPricesUseCase?
    @ObservationIgnored private let reachability: NetworkReachability?
    @ObservationIgnored private let exchangeRateRepository: ExchangeRateRepository?
    @ObservationIgnored private let signOutAccount: SignOutAccountUseCase?
    @ObservationIgnored private let onRequireSignIn: () -> Void

    @ObservationIgnored private var hasAutoSynced = false

    // MARK: - Init

    public init(
        repository: DashboardRepository,
        sessionRepository: SessionRepository,
        syncPrices: SyncPricesUseCase? = nil,
        reachability: NetworkReachability? = nil,
        exchangeRateRepository: ExchangeRateRepository? = nil,
        signOutAccount: SignOutAccountUseCase? = nil,
        onRequireSignIn: @escaping () -> Void = {}
    ) {
        self.repository = repository
        self.sessionRepository = sessionRepository
        self.syncPrices = syncPrices
        self.reachability = reachability
        self.exchangeRateRepository = exchangeRateRepository
        self.signOutAccount = signOutAccount
        self.onRequireSignIn = onRequireSignIn
        self.currency = sessionRepository.currency
    }

    /// Latest exchange rate from USD to the active display currency.
    /// View passes it to `CurrencyFormatter.format(_:currency:rate:)`
    /// so ARS / EUR values render with real conversion instead of a
    /// symbol swap.
    public var exchangeRate: ExchangeRate? {
        exchangeRateRepository?.rate(toQuote: currency)
    }

    // MARK: - Derived

    public var isLoading: Bool {
        if case .loading = status { return true }
        return false
    }

    // MARK: - Lifecycle

    public func onAppear() async {
        currency = sessionRepository.currency
        if snapshot == nil {
            await load()
        }
        // Auto-sync once per Dashboard lifetime so prices refresh after sign-in
        // without a manual pull. Gated on Wi-Fi inside `runSync`.
        if !hasAutoSynced {
            hasAutoSynced = true
            if await runSync() { await load() }
        }
        // Fire-and-forget FX refresh — view re-reads `exchangeRate`
        // once the repo bumps its cache.
        if let exchangeRateRepository {
            Task { try? await exchangeRateRepository.refresh() }
        }
    }

    public func load() async {
        status = .loading
        do {
            let result = try await repository.fetch()
            self.snapshot = result
            self.status = .loaded
        } catch {
            self.status = .error(message: error.localizedDescription)
        }
    }

    /// Pull-to-refresh hook. Fires a price sync (silently, gated on
    /// Wi-Fi) and then re-fetches the snapshot. The sync runs
    /// fire-and-forget — Dashboard never blocks on it because the
    /// snapshot consumes locally-persisted price data, not the
    /// remote response.
    public func refresh() async {
        await runSync()
        await load()
    }

    /// Runs a price sync (Wi-Fi-gated). Expired session → sign out + route to
    /// login; network/server failure → flag `syncFailed`; no-owned-cards is
    /// benign. Never throws — the snapshot reads local data regardless.
    /// - Returns: `true` when a sync was attempted (so the caller knows whether
    ///   re-reading the snapshot is worthwhile).
    @discardableResult
    private func runSync() async -> Bool {
        guard let syncPrices, reachability?.isOnWiFi == true else { return false }
        do {
            _ = try await syncPrices.execute(progress: nil)
            syncFailed = false
        } catch SyncPricesUseCase.SyncError.unauthorized {
            syncFailed = false
            await signOutAccount?.execute()
            onRequireSignIn()
        } catch SyncPricesUseCase.SyncError.noOwnedCards {
            syncFailed = false
        } catch {
            syncFailed = true
        }
        return true
    }

    /// Switching currency at the app level must update every number
    /// without a refetch. The view calls this from `.task`/`.onChange`
    /// so the @Observable read mirrors the session value.
    public func refreshCurrencyIfNeeded() {
        let latest = sessionRepository.currency
        if latest != currency {
            currency = latest
        }
    }
}

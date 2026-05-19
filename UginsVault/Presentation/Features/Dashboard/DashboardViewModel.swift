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

    // MARK: - Dependencies

    @ObservationIgnored private let repository: DashboardRepository
    @ObservationIgnored private let sessionRepository: SessionRepository

    // MARK: - Init

    public init(
        repository: DashboardRepository,
        sessionRepository: SessionRepository
    ) {
        self.repository = repository
        self.sessionRepository = sessionRepository
        self.currency = sessionRepository.currency
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

    /// Pull-to-refresh hook. Re-fetches the snapshot.
    public func refresh() async {
        do {
            let result = try await repository.fetch()
            self.snapshot = result
            self.status = .loaded
        } catch {
            self.status = .error(message: error.localizedDescription)
        }
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

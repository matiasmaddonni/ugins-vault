//
//  DashboardRepository.swift
//  UginsVault — Domain layer
//
//  Read-only surface for the Dashboard tab. v0.4 ships a mock impl
//  + a "real-stats" producer that reads from CardRepository,
//  CollectionItemRepository and StackRepository — pricing-history
//  features (sparkline, deltas, gainers/losers) stay mocked until an
//  FX/price-history backend lands.
//

import Foundation
import Observation

@MainActor
public protocol DashboardRepository: AnyObject, Observable {

    /// Latest computed snapshot. `nil` before the first fetch.
    var snapshot: DashboardSnapshot? { get }

    /// `true` while a fetch is in flight.
    var isFetching: Bool { get }

    /// Re-fetches the snapshot. Implementations decide what's real
    /// vs mocked — the call site just gets a final `DashboardSnapshot`.
    @discardableResult
    func fetch() async throws -> DashboardSnapshot
}

//
//  ExchangeRateRepository.swift
//  UginsVault — Domain layer
//
//  Live + cached exchange rates. The view layer reads `rate(toQuote:)`
//  at render time so the user can flip the display currency without
//  triggering a refetch; the repo serves the cached value or fires a
//  background refresh on its own clock.
//
//  v0.7 ships with two upstreams:
//    - dolarapi.com.ar  — USD → ARS (blue dollar, default)
//    - frankfurter.app  — USD → EUR (ECB rates)
//  A manual user override on `SessionStateStore.manualARSRate` short-
//  circuits the dolarapi call entirely.
//

import Foundation
import Observation

@MainActor
public protocol ExchangeRateRepository: AnyObject, Observable {

    /// Most recent rate for `quote` (base assumed USD). `nil` until
    /// the first successful refresh.
    func rate(toQuote quote: Currency) -> ExchangeRate?

    /// Convenience — applies the cached rate to `amount`. Returns
    /// `amount` unchanged when the rate is missing (degrades to a
    /// no-op rather than blocking the UI).
    func convert(_ amount: Decimal, from base: Currency, to quote: Currency) -> Decimal

    /// Forces a re-fetch of every known quote. Called from the
    /// Settings "Refresh rates" button + the weekly background task.
    @discardableResult
    func refresh() async throws -> [ExchangeRate]

    var lastRefreshedAt: Date? { get }
}

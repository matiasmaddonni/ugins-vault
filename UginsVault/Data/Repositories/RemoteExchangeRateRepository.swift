//
//  RemoteExchangeRateRepository.swift
//  UginsVault — Data layer
//
//  `ExchangeRateRepository` backed by `DolarAPIClient` (USD→ARS) +
//  `FrankfurterClient` (USD→EUR). Caches the latest rates in memory
//  + persists the last-refresh stamp via `SessionStorageDataSource`
//  so we can show "Rates updated 12m ago" in Settings.
//
//  Manual override behaviour: when `SessionStateStore.manualARSRate`
//  is non-nil, the ARS rate is served from that value with source
//  `.manual` and dolarapi is skipped. Refresh still hits Frankfurter
//  so EUR stays current.
//

import Foundation
import Observation

@MainActor
@Observable
public final class RemoteExchangeRateRepository: ExchangeRateRepository {

    public private(set) var lastRefreshedAt: Date?

    @ObservationIgnored private let dolarClient: DolarAPIClient
    @ObservationIgnored private let frankfurterClient: FrankfurterClient
    @ObservationIgnored private let sessionRepository: SessionStateStore
    @ObservationIgnored private let storage: SessionStorageDataSource
    @ObservationIgnored private let lastRefreshedKey = "uv.fx.lastRefreshedAt"

    @ObservationIgnored private var cache: [Currency: ExchangeRate] = [:]

    public init(
        dolarClient: DolarAPIClient,
        frankfurterClient: FrankfurterClient,
        sessionRepository: SessionStateStore,
        storage: SessionStorageDataSource
    ) {
        self.dolarClient = dolarClient
        self.frankfurterClient = frankfurterClient
        self.sessionRepository = sessionRepository
        self.storage = storage

        if let raw = storage.string(forKey: lastRefreshedKey),
           let interval = TimeInterval(raw) {
            self.lastRefreshedAt = Date(timeIntervalSince1970: interval)
        }
    }

    // MARK: - Reads

    public func rate(toQuote quote: Currency) -> ExchangeRate? {
        if quote == .usd {
            return ExchangeRate(
                base: .usd, quote: .usd, rate: 1, fetchedAt: Date(),
                source: .identity
            )
        }
        if quote == .ars, let manual = sessionRepository.manualARSRate, manual > 0 {
            return ExchangeRate(
                base: .usd, quote: .ars, rate: manual, fetchedAt: Date(),
                source: .manual
            )
        }
        return cache[quote]
    }

    public func convert(_ amount: Decimal, from base: Currency, to quote: Currency) -> Decimal {
        guard base == .usd else {
            // Every rate we cache is keyed off USD as base.
            // Non-USD bases would need a USD pivot; skip until needed.
            return amount
        }
        guard let rate = rate(toQuote: quote)?.rate else { return amount }
        return amount * rate
    }

    // MARK: - Writes

    @discardableResult
    public func refresh() async throws -> [ExchangeRate] {
        var refreshed: [ExchangeRate] = []
        let now = Date()

        // EUR — frankfurter always.
        if let value = try? await frankfurterClient.fetchRate(from: "USD", to: "EUR"),
           value > 0 {
            let rate = ExchangeRate(
                base: .usd, quote: .eur, rate: Decimal(value),
                fetchedAt: now, source: .frankfurter
            )
            cache[.eur] = rate
            refreshed.append(rate)
        }

        // ARS — manual override first; else dolarapi blue.
        if let manual = sessionRepository.manualARSRate, manual > 0 {
            let rate = ExchangeRate(
                base: .usd, quote: .ars, rate: manual,
                fetchedAt: now, source: .manual
            )
            cache[.ars] = rate
            refreshed.append(rate)
        } else if let quote = try? await dolarClient.fetchBlue(), quote.venta > 0 {
            let rate = ExchangeRate(
                base: .usd, quote: .ars, rate: Decimal(quote.venta),
                fetchedAt: now, source: .dolarapiBlue
            )
            cache[.ars] = rate
            refreshed.append(rate)
        }

        lastRefreshedAt = now
        storage.set(String(now.timeIntervalSince1970), forKey: lastRefreshedKey)
        return refreshed
    }
}

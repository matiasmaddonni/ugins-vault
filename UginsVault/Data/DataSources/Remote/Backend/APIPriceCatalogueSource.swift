//
//  APIPriceCatalogueSource.swift
//  UginsVault — Data layer / Backend
//
//  `PriceCatalogueSource` backed by the backend `GET /v1/prices`. The backend
//  is the authoritative price source; each history point maps to a
//  `PriceSnapshot` so `RealDashboardRepository.computeHistory` runs unchanged.
//  The marketplace passed to the API is `SessionRepository.preferredPriceSource`
//  so on-device aggregations and backend numbers agree.
//

import Foundation

@MainActor
public final class APIPriceCatalogueSource: PriceCatalogueSource {

    private let client: UginsVaultAPIClient
    private let sessionRepository: SessionRepository
    private let defaultWindow: Int
    private let fullHistoryWindow: Int

    public init(
        client: UginsVaultAPIClient,
        sessionRepository: SessionRepository,
        defaultWindow: Int = 35,
        fullHistoryWindow: Int = 90
    ) {
        self.client = client
        self.sessionRepository = sessionRepository
        self.defaultWindow = defaultWindow
        self.fullHistoryWindow = fullHistoryWindow
    }

    public func fetchSnapshots(ownedCardIDs: Set<UUID>) async throws -> [PriceSnapshot] {
        try await fetch(window: defaultWindow, ownedCardIDs: ownedCardIDs)
    }

    public func fetchFullHistory(ownedCardIDs: Set<UUID>, windowStart: Date?) async throws -> [PriceSnapshot] {
        let window: Int
        if let windowStart {
            let days = Calendar(identifier: .iso8601)
                .dateComponents([.day], from: windowStart, to: Date()).day ?? fullHistoryWindow
            window = min(fullHistoryWindow, max(defaultWindow, days + 1))
        } else {
            window = fullHistoryWindow
        }
        return try await fetch(window: window, ownedCardIDs: ownedCardIDs)
    }

    private func fetch(window: Int, ownedCardIDs: Set<UUID>) async throws -> [PriceSnapshot] {
        guard !ownedCardIDs.isEmpty else { return [] }
        let source = sessionRepository.preferredPriceSource
        let response = try await client.prices(window: window, source: source.rawValue)
        return Self.map(response, allowList: ownedCardIDs)
    }

    // MARK: - Mapping

    nonisolated static func map(_ response: PricesResponseDTO, allowList: Set<UUID>) -> [PriceSnapshot] {
        var out: [PriceSnapshot] = []
        for card in response.cards {
            guard
                let cardID = UUID(uuidString: card.cardId),
                allowList.contains(cardID),
                let source = PriceSource(rawValue: card.source)
            else { continue }

            let currency = Currency(rawValue: card.currency) ?? source.nativeCurrency
            for point in card.history where point.price > 0 {
                guard let day = Self.day(from: point.date) else { continue }
                out.append(PriceSnapshot(
                    cardID: cardID,
                    source: source,
                    date: day,
                    currency: currency,
                    retail: point.price
                ))
            }
        }
        return out
    }

    /// Parses a `"yyyy-MM-dd"` calendar day into a `Date` at 00:00 UTC, matching
    /// `PriceSnapshot.date`. Hand-parsed to avoid a non-Sendable `DateFormatter`.
    nonisolated static func day(from string: String) -> Date? {
        let parts = string.split(separator: "-")
        guard
            parts.count == 3,
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2])
        else { return nil }
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}

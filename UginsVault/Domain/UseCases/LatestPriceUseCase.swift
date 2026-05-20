//
//  LatestPriceUseCase.swift
//  UginsVault — Domain layer
//
//  Resolves a per-card retail price with a layered fallback:
//
//   1. `PriceRepository.latest(cardID: source: preferred)` — what
//      MTGJSON had for this card the last time we synced.
//   2. Any other `PriceSource` MTGJSON shipped — the data is already
//      on-device, no extra network hit.
//   3. The Scryfall `Card.prices` snapshot baked into the local
//      catalogue (always present after a Scryfall sync but only one
//      data point, no history).
//
//  Returns both the value and the source it came from so the view
//  can credit "via Card Kingdom" or "via Scryfall" honestly.
//

import Foundation

@MainActor
public final class LatestPriceUseCase {

    public struct Resolved: Equatable, Sendable {
        public let amount: Decimal
        public let currency: Currency
        public let source: Source

        public enum Source: Equatable, Sendable {
            case marketplace(PriceSource)
            case scryfall
        }
    }

    private let priceRepository: PriceRepository

    public init(priceRepository: PriceRepository) {
        self.priceRepository = priceRepository
    }

    /// Resolves the best available price for `card` with the user's
    /// preferred source taking priority. Returns `nil` when neither
    /// the local MTGJSON cache nor the Scryfall fallback has data.
    public func execute(
        card: Card,
        preferred: PriceSource,
        finish: Finish = .nonfoil
    ) async -> Resolved? {

        if let snapshot = try? await priceRepository.latest(cardID: card.id, source: preferred),
           snapshot.retail > 0 {
            return Resolved(
                amount: snapshot.retail,
                currency: snapshot.currency,
                source: .marketplace(preferred)
            )
        }

        for source in PriceSource.allCases where source != preferred {
            if let snapshot = try? await priceRepository.latest(cardID: card.id, source: source),
               snapshot.retail > 0 {
                return Resolved(
                    amount: snapshot.retail,
                    currency: snapshot.currency,
                    source: .marketplace(source)
                )
            }
        }

        if let usd = card.prices.usdPrice(for: finish), usd > 0 {
            return Resolved(amount: usd, currency: .usd, source: .scryfall)
        }
        return nil
    }
}

//
//  LatestPriceUseCase.swift
//  UginsVault — Domain layer
//
//  Resolves a per-card retail price from the local price store (backend
//  snapshots). Prefers the user's chosen source, then
//  any other source the store has. Returns `nil` when nothing is priced —
//  there is no Scryfall fallback: the backend is the single source of truth.
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
        }
    }

    private let priceRepository: PriceRepository

    public init(priceRepository: PriceRepository) {
        self.priceRepository = priceRepository
    }

    /// Best available price for `card`, preferring `preferred`. `nil` when the
    /// store has no priced snapshot for the card in any source.
    public func execute(card: Card, preferred: PriceSource) async -> Resolved? {
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

        return nil
    }
}

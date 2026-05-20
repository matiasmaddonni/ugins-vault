//
//  RealDashboardRepository.swift
//  UginsVault — Data layer / Dashboard
//
//  `DashboardRepository` that assembles the snapshot from real
//  catalogue data (CollectionItems × Stacks × PriceRepository) and
//  bolts the mocked historical fields (sparkline / gainers / losers)
//  on top via `DashboardSnapshot.assemble(realStats:mockedHistory:)`.
//
//  Pricing reads honour `SessionRepository.preferredPriceSource` with
//  the same fallback chain `LatestPriceUseCase` uses on Card detail.
//  Anything we still mock is tagged `HISTORICAL_MOCK` so the swap-in
//  point stays obvious when the FX + history backend land.
//

import Foundation
import Observation

@MainActor
@Observable
public final class RealDashboardRepository: DashboardRepository {

    public private(set) var snapshot: DashboardSnapshot?
    public private(set) var isFetching: Bool = false

    @ObservationIgnored private let cardRepository: CardRepository
    @ObservationIgnored private let collectionItemRepository: CollectionItemRepository
    @ObservationIgnored private let stackRepository: StackRepository
    @ObservationIgnored private let priceRepository: PriceRepository
    @ObservationIgnored private let sessionRepository: SessionRepository

    public init(
        cardRepository: CardRepository,
        collectionItemRepository: CollectionItemRepository,
        stackRepository: StackRepository,
        priceRepository: PriceRepository,
        sessionRepository: SessionRepository
    ) {
        self.cardRepository = cardRepository
        self.collectionItemRepository = collectionItemRepository
        self.stackRepository = stackRepository
        self.priceRepository = priceRepository
        self.sessionRepository = sessionRepository
    }

    @discardableResult
    public func fetch() async throws -> DashboardSnapshot {
        isFetching = true
        defer { isFetching = false }

        let items = try await collectionItemRepository.allItems()
        let stacks = try await stackRepository.refresh()
        let stackByID = Dictionary(uniqueKeysWithValues: stacks.map { ($0.id, $0) })

        // Hydrate cards + per-(card,source) latest snapshots.
        let cardIDs = Set(items.map(\.cardID))
        var cardsByID: [UUID: Card] = [:]
        for id in cardIDs {
            if let card = try? await cardRepository.card(id: id) {
                cardsByID[id] = card
            }
        }

        let preferred = sessionRepository.preferredPriceSource
        let preferredLatest = (try? await priceRepository.latestByCard(source: preferred)) ?? [:]
        var fallbackLatest: [PriceSource: [UUID: PriceSnapshot]] = [:]
        for source in PriceSource.allCases where source != preferred {
            fallbackLatest[source] = (try? await priceRepository.latestByCard(source: source)) ?? [:]
        }

        let resolver = PriceResolver(
            preferred: preferred,
            preferredLatest: preferredLatest,
            fallbackLatest: fallbackLatest
        )

        let real = buildRealStats(
            items: items,
            cardsByID: cardsByID,
            stackByID: stackByID,
            resolver: resolver
        )

        let assembled = DashboardSnapshot.assemble(
            realStats: real,
            mockedHistory: MockDashboardRepository.seed
        )
        self.snapshot = assembled
        return assembled
    }

    // MARK: - Producers

    private func buildRealStats(
        items: [CollectionItem],
        cardsByID: [UUID: Card],
        stackByID: [UUID: Stack],
        resolver: PriceResolver
    ) -> DashboardSnapshot.RealStats {

        var totalValue: Decimal = .zero
        var totalQuantity: Int = 0
        var foilQuantity: Int = 0
        var byFormat: [String: (slice: FormatSlice, sum: Decimal)] = [:]
        var bySet: [String: (bar: SetBar, sum: Decimal)] = [:]

        for item in items {
            totalQuantity += item.quantity
            if item.finish != .nonfoil { foilQuantity += item.quantity }

            guard let card = cardsByID[item.cardID] else { continue }
            let unitPrice = resolver.price(for: card, finish: item.finish) ?? .zero
            let rowValue = unitPrice * Decimal(item.quantity)
            totalValue += rowValue

            // byFormat — bucket "Unsorted" when no stack format.
            let format = stackByID[item.stackID]?.format
            let formatKey = format?.rawValue ?? "unsorted"
            let formatName = format?.displayName ?? String(localized: "Unsorted")
            let formatColor: UInt32 = format.map(Self.colorHex(for:)) ?? 0x7E7A93
            let existingFormat = byFormat[formatKey]?.sum ?? .zero
            byFormat[formatKey] = (
                slice: FormatSlice(
                    id: formatKey,
                    displayName: formatName,
                    valueUSD: existingFormat + rowValue,
                    colorHex: formatColor
                ),
                sum: existingFormat + rowValue
            )

            // bySet — group by Card.setCode.
            let setCode = card.setCode.uppercased()
            let existingSet = bySet[setCode]?.sum ?? .zero
            bySet[setCode] = (
                bar: SetBar(code: setCode, name: card.setName, valueUSD: existingSet + rowValue),
                sum: existingSet + rowValue
            )
        }

        let uniqueQuantity = items.count
        let avg: Decimal = totalQuantity > 0
            ? totalValue / Decimal(totalQuantity)
            : .zero

        let formatSlices = byFormat.values
            .map(\.slice)
            .sorted { $0.valueUSD > $1.valueUSD }

        let setBars = bySet.values
            .map(\.bar)
            .sorted { $0.valueUSD > $1.valueUSD }
            .prefix(8)
            .map { $0 }

        return DashboardSnapshot.RealStats(
            totalValueUSD: totalValue,
            byFormat: formatSlices,
            bySet: setBars,
            stats: CollectionStats(
                totalCards: totalQuantity,
                uniqueCards: uniqueQuantity,
                foils: foilQuantity,
                avgValueUSD: avg
            )
        )
    }

    // MARK: - Format colour map

    /// Mirrors the HTML prototype's `FORMAT_COLOR` palette. Unmapped
    /// formats fall back to the muted "unsorted" tone.
    private static func colorHex(for format: Format) -> UInt32 {
        switch format {
        case .modern:    return 0xB9A4D6
        case .commander: return 0xC9A24B
        case .legacy:    return 0x6BA8D8
        case .pioneer:   return 0x7BC58F
        case .pauper:    return 0x7E7A93
        case .standard:  return 0xD87858
        default:         return 0x7E7A93
        }
    }
}

// MARK: - Price resolver helper

@MainActor
private struct PriceResolver {

    let preferred: PriceSource
    let preferredLatest: [UUID: PriceSnapshot]
    let fallbackLatest: [PriceSource: [UUID: PriceSnapshot]]

    func price(for card: Card, finish: Finish) -> Decimal? {
        if let snapshot = preferredLatest[card.id], snapshot.retail > 0 {
            return snapshot.retail
        }
        for source in PriceSource.allCases where source != preferred {
            if let snapshot = fallbackLatest[source]?[card.id], snapshot.retail > 0 {
                return snapshot.retail
            }
        }
        if let usd = card.prices.usdPrice(for: finish), usd > 0 {
            return usd
        }
        return nil
    }
}

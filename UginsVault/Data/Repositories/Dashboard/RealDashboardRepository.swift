//
//  RealDashboardRepository.swift
//  UginsVault — Data layer / Dashboard
//
//  `DashboardRepository` that assembles the snapshot from real
//  catalogue data (CollectionItems × Stacks × PriceRepository) and
//  bolts the mocked historical fields (sparkline / gainers / losers)
//  on top via `DashboardSnapshot.assemble(realStats:mockedHistory:)`.
//
//  Pricing reads honour `SessionStateStore.preferredPriceSource` with
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
    @ObservationIgnored private let sessionRepository: SessionStateStore
    @ObservationIgnored private let wishlistRepository: WishlistRepository?

    public init(
        cardRepository: CardRepository,
        collectionItemRepository: CollectionItemRepository,
        stackRepository: StackRepository,
        priceRepository: PriceRepository,
        sessionRepository: SessionStateStore,
        wishlistRepository: WishlistRepository? = nil
    ) {
        self.cardRepository = cardRepository
        self.collectionItemRepository = collectionItemRepository
        self.stackRepository = stackRepository
        self.priceRepository = priceRepository
        self.sessionRepository = sessionRepository
        self.wishlistRepository = wishlistRepository
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

        var real = buildRealStats(
            items: items,
            cardsByID: cardsByID,
            stackByID: stackByID,
            resolver: resolver
        )

        // Real wishlist count replaces the mocked teaser numbers. Simple
        // mode has no buy-target, so "ready to buy" is always 0.
        if let wishlistRepository {
            let count = (try? await wishlistRepository.refresh())?.count ?? 0
            real.wishlistTrackedCount = count
            real.wishlistReadyToBuyCount = 0
        }

        // Real price-history fields (sparkline / week-delta / movers).
        // Replaces the mocked bag entirely — degrades to honest empties
        // when there aren't yet two distinct days of history to compare.
        let historyWindow: TimeInterval = 35 * 24 * 60 * 60
        let since = Date().addingTimeInterval(-historyWindow)
        let snapshots = (try? await priceRepository.allSince(source: preferred, since: since)) ?? []
        let history = Self.computeHistory(
            items: items,
            cardsByID: cardsByID,
            resolver: resolver,
            snapshots: snapshots,
            moverThreshold: sessionRepository.dashboardMoverThreshold
        )
        real.weekDeltaUSD   = history.weekDeltaUSD
        real.weekDeltaPct   = history.weekDeltaPct
        real.monthSparkline = history.sparkline
        real.gainers        = history.gainers
        real.losers         = history.losers

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
            let unitPrice = resolver.price(for: card) ?? .zero
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

    // MARK: - Price-history producer

    private struct HistoryResult {
        var weekDeltaUSD: Decimal
        var weekDeltaPct: Double
        var sparkline: [Decimal]
        var gainers: [Mover]
        var losers: [Mover]
    }

    /// Builds the sparkline + week-delta + per-card movers from windowed
    /// price snapshots. Returns honest empties when there are fewer than
    /// two distinct days of history (nothing to compare yet) — this is
    /// what replaces the old mocked gainers/losers.
    private static func computeHistory(
        items: [CollectionItem],
        cardsByID: [UUID: Card],
        resolver: PriceResolver,
        snapshots: [PriceSnapshot],
        moverThreshold: Decimal
    ) -> HistoryResult {
        let empty = HistoryResult(weekDeltaUSD: .zero, weekDeltaPct: 0, sparkline: [], gainers: [], losers: [])

        // Group snapshots by card (day-keyed, carry-forward friendly).
        var historyByCard: [UUID: [(day: Date, price: Decimal)]] = [:]
        var daySet: Set<Date> = []
        let calendar = Calendar(identifier: .iso8601)
        for snap in snapshots where snap.retail > 0 {
            let day = calendar.startOfDay(for: snap.date)
            historyByCard[snap.cardID, default: []].append((day, snap.retail))
            daySet.insert(day)
        }
        let days = daySet.sorted()
        guard days.count >= 2, let latestDay = days.last else { return empty }
        let weekAgoDay = calendar.date(byAdding: .day, value: -7, to: latestDay) ?? days[0]

        // Last price on/before a target day (carry-forward).
        func priceOnDay(_ cardID: UUID, _ target: Date) -> Decimal? {
            guard let points = historyByCard[cardID] else { return nil }
            var result: Decimal?
            for point in points {
                if point.day <= target { result = point.price } else { break }
            }
            return result
        }

        var qtyByCard: [UUID: Int] = [:]
        for item in items { qtyByCard[item.cardID, default: 0] += item.quantity }

        // Portfolio value on a day: per-card price-on-day × quantity,
        // falling back to the resolver's latest for cards lacking history.
        func portfolio(on target: Date) -> Decimal {
            var total: Decimal = .zero
            for (cardID, qty) in qtyByCard {
                let unit: Decimal
                if let priced = priceOnDay(cardID, target) {
                    unit = priced
                } else if let card = cardsByID[cardID],
                          let fallback = resolver.price(for: card) {
                    unit = fallback
                } else {
                    unit = .zero
                }
                total += unit * Decimal(qty)
            }
            return total
        }

        // Sparkline — sample down to ≤ maxPoints across the window.
        let maxPoints = 24
        let sampledDays: [Date]
        if days.count <= maxPoints {
            sampledDays = days
        } else {
            let step = Double(days.count - 1) / Double(maxPoints - 1)
            sampledDays = (0..<maxPoints).map { index in
                days[min(days.count - 1, Int((Double(index) * step).rounded()))]
            }
        }
        let sparkline = sampledDays.map { portfolio(on: $0) }

        let todayValue = portfolio(on: latestDay)
        let weekAgoValue = portfolio(on: weekAgoDay)
        let weekDeltaUSD = todayValue - weekAgoValue
        let weekDeltaPct: Double = {
            let base = NSDecimalNumber(decimal: weekAgoValue).doubleValue
            guard base > 0 else { return 0 }
            return NSDecimalNumber(decimal: weekDeltaUSD).doubleValue / base * 100
        }()

        // Per-card movers — per-unit 7-day change, threshold-filtered.
        var movers: [Mover] = []
        for cardID in qtyByCard.keys {
            guard let card = cardsByID[cardID],
                  let today = priceOnDay(cardID, latestDay),
                  let weekAgo = priceOnDay(cardID, weekAgoDay),
                  weekAgo > 0 else { continue }
            let delta = today - weekAgo
            guard delta != 0, abs(delta) >= moverThreshold else { continue }
            let pct = NSDecimalNumber(decimal: delta).doubleValue
                    / NSDecimalNumber(decimal: weekAgo).doubleValue * 100
            movers.append(Mover(
                id: cardID.uuidString,
                name: card.name,
                setCode: card.setCode.uppercased(),
                deltaUSD: delta,
                pct: pct
            ))
        }
        let gainers = movers.filter { $0.deltaUSD > 0 }.sorted { $0.pct > $1.pct }.prefix(5).map { $0 }
        let losers  = movers.filter { $0.deltaUSD < 0 }.sorted { $0.pct < $1.pct }.prefix(5).map { $0 }

        return HistoryResult(
            weekDeltaUSD: weekDeltaUSD,
            weekDeltaPct: weekDeltaPct,
            sparkline: sparkline,
            gainers: gainers,
            losers: losers
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

    func price(for card: Card) -> Decimal? {
        if let snapshot = preferredLatest[card.id], snapshot.retail > 0 {
            return snapshot.retail
        }
        for source in PriceSource.allCases where source != preferred {
            if let snapshot = fallbackLatest[source]?[card.id], snapshot.retail > 0 {
                return snapshot.retail
            }
        }
        return nil
    }
}

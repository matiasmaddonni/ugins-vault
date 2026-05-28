//
//  CollectionViewModel.swift
//  UginsVault — Presentation: Collection
//
//  Drives the Collection tab. Reads cards from a `CardRepository`,
//  reports a loading / error state, owns sort + filter + pagination.
//

import Foundation
import Observation

@MainActor
@Observable
public final class CollectionViewModel {

    // MARK: - Status

    public enum Status: Equatable {
        case idle
        case loading
        case loadingMore
        case error(message: String)
    }

    // MARK: - Observed state

    public private(set) var cards: [Card] = []
    public private(set) var matchingCount: Int = 0
    public private(set) var totalCount: Int = 0
    public private(set) var availableSetCodes: [String] = []
    public private(set) var status: Status = .idle
    public private(set) var currency: Currency

    public var searchQuery: String = ""
    public var sort: CardSortOption = .nameAscending
    public var filter: CardFilter = .empty

    // MARK: - Dependencies

    @ObservationIgnored private let sessionRepository: SessionStateStore
    @ObservationIgnored private let cardRepository: CardRepository
    @ObservationIgnored private let exchangeRateRepository: ExchangeRateRepository?
    @ObservationIgnored private let priceRepository: PriceRepository?
    @ObservationIgnored private let priceStatusSource: PriceStatusSource?
    @ObservationIgnored private let syncPrices: SyncPricesUseCase?

    /// Latest retail price per card from the local store (backend) for the
    /// user's preferred source. Cards without a priced snapshot are absent —
    /// they render with no price.
    public private(set) var priceMap: [UUID: Decimal] = [:]

    /// Owned cards still being priced server-side (drives the row "Fetching…"
    /// state). Cards the backend has no price for sit in `noDataCardIDs` and are
    /// NOT shown as fetching.
    public private(set) var fetchingCardIDs: Set<UUID> = []
    public private(set) var noDataCardIDs: Set<UUID> = []

    @ObservationIgnored private var pollTask: Task<Void, Never>?
    @ObservationIgnored private var searchTask: Task<Void, Never>?

    /// Page size for pagination.
    @ObservationIgnored private let pageSize: Int

    // MARK: - Init

    public init(
        sessionRepository: SessionStateStore,
        cardRepository: CardRepository,
        exchangeRateRepository: ExchangeRateRepository? = nil,
        priceRepository: PriceRepository? = nil,
        priceStatusSource: PriceStatusSource? = nil,
        syncPrices: SyncPricesUseCase? = nil,
        pageSize: Int = 50
    ) {
        self.sessionRepository = sessionRepository
        self.cardRepository = cardRepository
        self.exchangeRateRepository = exchangeRateRepository
        self.priceRepository = priceRepository
        self.priceStatusSource = priceStatusSource
        self.syncPrices = syncPrices
        self.pageSize = pageSize
        self.currency = sessionRepository.currency
    }

    /// Price for a card from the local store, or `nil` when unpriced.
    public func price(for cardID: UUID) -> Decimal? {
        priceMap[cardID]
    }

    /// `true` when this card has no local price yet but the backend is still
    /// fetching one (vs. genuinely having no data).
    public func isFetchingPrice(_ cardID: UUID) -> Bool {
        fetchingCardIDs.contains(cardID)
    }

    // MARK: - Derived

    public var hasMore: Bool {
        cards.count < matchingCount
    }

    public var totalValueUSD: Decimal {
        cards.reduce(.zero) { partial, card in
            partial + (priceMap[card.id] ?? .zero)
        }
    }

    /// USD→display-currency rate for `CurrencyFormatter`. `nil` until the
    /// FX repo's first refresh; the formatter then degrades to a symbol
    /// swap rather than a wrong number.
    public var exchangeRate: ExchangeRate? {
        exchangeRateRepository?.rate(toQuote: currency)
    }

    public var hasActiveFilter: Bool {
        !filter.isEmpty
    }

    private var currentQuery: CardQuery {
        CardQuery(
            text: searchQuery,
            sort: sort,
            filter: filter,
            offset: 0,
            limit: pageSize
        )
    }

    // MARK: - Lifecycle

    public func onAppear() async {
        currency = sessionRepository.currency
        await loadOrSeed()
        // Fire-and-forget FX refresh — rows + total re-read `exchangeRate`
        // once the repo bumps its cache.
        if let exchangeRateRepository {
            Task { try? await exchangeRateRepository.refresh() }
        }
        // Pull fresh backend prices so anything /v1/prices has shows up here too
        // — not only after visiting Dashboard. Best-effort + non-blocking.
        if let syncPrices {
            Task { [weak self] in
                _ = try? await syncPrices.execute(progress: nil)
                await self?.loadPrices()
            }
        }
        startPriceStatusPolling()
    }

    /// Loads the first page from the local catalogue. The catalogue is NOT
    /// auto-seeded — the Collection starts empty and fills as the user adds /
    /// imports cards (import persists each resolved card here).
    public func loadOrSeed() async {
        status = .loading

        do {
            try await refreshFirstPage()
            availableSetCodes = try await cardRepository.availableSetCodes()
            await loadPrices()
            status = .idle
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    /// Fetches the first page given the current query/sort/filter.
    /// Used after any change to text/sort/filter. Does NOT reload prices —
    /// the price map covers the whole store and is independent of the query,
    /// so search/sort/filter stay cheap (and don't shift values mid-search).
    public func refreshFirstPage() async throws {
        let query = currentQuery
        let loaded = try await cardRepository.refresh(query)
        cards = loaded
        matchingCount = try await cardRepository.count(matching: query)
        totalCount = try await cardRepository.totalCount()
    }

    /// Loads the latest price per card for the preferred source. The map
    /// covers the whole store, so paged-in rows are already priced.
    private func loadPrices() async {
        guard let priceRepository else { return }
        let source = sessionRepository.preferredPriceSource
        let latest = (try? await priceRepository.latestByCard(source: source)) ?? [:]
        priceMap = latest.mapValues(\.retail)
    }

    // MARK: - Price status polling

    /// Polls `/v1/prices/status` while any owned card is still being priced,
    /// backing off 3s → 30s. Updates `fetchingCardIDs` / `noDataCardIDs` and
    /// re-reads the local price store so prices that land mid-poll appear.
    public func startPriceStatusPolling() {
        guard priceStatusSource != nil else { return }
        pollTask?.cancel()
        pollTask = Task { @MainActor [weak self] in
            guard let self else { return }
            var delay: Duration = .seconds(3)
            var iterations = 0
            while !Task.isCancelled, iterations < 40 {
                await self.refreshPriceStatus()
                if self.fetchingCardIDs.isEmpty { break }
                try? await Task.sleep(for: delay)
                delay = min(.seconds(30), delay * 2)
                iterations += 1
            }
        }
    }

    public func stopPriceStatusPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func refreshPriceStatus() async {
        guard let priceStatusSource else { return }
        await loadPrices()
        guard let status = try? await priceStatusSource.status() else { return }
        let unpriced = Set(cards.map(\.id)).filter { priceMap[$0] == nil }
        noDataCardIDs = unpriced.intersection(status.noData)
        fetchingCardIDs = unpriced.subtracting(status.noData)
    }

    /// Appends the next page to the existing card list. No-op when
    /// `hasMore` is false.
    public func loadMoreIfNeeded() async {
        guard hasMore, status == .idle else { return }
        status = .loadingMore
        do {
            var next = currentQuery
            next.offset = cards.count
            let page = try await cardRepository.refresh(next)
            cards.append(contentsOf: page)
            status = .idle
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    /// Debounced re-query for the search field / sort / filter. Coalesces a
    /// burst of changes into one fetch ~300ms after the last keystroke, so the
    /// main thread stays free while typing.
    public func search() async {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let self else { return }
            do {
                try await self.refreshFirstPage()
            } catch {
                self.status = .error(message: error.localizedDescription)
            }
        }
    }

    /// Drives the swipe-down refresh control on the Collection list.
    /// Re-runs the current query against the local catalogue, refreshes the
    /// cached set-code list, and reconciles prices with the backend.
    ///
    /// The price reconcile matters: the backend prices newly-added cards
    /// asynchronously (enqueue → on-demand ingest, minutes later), and the
    /// status poll loop eventually stops (iteration cap) and is cancelled when
    /// the user leaves the tab. Without re-pulling here, a card that finished
    /// pricing after the loop ended stays stuck on "Fetching…" until relaunch.
    public func pullToRefresh() async {
        do {
            try await refreshFirstPage()
            availableSetCodes = try await cardRepository.availableSetCodes()
        } catch {
            status = .error(message: error.localizedDescription)
            return
        }
        if let syncPrices {
            _ = try? await syncPrices.execute(progress: nil)
        }
        await loadPrices()
        startPriceStatusPolling()
    }

    public func setSort(_ sort: CardSortOption) {
        self.sort = sort
        Task { await search() }
    }

    public func applyFilter(_ filter: CardFilter) {
        self.filter = filter
        Task { await search() }
    }

    public func clearFilter() {
        applyFilter(.empty)
    }

    // MARK: - Undo state

    public private(set) var recentlyRemoved: Card?

    @ObservationIgnored private var undoTimer: Task<Void, Never>?

    /// Removes a single card from the local catalogue (driven by the
    /// row's trailing swipe action). Bumps the in-memory list + the
    /// matching-count label and stashes the removed card so the user
    /// can undo within 5 seconds.
    public func removeCard(id: UUID) async {
        guard let card = cards.first(where: { $0.id == id }) else { return }
        do {
            try await cardRepository.delete(id: id)
            cards.removeAll { $0.id == id }
            matchingCount = try await cardRepository.count(matching: currentQuery)
            totalCount = try await cardRepository.totalCount()
            scheduleUndo(for: card)
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    /// Re-inserts the most recently removed card. No-op when the undo
    /// window has expired.
    public func undoRemoveCard() async {
        guard let card = recentlyRemoved else { return }
        recentlyRemoved = nil
        undoTimer?.cancel()
        undoTimer = nil
        do {
            try await cardRepository.save([card])
            try await refreshFirstPage()
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    /// Drops the pending undo (called when the toast times out or is
    /// dismissed).
    public func dismissUndo() {
        recentlyRemoved = nil
        undoTimer?.cancel()
        undoTimer = nil
    }

    private func scheduleUndo(for card: Card) {
        recentlyRemoved = card
        undoTimer?.cancel()
        undoTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            self?.recentlyRemoved = nil
            self?.undoTimer = nil
        }
    }

}

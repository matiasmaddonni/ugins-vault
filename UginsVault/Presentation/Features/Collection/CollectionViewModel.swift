//
//  CollectionViewModel.swift
//  UginsVault — Presentation: Collection
//
//  Drives the Collection tab. Reads cards from a `CardRepository`,
//  reports a loading / seeding / error state, owns sort + filter +
//  pagination, and on first launch kicks the `SeedCatalogueUseCase` to
//  populate an empty catalogue.
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
        case seeding(savedSoFar: Int)
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

    @ObservationIgnored private let sessionRepository: SessionRepository
    @ObservationIgnored private let cardRepository: CardRepository
    @ObservationIgnored private let seedCatalogue: SeedCatalogueUseCase

    /// Scryfall search to use when seeding an empty catalogue on first
    /// launch. Foundations ships ~310 cards.
    @ObservationIgnored private let seedQuery: String

    /// Page size for pagination.
    @ObservationIgnored private let pageSize: Int

    // MARK: - Init

    public init(
        sessionRepository: SessionRepository,
        cardRepository: CardRepository,
        seedCatalogue: SeedCatalogueUseCase,
        seedQuery: String = "set:fdn",
        pageSize: Int = 50
    ) {
        self.sessionRepository = sessionRepository
        self.cardRepository = cardRepository
        self.seedCatalogue = seedCatalogue
        self.seedQuery = seedQuery
        self.pageSize = pageSize
        self.currency = sessionRepository.currency
    }

    // MARK: - Derived

    public var hasMore: Bool {
        cards.count < matchingCount
    }

    public var totalValueUSD: Decimal {
        cards.reduce(.zero) { partial, card in
            partial + (card.prices.usdPrice(for: .nonfoil) ?? .zero)
        }
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
    }

    /// Pulls the latest first-page slice from storage. If the catalogue
    /// is empty, kicks the seed flow before re-reading.
    public func loadOrSeed() async {
        status = .loading

        do {
            let total = try await cardRepository.totalCount()
            if total == 0 {
                try await seed()
            }
            try await refreshFirstPage()
            availableSetCodes = try await cardRepository.availableSetCodes()
            status = .idle
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    /// Fetches the first page given the current query/sort/filter.
    /// Used after any change to text/sort/filter.
    public func refreshFirstPage() async throws {
        let query = currentQuery
        let loaded = try await cardRepository.refresh(query)
        cards = loaded
        matchingCount = try await cardRepository.count(matching: query)
        totalCount = try await cardRepository.totalCount()
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

    /// Re-runs the current query after the user touches the search field,
    /// the sort picker, or the filter sheet.
    public func search() async {
        do {
            try await refreshFirstPage()
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    /// Drives the swipe-down refresh control on the Collection list.
    /// Re-runs the current query against the local catalogue and refreshes
    /// the cached set-code list — does NOT re-seed from Scryfall (use
    /// `reseed()` for a full reset).
    public func pullToRefresh() async {
        do {
            try await refreshFirstPage()
            availableSetCodes = try await cardRepository.availableSetCodes()
        } catch {
            status = .error(message: error.localizedDescription)
        }
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

    /// Removes a single card from the local catalogue (driven by the
    /// row's trailing swipe action). Bumps the in-memory list + the
    /// matching-count label.
    public func removeCard(id: UUID) async {
        do {
            try await cardRepository.delete(id: id)
            cards.removeAll { $0.id == id }
            matchingCount = try await cardRepository.count(matching: currentQuery)
            totalCount = try await cardRepository.totalCount()
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    /// Wipes the local catalogue + re-seeds from Scryfall.
    public func reseed() async {
        status = .loading
        do {
            try await cardRepository.deleteAll()
            try await seed()
            try await refreshFirstPage()
            availableSetCodes = try await cardRepository.availableSetCodes()
            status = .idle
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    // MARK: - Private

    private func seed() async throws {
        try await seedCatalogue.execute(query: seedQuery) { [weak self] progress in
            guard let self else { return }
            self.status = .seeding(savedSoFar: progress.savedCount)
        }
    }
}

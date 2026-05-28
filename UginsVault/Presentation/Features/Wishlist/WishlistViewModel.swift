//
//  WishlistViewModel.swift
//  UginsVault — Presentation: Wishlist
//
//  Drives the Wishlist screen. Lists wishlisted cards from
//  `WishlistRepository` (via use cases) and powers the add-sheet's
//  debounced Scryfall search. Prices render in the active display
//  currency with the FX rate, matching the rest of the app.
//

import Foundation
import Observation

@MainActor
@Observable
public final class WishlistViewModel {

    // MARK: - Status

    public enum Status: Equatable {
        case idle
        case loading
        case error(message: String)
    }

    // MARK: - Observed state

    public private(set) var items: [WishlistItem] = []
    public private(set) var status: Status = .idle
    public private(set) var currency: Currency

    // Add-sheet search state
    public var isPresentingAdd: Bool = false
    public var searchQuery: String = ""
    public private(set) var searchResults: [Card] = []
    public private(set) var isSearching: Bool = false

    // MARK: - Dependencies

    @ObservationIgnored private let getWishlist: GetWishlistUseCase
    @ObservationIgnored private let addToWishlist: AddToWishlistUseCase
    @ObservationIgnored private let removeFromWishlist: RemoveFromWishlistUseCase
    @ObservationIgnored private let scryfallClient: any ScryfallClientProtocol
    @ObservationIgnored private let sessionRepository: SessionStateStore
    @ObservationIgnored private let exchangeRateRepository: ExchangeRateStore?

    @ObservationIgnored private var searchTask: Task<Void, Never>?

    // MARK: - Init

    public init(
        getWishlist: GetWishlistUseCase,
        addToWishlist: AddToWishlistUseCase,
        removeFromWishlist: RemoveFromWishlistUseCase,
        scryfallClient: any ScryfallClientProtocol,
        sessionRepository: SessionStateStore,
        exchangeRateRepository: ExchangeRateStore? = nil
    ) {
        self.getWishlist = getWishlist
        self.addToWishlist = addToWishlist
        self.removeFromWishlist = removeFromWishlist
        self.scryfallClient = scryfallClient
        self.sessionRepository = sessionRepository
        self.exchangeRateRepository = exchangeRateRepository
        self.currency = sessionRepository.currency
    }

    // MARK: - Derived

    public var isEmpty: Bool { items.isEmpty }

    /// USD→display-currency rate for `CurrencyFormatter`.
    public var exchangeRate: ExchangeRate? {
        exchangeRateRepository?.rate(toQuote: currency)
    }

    /// `true` when a search result is already on the wishlist — drives
    /// the "added" checkmark in the add sheet.
    public func isInWishlist(_ id: UUID) -> Bool {
        items.contains { $0.id == id }
    }

    // MARK: - Lifecycle

    public func onAppear() async {
        currency = sessionRepository.currency
        await load()
        if let exchangeRateRepository {
            Task { try? await exchangeRateRepository.refresh() }
        }
    }

    public func load() async {
        status = .loading
        do {
            items = try await getWishlist.execute()
            status = .idle
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    // MARK: - Add sheet

    public func presentAdd() {
        searchQuery = ""
        searchResults = []
        isSearching = false
        isPresentingAdd = true
    }

    /// Debounced Scryfall search. Maps results to `Card` so the add-sheet
    /// rows can reuse the catalogue rendering + price snapshot.
    public func search() {
        searchTask?.cancel()
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(300))
            if Task.isCancelled { return }
            do {
                let list = try await scryfallClient.searchCards(query: trimmed, page: 1)
                if Task.isCancelled { return }
                self.searchResults = list.data.compactMap { Card(from: $0) }
            } catch {
                if !Task.isCancelled { self.searchResults = [] }
            }
            self.isSearching = false
        }
    }

    public func add(_ card: Card) async {
        do {
            try await addToWishlist.execute(card: card)
            await load()
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    public func remove(id: UUID) async {
        do {
            try await removeFromWishlist.execute(id: id)
            await load()
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }
}

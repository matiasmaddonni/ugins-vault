//
//  CollectionViewModel.swift
//  UginsVault — Presentation: Collection
//
//  Drives the Collection tab. Reads cards from a `CardRepository`,
//  reports a loading / seeding / error state, and on first launch
//  kicks the `SeedCatalogueUseCase` to populate an empty catalogue.
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
        case seeding(savedSoFar: Int)
        case error(message: String)
    }

    // MARK: - Observed state

    public private(set) var cards: [Card] = []
    public private(set) var cardCount: Int = 0
    public private(set) var status: Status = .idle
    public private(set) var currency: Currency

    public var searchQuery: String = ""

    // MARK: - Dependencies

    @ObservationIgnored private let sessionRepository: SessionRepository
    @ObservationIgnored private let cardRepository: CardRepository
    @ObservationIgnored private let seedCatalogue: SeedCatalogueUseCase

    /// Scryfall search to use when seeding an empty catalogue on first
    /// launch. Foundations (core 2024) ships ~310 cards — good size for
    /// a demo without hammering Scryfall.
    @ObservationIgnored private let seedQuery: String

    // MARK: - Init

    public init(
        sessionRepository: SessionRepository,
        cardRepository: CardRepository,
        seedCatalogue: SeedCatalogueUseCase,
        seedQuery: String = "set:fdn"
    ) {
        self.sessionRepository = sessionRepository
        self.cardRepository = cardRepository
        self.seedCatalogue = seedCatalogue
        self.seedQuery = seedQuery
        self.currency = sessionRepository.currency
    }

    // MARK: - Computed

    public var totalValueUSD: Decimal {
        cards.reduce(.zero) { partial, card in
            partial + (card.prices.usdPrice(for: .nonfoil) ?? .zero)
        }
    }

    // MARK: - Lifecycle

    public func onAppear() async {
        currency = sessionRepository.currency
        await loadOrSeed()
    }

    /// Pulls the latest card list from storage. If the catalogue is empty,
    /// kicks the seed flow (Scryfall search → SwiftData) before re-reading.
    public func loadOrSeed() async {
        status = .loading

        do {
            let total = try await cardRepository.totalCount()
            if total == 0 {
                try await seed()
            }
            try await refreshCards()
            status = .idle
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    public func refreshCards() async throws {
        let loaded = try await cardRepository.refresh(query: searchQuery)
        let total = try await cardRepository.totalCount()
        cards = loaded
        cardCount = total
    }

    public func search() async {
        do {
            try await refreshCards()
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    /// Wipes the local catalogue + re-seeds from Scryfall. Used by
    /// Settings "Reset catalogue" later; exposed here for the empty-state
    /// "Retry" affordance.
    public func reseed() async {
        status = .loading
        do {
            try await cardRepository.deleteAll()
            try await seed()
            try await refreshCards()
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

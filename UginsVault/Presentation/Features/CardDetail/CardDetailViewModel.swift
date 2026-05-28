//
//  CardDetailViewModel.swift
//  UginsVault — Presentation: CardDetail
//
//  Holds the currently-displayed printing plus the list of *other*
//  printings of the same oracle, fetched lazily from Scryfall via
//  `/cards/search?q=oracleid:…`. Tapping another printing swaps it
//  into the same detail screen without pushing a new navigation entry.
//

import Foundation
import Observation

@MainActor
@Observable
public final class CardDetailViewModel {

    public enum OtherPrintingsStatus: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    // MARK: - Observed state

    public private(set) var card: Card
    public private(set) var otherPrintings: [Card] = []
    public private(set) var status: OtherPrintingsStatus = .idle
    public private(set) var availableStacks: [Stack] = []
    public private(set) var lastAddedStackName: String?
    public let displayCurrency: Currency

    /// Resolved price for the hero block — from the local price store
    /// (the backend). `nil` when the card isn't priced.
    public private(set) var resolvedPrice: LatestPriceUseCase.Resolved?

    /// Why the retail value is (or isn't) shown: a real price, still being
    /// fetched server-side, or confirmed to have no price data.
    public enum PriceState: Equatable { case priced, fetching, noData }
    public private(set) var priceState: PriceState = .fetching

    /// 30-day rolling history for the preferred source. Drives the
    /// mini sparkline on Card Detail. Oldest first.
    public private(set) var priceHistory: [PriceSnapshot] = []

    /// Source the user picked in Settings — mirrored here so reads
    /// are observable without a separate hop into SessionStateStore.
    public private(set) var preferredSource: PriceSource

    // MARK: - Dependencies

    @ObservationIgnored private let client: any ScryfallClientProtocol
    @ObservationIgnored private let stackRepository: StackRepository?
    @ObservationIgnored private let addCardToStack: AddCardToStackUseCase?
    @ObservationIgnored private let cardRepository: CardRepository?
    @ObservationIgnored private let priceRepository: PriceRepository?
    @ObservationIgnored private let latestPriceUseCase: LatestPriceUseCase?
    @ObservationIgnored private let priceStatusSource: PriceStatusSource?
    @ObservationIgnored private let sessionRepository: SessionStateStore?

    // MARK: - Init

    public init(
        card: Card,
        displayCurrency: Currency,
        client: any ScryfallClientProtocol,
        stackRepository: StackRepository? = nil,
        addCardToStack: AddCardToStackUseCase? = nil,
        cardRepository: CardRepository? = nil,
        priceRepository: PriceRepository? = nil,
        latestPriceUseCase: LatestPriceUseCase? = nil,
        priceStatusSource: PriceStatusSource? = nil,
        sessionRepository: SessionStateStore? = nil
    ) {
        self.card = card
        self.displayCurrency = displayCurrency
        self.client = client
        self.stackRepository = stackRepository
        self.addCardToStack = addCardToStack
        self.cardRepository = cardRepository
        self.priceRepository = priceRepository
        self.latestPriceUseCase = latestPriceUseCase
        self.priceStatusSource = priceStatusSource
        self.sessionRepository = sessionRepository
        self.preferredSource = sessionRepository?.preferredPriceSource ?? .cardkingdom
    }

    // MARK: - Pricing

    /// Resolves the best available retail price + pulls 30-day
    /// history for the preferred source. Fires from the view's
    /// `.task` block alongside `refreshCardIfStale` and
    /// `loadOtherPrintings`.
    public func loadPricing() async {
        if let session = sessionRepository {
            preferredSource = session.preferredPriceSource
        }
        if let useCase = latestPriceUseCase {
            resolvedPrice = await useCase.execute(
                card: card,
                preferred: preferredSource
            )
        }
        if let repo = priceRepository {
            let cutoff = Date().addingTimeInterval(-30 * 24 * 60 * 60)
            priceHistory = (try? await repo.history(
                cardID: card.id,
                source: preferredSource,
                since: cutoff
            )) ?? []
        }
        await resolvePriceState()
    }

    /// Classifies the missing-price case so the view can say *why*: still being
    /// fetched server-side (`fetching`) vs. MTGJSON has no price (`noData`).
    private func resolvePriceState() async {
        if resolvedPrice != nil {
            priceState = .priced
            return
        }
        guard let status = try? await priceStatusSource?.status() else {
            priceState = .fetching
            return
        }
        priceState = status.noData.contains(card.id) ? .noData : .fetching
    }

    // MARK: - Stale-data backfill

    /// If the displayed card lacks every image URL (a row that pre-dates
    /// the DFC `card_faces` mapper fix), refetch it from Scryfall by id,
    /// persist the refreshed row, and swap it in so the hero image
    /// stops being a placeholder.
    public func refreshCardIfStale() async {
        guard !hasAnyImage(card) else { return }
        do {
            let dto = try await client.card(id: card.id)
            guard let refreshed = Card(from: dto) else { return }
            try? await cardRepository?.save([refreshed])
            self.card = refreshed
        } catch {
            // Silent — placeholder image is acceptable fallback.
        }
    }

    private func hasAnyImage(_ card: Card) -> Bool {
        let urls = [
            card.images.small,
            card.images.normal,
            card.images.large,
            card.images.png,
            card.images.artCrop,
            card.images.borderCrop
        ]
        return urls.contains(where: { $0 != nil })
    }

    // MARK: - Intents

    /// Loads every other printing of this card's oracle id. Idempotent:
    /// once `.loaded` (or `.failed`), repeat calls are no-ops until the
    /// user swaps to a different card.
    public func loadOtherPrintings() async {
        guard status == .idle else { return }
        status = .loading
        do {
            let list = try await client.searchCards(
                // `unique:prints` — without it Scryfall collapses to one card
                // per oracle id, so the only hit is the card we're showing and
                // the list comes back empty. This returns every printing.
                query: "oracleid:\(card.oracleID.uuidString.lowercased()) unique:prints",
                page: 1
            )
            let mapped = list.data.compactMap(Card.init(from:))
            // Exclude the printing we're currently showing.
            otherPrintings = mapped.filter { $0.id != card.id }
            status = .loaded
        } catch {
            otherPrintings = []
            status = .failed
        }
    }

    /// Swaps the displayed printing without pushing a new navigation.
    /// Triggers a fresh load of the other-printings list + pricing.
    public func switchTo(_ printing: Card) {
        guard printing.id != card.id else { return }
        card = printing
        otherPrintings = []
        status = .idle
        resolvedPrice = nil
        priceHistory = []
        Task { await loadOtherPrintings() }
        Task { await loadPricing() }
    }

    // MARK: - Add to stack

    /// Pulls the user's stacks so the "Add to stack" sheet can pick one.
    public func loadAvailableStacks() async {
        guard let stackRepository else { return }
        do {
            availableStacks = try await stackRepository.refresh()
        } catch {
            availableStacks = []
        }
    }

    /// Inserts (or increments) a `CollectionItem` row for the displayed
    /// card in the chosen stack. Surfaces a one-shot toast string the
    /// view can show before clearing it via `dismissAddToStackToast()`.
    public func addCard(to stackID: UUID) async {
        guard let addCardToStack else { return }
        do {
            try await addCardToStack.execute(cardID: card.id, stackID: stackID)
            if let stack = availableStacks.first(where: { $0.id == stackID }) {
                lastAddedStackName = stack.name
            }
        } catch {
            lastAddedStackName = nil
        }
    }

    public func dismissAddToStackToast() {
        lastAddedStackName = nil
    }
}

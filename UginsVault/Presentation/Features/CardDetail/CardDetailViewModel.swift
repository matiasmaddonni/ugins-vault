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
    public let displayCurrency: Currency

    // MARK: - Dependencies

    @ObservationIgnored private let client: any ScryfallClientProtocol

    // MARK: - Init

    public init(
        card: Card,
        displayCurrency: Currency,
        client: any ScryfallClientProtocol
    ) {
        self.card = card
        self.displayCurrency = displayCurrency
        self.client = client
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
                query: "oracleid:\(card.oracleID.uuidString.lowercased())",
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
    /// Triggers a fresh load of the other-printings list.
    public func switchTo(_ printing: Card) {
        guard printing.id != card.id else { return }
        card = printing
        otherPrintings = []
        status = .idle
        Task { await loadOtherPrintings() }
    }
}

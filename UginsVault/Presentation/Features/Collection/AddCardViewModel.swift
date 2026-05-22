//
//  AddCardViewModel.swift
//  UginsVault — Presentation: Collection
//
//  Drives the "Add card" search sheet: a debounced Scryfall search that maps
//  hits to `Card`. Tapping a result opens Card Detail, which owns the actual
//  "Add to stack" action (so this stays a thin search surface).
//

import Foundation
import Observation

@MainActor
@Observable
public final class AddCardViewModel {

    public enum Status: Equatable {
        case idle
        case searching
        case empty
        case error(String)
    }

    public private(set) var results: [Card] = []
    public private(set) var status: Status = .idle
    public var query: String = ""

    @ObservationIgnored private let scryfallClient: any ScryfallClientProtocol
    @ObservationIgnored private var searchTask: Task<Void, Never>?

    public init(scryfallClient: any ScryfallClientProtocol) {
        self.scryfallClient = scryfallClient
    }

    /// Debounced — call on every keystroke. Searches ~350ms after the last
    /// change; queries under 2 chars clear the list.
    public func onQueryChange() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            status = .idle
            return
        }
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled, let self else { return }
            await self.runSearch(trimmed)
        }
    }

    /// Runs the search immediately (no debounce). Internal so tests can drive it.
    func runSearch(_ trimmed: String) async {
        status = .searching
        do {
            let list = try await scryfallClient.searchCards(query: trimmed, page: 1)
            let cards = list.data.compactMap(Card.init(from:))
            guard !Task.isCancelled else { return }
            results = cards
            status = cards.isEmpty ? .empty : .idle
        } catch {
            results = []
            status = .error(String(localized: "Search failed — try again."))
        }
    }
}

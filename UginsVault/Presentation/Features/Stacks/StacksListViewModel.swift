//
//  StacksListViewModel.swift
//  UginsVault — Presentation: Stacks
//
//  Drives the Stacks tab. Reads the user's `Stack`s from
//  `StackRepository`, hydrates per-stack card counts via
//  `CollectionItemRepository`, exposes a kind filter, and computes the
//  summary line shown above the list (N stacks · N cards · $X — always
//  aggregated across ALL stacks, not the filtered slice).
//
//  v0.3 ships value display as "$0" everywhere — wiring per-stack price
//  totals lives in a later milestone when `CollectionItem` joins on
//  `Card.prices`.
//

import Foundation
import Observation

@MainActor
@Observable
public final class StacksListViewModel {

    // MARK: - Status

    public enum Status: Equatable {
        case idle
        case loading
        case error(message: String)
    }

    // MARK: - Filter

    public enum Filter: Equatable, Hashable {
        case all
        case kind(StackKind)
    }

    // MARK: - Observed state

    /// Every stack the user owns. Drives the summary line aggregation.
    public private(set) var allStacks: [Stack] = []

    /// The slice currently shown after `filter` is applied.
    public private(set) var visibleStacks: [Stack] = []

    /// Map of `Stack.id` → total card count (summed quantity).
    public private(set) var cardCounts: [UUID: Int] = [:]

    public private(set) var status: Status = .idle

    public var filter: Filter = .all {
        didSet { recomputeVisible() }
    }

    // MARK: - Create-sheet plumbing

    /// Set by the view layer to drive `.sheet(isPresented:)` for the
    /// Create Stack flow.
    public var isPresentingCreate: Bool = false

    // MARK: - Dependencies

    @ObservationIgnored private let stackRepository: StackRepository
    @ObservationIgnored private let itemRepository: CollectionItemRepository
    @ObservationIgnored private let sessionRepository: SessionRepository

    // MARK: - Init

    public init(
        stackRepository: StackRepository,
        itemRepository: CollectionItemRepository,
        sessionRepository: SessionRepository
    ) {
        self.stackRepository = stackRepository
        self.itemRepository = itemRepository
        self.sessionRepository = sessionRepository
    }

    // MARK: - Derived

    public var currency: Currency { sessionRepository.currency }

    public var totalStackCount: Int { allStacks.count }

    public var totalCardCount: Int {
        cardCounts.values.reduce(0, +)
    }

    public var totalValue: Decimal {
        // v0.3 stub — collection items don't yet carry a USD per-row
        // price (we'd need to join on `Card.prices.usd`). Real wiring
        // lands when we surface owned-printing pricing.
        .zero
    }

    public var formattedTotalValue: String {
        CurrencyFormatter.format(totalValue, currency: currency)
    }

    public var isEmpty: Bool { allStacks.isEmpty }

    public var hasActiveFilter: Bool { filter != .all }

    public var availableFilters: [Filter] {
        [.all] + StackKind.allCases.map(Filter.kind)
    }

    // MARK: - Lifecycle

    public func onAppear() async {
        await refresh()
    }

    public func refresh() async {
        status = .loading
        do {
            let stacks = try await stackRepository.refresh()
            self.allStacks = stacks

            // Hydrate counts in one fetch — `allItems()` is cheap for the
            // sizes we expect locally.
            let items = try await itemRepository.allItems()
            var counts: [UUID: Int] = [:]
            for item in items {
                counts[item.stackID, default: 0] += item.quantity
            }
            self.cardCounts = counts

            recomputeVisible()
            self.status = .idle
        } catch {
            self.status = .error(message: error.localizedDescription)
        }
    }

    // MARK: - Filter

    public func applyFilter(_ filter: Filter) {
        self.filter = filter
    }

    // MARK: - Create

    public func presentCreate() {
        isPresentingCreate = true
    }

    public func dismissCreate() {
        isPresentingCreate = false
    }

    /// Persists a new stack and refreshes the visible list. The next
    /// available `sortOrder` is auto-assigned (max + 1).
    public func createStack(
        name: String,
        kind: StackKind,
        format: Format? = nil,
        colors: Set<ManaColor> = [],
        commander: String? = nil,
        person: String? = nil
    ) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let nextOrder = (allStacks.map(\.sortOrder).max() ?? -1) + 1
        let stack = Stack(
            name: trimmed,
            kind: kind,
            sortOrder: nextOrder,
            format: kind == .deck ? format : nil,
            colors: kind == .deck ? colors : [],
            commander: kind == .deck ? commander : nil,
            person: kind == .loan ? person : nil,
            since: kind == .loan ? Date() : nil
        )

        do {
            try await stackRepository.save(stack)
            await refresh()
            dismissCreate()
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    public func cardCount(for stack: Stack) -> Int {
        cardCounts[stack.id] ?? 0
    }

    public func displayValue(for stack: Stack) -> String? {
        // v0.3 stub — see `totalValue` note above. Suppressing the
        // per-row figure until the price-join lands keeps the row from
        // showing a misleading $0.00 everywhere.
        nil
    }

    // MARK: - Private

    private func recomputeVisible() {
        switch filter {
        case .all:
            visibleStacks = allStacks
        case .kind(let kind):
            visibleStacks = allStacks.filter { $0.kind == kind }
        }
    }
}

// MARK: - Filter label helpers

extension StacksListViewModel.Filter: Identifiable {

    public var id: String {
        switch self {
        case .all:            return "all"
        case .kind(let kind): return kind.rawValue
        }
    }

    /// Plural label used on the chip row. "All" / "Decks" / "Binders" / ...
    public var chipLabel: String {
        switch self {
        case .all:                return String(localized: "All")
        case .kind(.deck):        return String(localized: "Decks")
        case .kind(.binder):      return String(localized: "Binders")
        case .kind(.loan):        return String(localized: "Loans")
        case .kind(.sale):        return String(localized: "Sales")
        case .kind(.showcase):    return String(localized: "Showcase")
        case .kind(.inbox):       return String(localized: "Unsorted")
        }
    }

    public var iconName: String? {
        switch self {
        case .all:            return nil
        case .kind(let kind): return kind.iconName
        }
    }
}

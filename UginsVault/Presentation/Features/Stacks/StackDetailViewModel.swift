//
//  StackDetailViewModel.swift
//  UginsVault — Presentation: Stacks
//
//  Drives the per-stack detail screen. Receives an initial `Stack`
//  snapshot from the list, loads its `CollectionItem` rows from
//  `CollectionItemRepository`, and computes the hero-card counts
//  (total quantity + unique-row count).
//
//  v0.3 ships actions as stubs — the action bar buttons fire `onAction`
//  through the view but no concrete flow is wired yet (per the brief's
//  v0.3 scope decision).
//

import Foundation
import Observation

@MainActor
@Observable
public final class StackDetailViewModel {

    // MARK: - Status

    public enum Status: Equatable {
        case idle
        case loading
        case error(message: String)
    }

    // MARK: - Observed state

    public private(set) var stack: Stack
    public private(set) var items: [CollectionItem] = []
    public private(set) var cardsByID: [UUID: Card] = [:]
    public private(set) var cardCount: Int = 0
    public private(set) var uniqueCount: Int = 0
    public private(set) var status: Status = .idle

    /// Latest retail price per card from the local store (backend) for the
    /// preferred source. Cards without data don't contribute.
    public private(set) var priceMap: [UUID: Decimal] = [:]

    // MARK: - Import sheet

    public var isPresentingImport: Bool = false

    // MARK: - Delete

    public var isPresentingDeleteConfirm: Bool = false
    public private(set) var didDelete: Bool = false

    // MARK: - Commander picker

    public var isPresentingCommanderPicker: Bool = false

    // MARK: - Dependencies

    @ObservationIgnored private let itemRepository: CollectionItemRepository
    @ObservationIgnored private let cardRepository: CardRepository?
    @ObservationIgnored private let stackRepository: StackRepository?
    @ObservationIgnored private let sessionRepository: SessionRepository
    @ObservationIgnored private let exchangeRateRepository: ExchangeRateRepository?
    @ObservationIgnored private let priceRepository: PriceRepository?
    @ObservationIgnored private let importCoordinator: ImportCoordinator?
    @ObservationIgnored private let scryfallClient: (any ScryfallClientProtocol)?

    // MARK: - Init

    public init(
        stack: Stack,
        itemRepository: CollectionItemRepository,
        sessionRepository: SessionRepository,
        cardRepository: CardRepository? = nil,
        stackRepository: StackRepository? = nil,
        exchangeRateRepository: ExchangeRateRepository? = nil,
        priceRepository: PriceRepository? = nil,
        importCoordinator: ImportCoordinator? = nil,
        scryfallClient: (any ScryfallClientProtocol)? = nil
    ) {
        self.stack = stack
        self.itemRepository = itemRepository
        self.cardRepository = cardRepository
        self.stackRepository = stackRepository
        self.sessionRepository = sessionRepository
        self.exchangeRateRepository = exchangeRateRepository
        self.priceRepository = priceRepository
        self.importCoordinator = importCoordinator
        self.scryfallClient = scryfallClient
    }

    // MARK: - Card lookup

    public func card(for item: CollectionItem) -> Card? {
        cardsByID[item.cardID]
    }

    // MARK: - Derived

    public var currency: Currency { sessionRepository.currency }

    public var isEmpty: Bool { items.isEmpty }

    public var heroSubtitle: String {
        switch stack.kind {
        case .deck:
            // Prefer the resolved commander card name when set, then
            // the manual `stack.commander` string. Format already shows
            // up in the badge — don't repeat it here.
            if let commanderCard, !commanderCard.name.isEmpty {
                return commanderCard.name
            }
            if let commander = stack.commander, !commander.isEmpty {
                return commander
            }
            return ""
        case .loan:
            if let person = stack.person, !person.isEmpty {
                return String(localized: "On loan to \(person)")
            }
            return StackKind.loan.displayLabel
        default:
            return stack.kind.displayLabel
        }
    }

    /// `Card` matching `stack.commanderCardID`, when both are set + the
    /// card hydrated locally.
    public var commanderCard: Card? {
        guard let id = stack.commanderCardID else { return nil }
        return cardsByID[id]
    }

    /// Big art URL used by `StackHeroCard` when a commander is pinned.
    public var commanderArtURL: URL? {
        commanderCard?.images.artCrop
            ?? commanderCard?.images.normal
            ?? commanderCard?.images.large
    }

    // MARK: - Commander (validation + detection)

    public var isCommanderDeck: Bool {
        stack.kind == .deck && stack.format == .commander
    }

    /// Items whose joined card is a legendary creature — commander candidates.
    public var commanderCandidates: [CollectionItem] {
        items.filter { item in
            guard let card = cardsByID[item.cardID] else { return false }
            let type = card.typeLine.lowercased()
            return type.contains("legendary") && type.contains("creature")
        }
    }

    /// Non-nil when a Commander deck breaks the 100-card singleton rule
    /// (1 commander + 99). Drives a banner on the detail screen.
    public var commanderValidation: String? {
        guard isCommanderDeck else { return nil }
        var issues: [String] = []
        if cardCount != 100 {
            issues.append(String(localized: "needs 100 cards (has \(cardCount))"))
        }
        if stack.commanderCardID == nil {
            issues.append(String(localized: "no commander set — pick one"))
        }
        guard !issues.isEmpty else { return nil }
        return String(localized: "Commander deck ") + issues.joined(separator: " · ")
    }

    /// Decklist text — used by Edit list (pre-populates the import
    /// sheet) and by Export (share sheet content). Format mirrors
    /// Moxfield's `N Name (SET) NUMBER`.
    public var serializedCardList: String {
        items.map { item in
            let card = cardsByID[item.cardID]
            let name = card?.name ?? "Unknown card"
            let suffix: String
            if let card {
                suffix = " (\(card.setCode.uppercased())) \(card.collectorNumber)"
            } else {
                suffix = ""
            }
            return "\(item.quantity) \(name)\(suffix)"
        }
        .joined(separator: "\n")
    }

    /// Sum of USD prices × quantity across every item in the stack
    /// whose joined `Card` has a usable price. Items without a hydrated
    /// Card or without prices simply don't contribute.
    public var totalValue: Decimal {
        items.reduce(.zero) { running, item in
            guard let price = priceMap[item.cardID] else { return running }
            return running + (price * Decimal(item.quantity))
        }
    }

    /// USD→display-currency rate for `CurrencyFormatter`. `nil` until the
    /// FX repo's first refresh.
    public var exchangeRate: ExchangeRate? {
        exchangeRateRepository?.rate(toQuote: currency)
    }

    public var formattedTotalValue: String {
        CurrencyFormatter.format(totalValue, currency: currency, rate: exchangeRate)
    }

    /// Per-stack analytics for the Statistics screen, computed from the
    /// already-loaded rows / cards / prices — no extra fetch.
    public var statistics: StackStatistics {
        StackStatistics.make(
            items: items,
            cardsByID: cardsByID,
            priceMap: priceMap,
            commanderCardID: stack.commanderCardID
        )
    }

    /// Kind-aware action labels rendered in `StackActionBar`.
    /// Per the brief §8.2.
    public var actions: [StackAction] {
        switch stack.kind {
        case .deck:
            return [
                .init(id: "edit_list",     label: String(localized: "Edit list"),     icon: "list.bullet.rectangle"),
                .init(id: "export",        label: String(localized: "Export"),        icon: "square.and.arrow.up"),
                .init(id: "stats",         label: String(localized: "Stats"),         icon: "chart.bar.fill")
            ]
        case .binder:
            return [
                .init(id: "add_cards",     label: String(localized: "Add cards"),     icon: "plus.circle.fill"),
                .init(id: "sort_by",       label: String(localized: "Sort by"),       icon: "arrow.up.arrow.down"),
                .init(id: "export",        label: String(localized: "Export"),        icon: "square.and.arrow.up"),
                .init(id: "print",         label: String(localized: "Print sleeves"), icon: "printer.fill")
            ]
        case .loan:
            return [
                .init(id: "mark_returned", label: String(localized: "Mark returned"), icon: "checkmark.circle.fill"),
                .init(id: "contact",       label: String(localized: "Contact"),       icon: "message.fill"),
                .init(id: "receipt",       label: String(localized: "Receipt"),       icon: "doc.text.fill")
            ]
        case .sale:
            return [
                .init(id: "mark_sold",     label: String(localized: "Mark sold"),     icon: "checkmark.seal.fill"),
                .init(id: "set_price",     label: String(localized: "Set price"),     icon: "tag.fill"),
                .init(id: "list",          label: String(localized: "List"),          icon: "cart.fill"),
                .init(id: "export",        label: String(localized: "Export"),        icon: "square.and.arrow.up")
            ]
        case .showcase:
            return [
                .init(id: "add_cards",     label: String(localized: "Add cards"),     icon: "plus.circle.fill"),
                .init(id: "reorder",       label: String(localized: "Reorder"),       icon: "arrow.up.arrow.down.circle")
            ]
        case .inbox:
            return [
                .init(id: "sort_all",      label: String(localized: "Sort all"),      icon: "tray.full.fill"),
                .init(id: "add_cards",     label: String(localized: "Add cards"),     icon: "plus.circle.fill")
            ]
        }
    }

    // MARK: - Lifecycle

    public func onAppear() async {
        await refresh()
        if let exchangeRateRepository {
            Task { try? await exchangeRateRepository.refresh() }
        }
    }

    public func refresh() async {
        status = .loading
        do {
            let loaded = try await itemRepository.items(in: stack.id)
            self.items = loaded
            self.cardCount   = try await itemRepository.cardCount(in: stack.id)
            self.uniqueCount = try await itemRepository.uniqueCount(in: stack.id)
            await hydrateCards(for: loaded)
            await loadPrices()
            await autoDetectCommanderIfNeeded()
            self.status = .idle
        } catch {
            self.status = .error(message: error.localizedDescription)
        }
    }

    private func loadPrices() async {
        guard let priceRepository else { return }
        let source = sessionRepository.preferredPriceSource
        let latest = (try? await priceRepository.latestByCard(source: source)) ?? [:]
        priceMap = latest.mapValues(\.retail)
    }

    private func hydrateCards(for items: [CollectionItem]) async {
        guard let cardRepository else { return }
        // One batched fetch for the whole stack instead of a query per row —
        // keeps the screen responsive when entering a big deck.
        let ids = Array(Set(items.map(\.cardID)))
        let cards = (try? await cardRepository.cards(ids: ids)) ?? []
        var map: [UUID: Card] = [:]
        for card in cards { map[card.id] = card }
        cardsByID = map

        // Rows imported before the DFC mapper fix have no image URLs. Backfill
        // them from Scryfall in the BACKGROUND so thumbnails fill in without
        // blocking the list.
        let imageless = cards.filter { !hasAnyImage($0) }
        if !imageless.isEmpty {
            Task { [weak self] in await self?.backfillImages(imageless) }
        }
    }

    private func backfillImages(_ cards: [Card]) async {
        guard let cardRepository else { return }
        for card in cards {
            guard let refreshed = await refreshFromScryfall(id: card.id) else { continue }
            try? await cardRepository.save([refreshed])
            cardsByID[card.id] = refreshed
        }
    }

    private func refreshFromScryfall(id: UUID) async -> Card? {
        guard let scryfallClient else { return nil }
        do {
            let dto = try await scryfallClient.card(id: id)
            return Card(from: dto)
        } catch {
            return nil
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

    // MARK: - Import

    public func presentImport() {
        isPresentingImport = true
    }

    public func dismissImport() {
        isPresentingImport = false
    }

    // MARK: - Delete stack

    public func presentDeleteConfirm() {
        isPresentingDeleteConfirm = true
    }

    public func dismissDeleteConfirm() {
        isPresentingDeleteConfirm = false
    }

    /// Cascades a stack delete: wipes the `CollectionItem` rows that
    /// referenced this stack and then removes the stack row itself.
    /// Flips `didDelete` so the view can pop the navigation stack.
    public func deleteStack() async {
        guard let stackRepository else { return }
        do {
            try await itemRepository.deleteAll(in: stack.id)
            try await stackRepository.delete(id: stack.id)
            didDelete = true
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    // MARK: - Commander

    public func presentCommanderPicker() {
        isPresentingCommanderPicker = true
    }

    public func dismissCommanderPicker() {
        isPresentingCommanderPicker = false
    }

    /// On refresh of a Commander deck with no commander pinned, if the list
    /// has exactly one distinct legendary creature, set it as commander.
    private func autoDetectCommanderIfNeeded() async {
        guard isCommanderDeck, stack.commanderCardID == nil else { return }
        let distinct = Set(commanderCandidates.map(\.cardID))
        guard distinct.count == 1, let cardID = distinct.first else { return }
        await setCommander(cardID: cardID)
    }

    /// Pins the printing identified by `cardID` as this deck's
    /// commander. Persists via `StackRepository` + bumps the local
    /// `stack` copy so the hero card re-renders.
    public func setCommander(cardID: UUID) async {
        guard let stackRepository else { return }
        var updated = stack
        updated.commanderCardID = cardID
        if let card = cardsByID[cardID] {
            updated.commander = card.name
        }
        do {
            try await stackRepository.save(updated)
            self.stack = updated
            dismissCommanderPicker()
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    /// Clears the commander pointer (back to the generic cover).
    public func clearCommander() async {
        guard let stackRepository else { return }
        var updated = stack
        updated.commanderCardID = nil
        updated.commander = nil
        do {
            try await stackRepository.save(updated)
            self.stack = updated
            dismissCommanderPicker()
        } catch {
            status = .error(message: error.localizedDescription)
        }
    }

    /// Items sorted by name (when joined) for the commander-picker UI.
    public var pickerCandidates: [CollectionItem] {
        items.sorted { lhs, rhs in
            let lname = cardsByID[lhs.cardID]?.name ?? ""
            let rname = cardsByID[rhs.cardID]?.name ?? ""
            return lname.localizedCaseInsensitiveCompare(rname) == .orderedAscending
        }
    }

    /// Hands the decklist to the app-scoped import coordinator (runs in the
    /// background + surfaces in the floating pill), then closes the sheet.
    public func startImport(source: String) {
        importCoordinator?.start(source: source, stackID: stack.id, stackName: stack.name)
        isPresentingImport = false
    }
}

// MARK: - Action descriptor

public struct StackAction: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let icon: String

    public init(id: String, label: String, icon: String) {
        self.id = id
        self.label = label
        self.icon = icon
    }
}

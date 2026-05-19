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

    // MARK: - Import sheet

    public var isPresentingImport: Bool = false
    public private(set) var isImporting: Bool = false
    public private(set) var importProgress: (current: Int, total: Int) = (0, 0)
    public private(set) var lastImportResult: ImportDeckListUseCase.ImportResult?

    // MARK: - Dependencies

    @ObservationIgnored private let itemRepository: CollectionItemRepository
    @ObservationIgnored private let cardRepository: CardRepository?
    @ObservationIgnored private let sessionRepository: SessionRepository
    @ObservationIgnored private let importDeckList: ImportDeckListUseCase?

    // MARK: - Init

    public init(
        stack: Stack,
        itemRepository: CollectionItemRepository,
        sessionRepository: SessionRepository,
        cardRepository: CardRepository? = nil,
        importDeckList: ImportDeckListUseCase? = nil
    ) {
        self.stack = stack
        self.itemRepository = itemRepository
        self.cardRepository = cardRepository
        self.sessionRepository = sessionRepository
        self.importDeckList = importDeckList
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
            if let commander = stack.commander, !commander.isEmpty {
                return commander
            }
            return stack.format?.displayName ?? StackKind.deck.displayLabel
        case .loan:
            if let person = stack.person, !person.isEmpty {
                return String(localized: "On loan to \(person)")
            }
            return StackKind.loan.displayLabel
        default:
            return stack.kind.displayLabel
        }
    }

    public var formattedTotalValue: String {
        // v0.3 stub — see `StacksListViewModel.totalValue` note. Real
        // value join lands when CollectionItem rows learn to read
        // Card.prices.
        CurrencyFormatter.format(.zero, currency: currency)
    }

    /// Kind-aware action labels rendered in `StackActionBar`.
    /// Per the brief §8.2.
    public var actions: [StackAction] {
        switch stack.kind {
        case .deck:
            return [
                .init(id: "edit_list",     label: String(localized: "Edit list"),     icon: "list.bullet.rectangle"),
                .init(id: "sample_hand",   label: String(localized: "Sample hand"),   icon: "rectangle.on.rectangle"),
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
    }

    public func refresh() async {
        status = .loading
        do {
            let loaded = try await itemRepository.items(in: stack.id)
            self.items = loaded
            self.cardCount   = try await itemRepository.cardCount(in: stack.id)
            self.uniqueCount = try await itemRepository.uniqueCount(in: stack.id)
            await hydrateCards(for: loaded)
            self.status = .idle
        } catch {
            self.status = .error(message: error.localizedDescription)
        }
    }

    private func hydrateCards(for items: [CollectionItem]) async {
        guard let cardRepository else { return }
        var map: [UUID: Card] = [:]
        for item in items where map[item.cardID] == nil {
            if let card = try? await cardRepository.card(id: item.cardID) {
                map[item.cardID] = card
            }
        }
        cardsByID = map
    }

    // MARK: - Import

    public func presentImport() {
        lastImportResult = nil
        isPresentingImport = true
    }

    public func dismissImport() {
        isPresentingImport = false
    }

    public func dismissImportResult() {
        lastImportResult = nil
    }

    /// Parses + resolves a Moxfield-style decklist and pushes the
    /// matched cards into this stack.
    public func importDeckList(source: String) async {
        guard let importDeckList else { return }
        isImporting = true
        importProgress = (0, 0)
        defer { isImporting = false }

        do {
            let result = try await importDeckList.execute(
                source: source,
                stackID: stack.id,
                progress: { [weak self] current, total in
                    self?.importProgress = (current, total)
                }
            )
            lastImportResult = result
            isPresentingImport = false
            await refresh()
        } catch {
            status = .error(message: error.localizedDescription)
        }
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

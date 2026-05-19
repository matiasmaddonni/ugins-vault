//
//  Stack.swift
//  UginsVault — Domain layer
//
//  A user-owned pile of cards. Decks, binders, loans, sale piles, the
//  showcase, the unsorted inbox — every owned card lives in exactly one
//  Stack via a `CollectionItem.stackID` reference.
//
//  Card-level totals (count + value) aren't on this struct — they're
//  derived via the `CollectionItemRepository` so we don't store stale
//  aggregates.
//

import Foundation

public struct Stack: Identifiable, Hashable, Codable, Sendable {

    public let id: UUID
    public var name: String
    public var kind: StackKind
    public var sortOrder: Int
    public var createdAt: Date

    // MARK: - Deck-only

    public var format: Format?
    public var colors: Set<ManaColor>
    public var commander: String?

    // MARK: - Loan-only

    public var person: String?
    public var since: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        kind: StackKind,
        sortOrder: Int = 0,
        createdAt: Date = .init(),
        format: Format? = nil,
        colors: Set<ManaColor> = [],
        commander: String? = nil,
        person: String? = nil,
        since: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.format = format
        self.colors = colors
        self.commander = commander
        self.person = person
        self.since = since
    }
}

//
//  CollectionItem.swift
//  UginsVault — Domain layer
//
//  Represents the user *owning* X copies of a specific Scryfall printing
//  in a specific Stack. The Scryfall `Card` is a catalogue mirror — it
//  doesn't carry per-user fields. Everything user-specific (quantity,
//  finish, condition, when-acquired, notes) lives here.
//

import Foundation

public struct CollectionItem: Identifiable, Hashable, Codable, Sendable {

    public let id: UUID
    public var cardID: UUID       // Scryfall printing id → `Card.id`
    public var stackID: UUID      // → `Stack.id`
    public var quantity: Int
    public var finish: Finish
    public var condition: CardCondition
    public var language: String
    public var acquiredAt: Date?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        cardID: UUID,
        stackID: UUID,
        quantity: Int = 1,
        finish: Finish = .nonfoil,
        condition: CardCondition = .nearMint,
        language: String = "en",
        acquiredAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.cardID = cardID
        self.stackID = stackID
        self.quantity = quantity
        self.finish = finish
        self.condition = condition
        self.language = language
        self.acquiredAt = acquiredAt
        self.notes = notes
    }
}

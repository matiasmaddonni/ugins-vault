//
//  SwiftDataCollectionItem.swift
//  UginsVault — Data layer / SwiftData
//
//  Persistence shape for Domain `CollectionItem`. Stores the ownership
//  row that links a Scryfall printing (`Card.id` → `cardID`) to a Stack.
//

import Foundation
import SwiftData

@Model
public final class SwiftDataCollectionItem {

    @Attribute(.unique) public var id: UUID
    public var cardID: UUID
    public var stackID: UUID
    public var quantity: Int
    public var finishRaw: String
    public var conditionRaw: String
    public var language: String
    public var acquiredAt: Date?
    public var notes: String?

    public init(
        id: UUID,
        cardID: UUID,
        stackID: UUID,
        quantity: Int = 1,
        finishRaw: String = Finish.nonfoil.rawValue,
        conditionRaw: String = CardCondition.nearMint.rawValue,
        language: String = "en",
        acquiredAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.cardID = cardID
        self.stackID = stackID
        self.quantity = quantity
        self.finishRaw = finishRaw
        self.conditionRaw = conditionRaw
        self.language = language
        self.acquiredAt = acquiredAt
        self.notes = notes
    }
}

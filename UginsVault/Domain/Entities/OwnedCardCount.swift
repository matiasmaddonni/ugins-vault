//
//  OwnedCardCount.swift
//  UginsVault — Domain layer
//
//  A single owned printing + total quantity, summed across stacks. The unit
//  the backend's owned list is keyed by (`cardID` = Scryfall printing id).
//

import Foundation

public struct OwnedCardCount: Sendable, Equatable {
    public let cardID: UUID
    public let quantity: Int

    public init(cardID: UUID, quantity: Int) {
        self.cardID = cardID
        self.quantity = quantity
    }
}

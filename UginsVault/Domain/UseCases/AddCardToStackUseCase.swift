//
//  AddCardToStackUseCase.swift
//  UginsVault — Domain layer
//
//  Creates a new `CollectionItem` row in the given stack for the given
//  Scryfall printing. If a row already exists for the same
//  (cardID, stackID, finish, condition, language) tuple, the quantity is
//  incremented on the existing row instead — keeping the table tidy.
//

import Foundation

public final class AddCardToStackUseCase: Sendable {

    private let itemRepository: CollectionItemRepository

    public init(itemRepository: CollectionItemRepository) {
        self.itemRepository = itemRepository
    }

    /// Adds `quantity` copies of `cardID` to `stackID`. If an identical
    /// row already exists, its quantity is bumped instead of inserting
    /// a duplicate.
    /// - Returns: The id of the affected `CollectionItem` row.
    @discardableResult
    public func execute(
        cardID: UUID,
        stackID: UUID,
        quantity: Int = 1,
        finish: Finish = .nonfoil,
        condition: CardCondition = .nearMint,
        language: String = "en"
    ) async throws -> UUID {
        guard quantity > 0 else {
            throw AddCardToStackError.invalidQuantity
        }

        let existing = try await itemRepository.items(in: stackID)
        if var match = existing.first(where: {
            $0.cardID    == cardID &&
            $0.finish    == finish &&
            $0.condition == condition &&
            $0.language  == language
        }) {
            match.quantity += quantity
            try await itemRepository.save(match)
            return match.id
        }

        let new = CollectionItem(
            cardID: cardID,
            stackID: stackID,
            quantity: quantity,
            finish: finish,
            condition: condition,
            language: language,
            acquiredAt: Date()
        )
        try await itemRepository.save(new)
        return new.id
    }
}

public enum AddCardToStackError: Error, Equatable {
    case invalidQuantity
}

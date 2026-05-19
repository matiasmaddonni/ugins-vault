//
//  MoveCollectionItemUseCase.swift
//  UginsVault — Domain layer
//
//  Re-parents a single `CollectionItem` to a different stack. Used by
//  drag-and-drop between piles + by the "Move to…" sheet action.
//

import Foundation

@MainActor
public final class MoveCollectionItemUseCase {

    private let itemRepository: CollectionItemRepository

    public init(itemRepository: CollectionItemRepository) {
        self.itemRepository = itemRepository
    }

    /// Moves the item identified by `itemID` into `targetStackID`. No-op
    /// when the item is already in the target stack.
    public func execute(itemID: UUID, targetStackID: UUID) async throws {
        guard var item = try await itemRepository.item(id: itemID) else {
            throw MoveCollectionItemError.itemNotFound
        }
        guard item.stackID != targetStackID else { return }

        item.stackID = targetStackID
        try await itemRepository.save(item)
    }
}

public enum MoveCollectionItemError: Error, Equatable {
    case itemNotFound
}

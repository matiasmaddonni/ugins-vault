//
//  WishlistUseCases.swift
//  UginsVault — Domain layer / Use cases
//
//  Thin business operations over `WishlistRepository`. Grouped in one
//  file because each is a one-liner — the wishlist has no cross-entity
//  rules beyond "don't duplicate a card".
//

import Foundation

/// Loads the wishlist (newest first).
@MainActor
public struct GetWishlistUseCase {
    private let repository: WishlistRepository
    public init(repository: WishlistRepository) { self.repository = repository }

    @discardableResult
    public func execute() async throws -> [WishlistItem] {
        try await repository.refresh()
    }
}

/// Adds a card to the wishlist. No-op when it's already tracked.
@MainActor
public struct AddToWishlistUseCase {
    private let repository: WishlistRepository
    public init(repository: WishlistRepository) { self.repository = repository }

    public func execute(card: Card) async throws {
        if try await repository.contains(id: card.id) { return }
        try await repository.add(WishlistItem(card: card))
    }
}

/// Removes a card from the wishlist by its id.
@MainActor
public struct RemoveFromWishlistUseCase {
    private let repository: WishlistRepository
    public init(repository: WishlistRepository) { self.repository = repository }

    public func execute(id: UUID) async throws {
        try await repository.remove(id: id)
    }
}

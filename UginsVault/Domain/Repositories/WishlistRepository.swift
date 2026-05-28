//
//  WishlistRepository.swift
//  UginsVault — Domain layer
//
//  Persistence boundary for the user's wishlist. Concrete implementation
//  (`SwiftDataWishlistRepository`) lives in the Data layer.
//

import Foundation

public protocol WishlistRepository: AnyObject, Sendable {

    /// Loads the wishlist from storage, newest first.
    @discardableResult
    func refresh() async throws -> [WishlistItem]

    /// `true` when a card with `id` is already wishlisted.
    func contains(id: UUID) async throws -> Bool

    /// Inserts (or updates) a wishlist entry. Idempotent on `id`.
    func add(_ item: WishlistItem) async throws

    /// Removes the entry with `id`. No-op when absent.
    func remove(id: UUID) async throws
}

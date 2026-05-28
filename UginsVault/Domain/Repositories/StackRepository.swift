//
//  StackRepository.swift
//  UginsVault — Domain layer
//
//  Read + write surface over the user's stack list. Card-level data
//  (count + value per stack) is derived through `CollectionItemRepository`,
//  not stored on the Stack row itself.
//

import Foundation

public protocol StackRepository: AnyObject, Sendable {

    // MARK: - Reads

    /// Pulls the current list of stacks from storage, sorted by
    /// `sortOrder` ascending.
    @discardableResult
    func refresh() async throws -> [Stack]

    /// Number of stored stacks. Drives the Stacks tab summary line.
    func totalCount() async throws -> Int

    /// Looks up a single stack by id.
    func stack(id: UUID) async throws -> Stack?

    // MARK: - Writes

    /// Inserts or updates by `Stack.id`. Idempotent.
    func save(_ stack: Stack) async throws

    /// Removes a single stack by id. Caller is responsible for moving or
    /// deleting any `CollectionItem` rows that point at it.
    func delete(id: UUID) async throws

    /// Wipes every stack. Used by tests + Settings → Reset.
    func deleteAll() async throws
}

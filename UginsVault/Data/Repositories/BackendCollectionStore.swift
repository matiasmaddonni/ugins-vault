//
//  BackendCollectionStore.swift
//  UginsVault — Data layer
//
//  `RemoteCollectionStore` over the Ugin's Vault `/v1/collection` endpoints.
//  Maps Domain entities ⇄ wire DTOs (opaque enum rawValues) and no-ops on empty
//  batches so callers can fire freely.
//

import Foundation

public struct BackendCollectionStore: RemoteCollectionStore {

    private let client: UginsVaultAPIClient

    public init(client: UginsVaultAPIClient) {
        self.client = client
    }

    public func fetch() async throws -> RemoteCollection {
        let dto = try await client.getCollection()
        return RemoteCollection(
            stacks: dto.stacks.map { $0.toDomain() },
            items: dto.items.map { $0.toDomain() }
        )
    }

    public func upsertItems(_ items: [CollectionItem]) async throws {
        guard !items.isEmpty else { return }
        _ = try await client.upsertItems(items.map(CollectionItemDTO.init))
    }

    public func deleteItems(ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }
        _ = try await client.deleteItems(ids: ids)
    }

    public func upsertStacks(_ stacks: [Stack]) async throws {
        guard !stacks.isEmpty else { return }
        _ = try await client.upsertStacks(stacks.map(StackDTO.init))
    }

    public func deleteStacks(ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }
        _ = try await client.deleteStacks(ids: ids)
    }

    public func replaceAll(stacks: [Stack], items: [CollectionItem]) async throws {
        _ = try await client.putCollection(
            stacks: stacks.map(StackDTO.init),
            items: items.map(CollectionItemDTO.init)
        )
    }
}

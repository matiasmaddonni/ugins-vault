//
//  CollectionSyncingStackRepositoryTests.swift
//  UginsVaultTests — Data
//

import Foundation
import SwiftData
import Testing
@testable import UginsVault

@Suite("CollectionSyncingStackRepository")
@MainActor
struct CollectionSyncingStackRepositoryTests {

    private func makeSUT() throws -> (
        CollectionSyncingStackRepository,
        SwiftDataStackRepository,
        MockRemoteCollectionStore
    ) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataStack.self, configurations: config)
        let base = SwiftDataStackRepository(modelContainer: container)
        let remote = MockRemoteCollectionStore()
        let sut = CollectionSyncingStackRepository(wrapped: base, remote: remote, debounce: .milliseconds(20))
        return (sut, base, remote)
    }

    @Test("reads delegate to the wrapped repo")
    func readsDelegate() async throws {
        let (sut, base, _) = try makeSUT()
        let stack = Stack(name: "Deck", kind: .deck)
        try await base.save(stack)

        #expect(try await sut.refresh().count == 1)
        #expect(try await sut.totalCount() == 1)
        #expect(try await sut.stack(id: stack.id)?.id == stack.id)
    }

    @Test("save persists locally + pushes a debounced upsert")
    func savePushesUpsert() async throws {
        let (sut, base, remote) = try makeSUT()
        let stack = Stack(name: "Modern deck", kind: .deck)

        try await sut.save(stack)
        try await Task.sleep(for: .milliseconds(150))

        #expect(try await base.stack(id: stack.id) != nil)
        #expect(remote.allUpsertedStackIDs.contains(stack.id))
    }

    @Test("delete removes locally + pushes a delete (server cascades its items)")
    func deletePushesDelete() async throws {
        let (sut, _, remote) = try makeSUT()
        let stack = Stack(name: "Binder", kind: .binder)
        try await sut.save(stack)
        try await Task.sleep(for: .milliseconds(150))

        try await sut.delete(id: stack.id)
        try await Task.sleep(for: .milliseconds(150))

        #expect(remote.allDeletedStackIDs.contains(stack.id))
    }

    @Test("deleteAll() is local-only")
    func deleteAllDoesNotPush() async throws {
        let (sut, _, remote) = try makeSUT()

        try await sut.deleteAll()
        try await Task.sleep(for: .milliseconds(120))

        #expect(remote.upsertedStacks.isEmpty)
        #expect(remote.deletedStackIDs.isEmpty)
    }
}

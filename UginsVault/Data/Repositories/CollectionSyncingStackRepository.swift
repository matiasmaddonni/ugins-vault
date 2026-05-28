//
//  CollectionSyncingStackRepository.swift
//  UginsVault — Data layer
//
//  Decorates a `StackRepository` so every local write also pushes a debounced
//  incremental change to the backend:
//    • save   → POST /v1/collection/stacks   (upsert by id)
//    • delete → DELETE /v1/collection/stacks (by id — cascades its items)
//  Best-effort; the next launch's restore reconciles. `deleteAll()` is
//  local-only (used by restore, which writes the base repo).
//
//  No observable state — view models read what `refresh()` returns.
//

import Foundation

@MainActor
public final class CollectionSyncingStackRepository: StackRepository {

    private let wrapped: StackRepository
    private let remote: RemoteCollectionStore
    private let debounce: Duration

    private var pendingUpsertIDs: Set<UUID> = []
    private var pendingDeleteIDs: Set<UUID> = []
    private var flushTask: Task<Void, Never>?

    public init(
        wrapped: StackRepository,
        remote: RemoteCollectionStore,
        debounce: Duration = .seconds(2)
    ) {
        self.wrapped = wrapped
        self.remote = remote
        self.debounce = debounce
    }

    // MARK: - Reads (delegate)

    @discardableResult
    public func refresh() async throws -> [Stack] {
        try await wrapped.refresh()
    }

    public func totalCount() async throws -> Int {
        try await wrapped.totalCount()
    }

    public func stack(id: UUID) async throws -> Stack? {
        try await wrapped.stack(id: id)
    }

    // MARK: - Writes (delegate + schedule push)

    public func save(_ stack: Stack) async throws {
        try await wrapped.save(stack)
        pendingDeleteIDs.remove(stack.id)
        pendingUpsertIDs.insert(stack.id)
        scheduleFlush()
    }

    public func delete(id: UUID) async throws {
        try await wrapped.delete(id: id)
        pendingUpsertIDs.remove(id)
        pendingDeleteIDs.insert(id)
        scheduleFlush()
    }

    public func deleteAll() async throws {
        try await wrapped.deleteAll()   // local-only by design
    }

    // MARK: - Debounced push

    private func scheduleFlush() {
        flushTask?.cancel()
        flushTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.debounce)
            guard !Task.isCancelled else { return }
            await self.flush()
        }
    }

    private func flush() async {
        let upsertIDs = pendingUpsertIDs
        let deleteIDs = pendingDeleteIDs
        pendingUpsertIDs = []
        pendingDeleteIDs = []

        var stacks: [Stack] = []
        for id in upsertIDs {
            if let stack = try? await wrapped.stack(id: id) { stacks.append(stack) }
        }
        try? await remote.upsertStacks(stacks)
        try? await remote.deleteStacks(ids: Array(deleteIDs))
    }
}

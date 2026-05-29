//
//  SwiftDataStackRepository.swift
//  UginsVault — Data layer / SwiftData
//
//  `StackRepository` backed by SwiftData via `@ModelActor`. Owns its
//  own background `ModelContext` so reads/writes don't queue on the
//  main actor.
//

import Foundation
import SwiftData

@ModelActor
public actor SwiftDataStackRepository: StackRepository {

    // MARK: - Reads

    @discardableResult
    public func refresh() async throws -> [Stack] {
        let descriptor = FetchDescriptor<SwiftDataStack>(
            sortBy: [
                SortDescriptor(\.sortOrder, order: .forward),
                SortDescriptor(\.createdAt, order: .forward)
            ]
        )
        return try modelContext.fetch(descriptor).map(Stack.init(from:))
    }

    public func totalCount() async throws -> Int {
        let descriptor = FetchDescriptor<SwiftDataStack>()
        return try modelContext.fetchCount(descriptor)
    }

    public func stack(id: UUID) async throws -> Stack? {
        var descriptor = FetchDescriptor<SwiftDataStack>(
            predicate: #Predicate<SwiftDataStack> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.map(Stack.init(from:))
    }

    // MARK: - Writes

    public func save(_ stack: Stack) async throws {
        let stackID = stack.id
        var descriptor = FetchDescriptor<SwiftDataStack>(
            predicate: #Predicate<SwiftDataStack> { $0.id == stackID }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(stack)
        } else {
            modelContext.insert(SwiftDataStack(from: stack))
        }
        try modelContext.save()
    }

    public func delete(id: UUID) async throws {
        var descriptor = FetchDescriptor<SwiftDataStack>(
            predicate: #Predicate<SwiftDataStack> { $0.id == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
            try modelContext.save()
        }
    }

    public func deleteAll() async throws {
        try modelContext.delete(model: SwiftDataStack.self)
        try modelContext.save()
    }
}

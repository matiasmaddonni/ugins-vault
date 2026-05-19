//
//  SwiftDataStackRepository.swift
//  UginsVault — Data layer / SwiftData
//
//  `StackRepository` backed by SwiftData. Operates on the shared
//  `ModelContainer`'s `mainContext`.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
public final class SwiftDataStackRepository: StackRepository {

    // MARK: - Observable state

    public private(set) var stacks: [Stack] = []
    public private(set) var isWriting: Bool = false

    // MARK: - Dependencies

    @ObservationIgnored private let modelContainer: ModelContainer
    @ObservationIgnored private var context: ModelContext { modelContainer.mainContext }

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Reads

    @discardableResult
    public func refresh() async throws -> [Stack] {
        let descriptor = FetchDescriptor<SwiftDataStack>(
            sortBy: [
                SortDescriptor(\.sortOrder, order: .forward),
                SortDescriptor(\.createdAt, order: .forward)
            ]
        )
        let loaded = try context.fetch(descriptor).map(Stack.init(from:))
        stacks = loaded
        return loaded
    }

    public func totalCount() async throws -> Int {
        let descriptor = FetchDescriptor<SwiftDataStack>()
        return try context.fetchCount(descriptor)
    }

    public func stack(id: UUID) async throws -> Stack? {
        var descriptor = FetchDescriptor<SwiftDataStack>(
            predicate: #Predicate<SwiftDataStack> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first.map(Stack.init(from:))
    }

    // MARK: - Writes

    public func save(_ stack: Stack) async throws {
        isWriting = true
        defer { isWriting = false }

        let stackID = stack.id
        var descriptor = FetchDescriptor<SwiftDataStack>(
            predicate: #Predicate<SwiftDataStack> { $0.id == stackID }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.apply(stack)
        } else {
            context.insert(SwiftDataStack(from: stack))
        }
        try context.save()
    }

    public func delete(id: UUID) async throws {
        isWriting = true
        defer { isWriting = false }

        var descriptor = FetchDescriptor<SwiftDataStack>(
            predicate: #Predicate<SwiftDataStack> { $0.id == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
            stacks.removeAll { $0.id == id }
        }
    }

    public func deleteAll() async throws {
        isWriting = true
        defer { isWriting = false }

        try context.delete(model: SwiftDataStack.self)
        try context.save()
        stacks = []
    }
}

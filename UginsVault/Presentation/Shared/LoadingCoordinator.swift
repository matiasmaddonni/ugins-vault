//
//  LoadingCoordinator.swift
//  UginsVault — Presentation: Shared
//
//  App-scoped counter of in-flight long-running work. Backs the slim
//  always-visible progress bar at the top of the root view so the user
//  never sees a "frozen screen" — even when the main actor is being
//  held by a slow SwiftData read, the bar makes it clear something is
//  happening. Non-blocking by design: never disables input, never
//  intercepts touches.
//
//  Use via `coordinator.track { … }` — increments on entry, decrements
//  on completion (success or throw). Safe to nest.
//

import Foundation
import Observation

@MainActor
@Observable
public final class LoadingCoordinator {

    public private(set) var activeCount: Int = 0

    public var isLoading: Bool { activeCount > 0 }

    public init() {}

    /// Runs `op` while incrementing the active counter. Decrements on
    /// completion or throw. Always paired.
    @discardableResult
    public func track<T>(
        _ label: String = "",
        operation: () async throws -> T
    ) async rethrows -> T {
        activeCount += 1
        defer { activeCount -= 1 }
        #if DEBUG
        let start = ContinuousClock().now
        defer {
            let elapsed = ContinuousClock().now - start
            if elapsed > .milliseconds(50), !label.isEmpty {
                print("⏱ \(label): \(elapsed)")
            }
        }
        #endif
        return try await operation()
    }
}

/// Convenience: run `op` while bumping the shared `LoadingCoordinator`
/// (resolved via `DependencyContainer.shared`). Use at call sites where
/// pushing the coordinator through the dependency tree would be more
/// churn than the perf indicator is worth.
@MainActor
@discardableResult
public func trackLoading<T>(
    _ label: String = "",
    _ op: () async throws -> T
) async rethrows -> T {
    try await DependencyContainer.shared.loadingCoordinator.track(label, operation: op)
}

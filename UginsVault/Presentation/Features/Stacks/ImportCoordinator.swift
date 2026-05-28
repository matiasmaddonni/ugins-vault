//
//  ImportCoordinator.swift
//  UginsVault — Presentation: Stacks
//
//  App-scoped coordinator for deck-list imports. Owns the background `Task` +
//  live progress so an import survives the sheet being dismissed, tab switches,
//  and navigating away from the stack. The floating `ImportProgressPill`
//  observes this; only one import runs at a time.
//

import Foundation
import Observation

@MainActor
@Observable
public final class ImportCoordinator {

    public enum Phase: Equatable {
        case idle
        case importing
        case finished
        case failed
    }

    // MARK: - Observed state

    public private(set) var phase: Phase = .idle
    public private(set) var stackName: String = ""
    public private(set) var stackID: UUID?
    public private(set) var current: Int = 0
    public private(set) var total: Int = 0
    public private(set) var result: ImportDeckListUseCase.ImportResult?
    public private(set) var errorMessage: String?

    // MARK: - Dependencies

    @ObservationIgnored private let makeUseCase: () -> ImportDeckListUseCase
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var lastSource: String = ""

    public init(makeUseCase: @escaping () -> ImportDeckListUseCase) {
        self.makeUseCase = makeUseCase
    }

    // MARK: - Derived

    public var isActive: Bool { phase == .importing }

    public var fractionComplete: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    // MARK: - Intents

    /// Kicks off a background import. No-op while one is already running
    /// (single-user app — serialise).
    public func start(source: String, stackID: UUID, stackName: String) {
        guard phase != .importing else { return }

        self.stackID = stackID
        self.stackName = stackName
        self.lastSource = source
        current = 0
        total = 0
        result = nil
        errorMessage = nil
        phase = .importing

        let useCase = makeUseCase()
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let result = try await useCase.execute(source: source, stackID: stackID) { current, total in
                    Task { @MainActor [weak self] in
                        self?.current = current
                        self?.total = total
                    }
                }
                self.result = result
                self.phase = .finished
            } catch {
                self.errorMessage = error.localizedDescription
                self.phase = .failed
            }
            self.task = nil
        }
    }

    public func retry() {
        guard phase == .failed, let stackID else { return }
        start(source: lastSource, stackID: stackID, stackName: stackName)
    }

    /// Hides the pill. Cancels an in-flight import (best-effort — already-saved
    /// rows stay).
    public func cancel() {
        task?.cancel()
        task = nil
        reset()
    }

    /// Clears a finished / failed banner.
    public func dismiss() {
        guard phase != .importing else { return }
        reset()
    }

    private func reset() {
        phase = .idle
        current = 0
        total = 0
        result = nil
        errorMessage = nil
        stackID = nil
        stackName = ""
    }
}

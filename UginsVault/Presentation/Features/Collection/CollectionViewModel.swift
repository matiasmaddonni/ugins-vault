//
//  CollectionViewModel.swift
//  UginsVault — Presentation: Collection
//
//  Drives the Collection tab. Surfaces the user's display currency + the
//  current totals (card count, vault value). Theme + currency *changes* are
//  owned by Settings; this VM only *reads* them via the session repository.
//

import Foundation
import Observation

@MainActor
@Observable
public final class CollectionViewModel {

    // MARK: - Observed state

    public private(set) var currency: Currency

    /// Placeholder totals — replaced by `CollectionRepository` reads later.
    public private(set) var cardCount: Int = 0
    public private(set) var totalValue: Decimal = 0

    public var searchQuery: String = ""

    // MARK: - Dependencies

    @ObservationIgnored private let sessionRepository: SessionRepository

    // MARK: - Init

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
        self.currency = sessionRepository.currency
    }

    // MARK: - Intents

    /// Re-reads the currency preference from the session repository.
    /// Called when Settings emits a change.
    public func refreshPreferences() {
        currency = sessionRepository.currency
    }
}

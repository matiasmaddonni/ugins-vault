//
//  HomeViewModel.swift
//  UginsVault — Presentation: Home (Collection placeholder)
//
//  Surfaces the user's theme + currency prefs and lets the view toggle them.
//  Card / stack data will come from a CollectionRepository when that feature
//  lands; for the skeleton, this VM exposes empty totals only.
//

import Foundation
import Observation

@MainActor
@Observable
public final class HomeViewModel {

    // MARK: - Observed state

    public private(set) var theme: AppTheme
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
        self.theme = sessionRepository.loadTheme()
        self.currency = sessionRepository.loadCurrency()
    }

    // MARK: - Intents

    public func toggleTheme() {
        let next: AppTheme = (theme == .dark) ? .light : .dark
        theme = next
        sessionRepository.saveTheme(next)
    }

    public func setCurrency(_ currency: Currency) {
        self.currency = currency
        sessionRepository.saveCurrency(currency)
    }
}

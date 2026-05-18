//
//  HomeViewModel.swift
//  UginsVault — Presentation: Home (Collection placeholder)
//
//  Surfaces the user's theme + currency prefs and lets the view toggle them.
//  Card / stack data will come from a CollectionRepository when that feature
//  lands; for the skeleton, this VM exposes empty totals only.
//

import Foundation
import Combine

@MainActor
public final class HomeViewModel: ObservableObject {

    // MARK: - Published state

    @Published public private(set) var theme: AppTheme
    @Published public private(set) var currency: Currency

    /// Placeholder totals — replaced by `CollectionRepository` reads later.
    @Published public private(set) var cardCount: Int = 0
    @Published public private(set) var totalValue: Decimal = 0

    @Published public var searchQuery: String = ""

    // MARK: - Dependencies

    private let sessionRepository: SessionRepositoryProtocol

    // MARK: - Init

    public init(sessionRepository: SessionRepositoryProtocol) {
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

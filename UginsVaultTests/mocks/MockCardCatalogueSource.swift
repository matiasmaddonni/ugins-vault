//
//  MockCardCatalogueSource.swift
//  UginsVaultTests
//

import Foundation
@testable import UginsVault

final class MockCardCatalogueSource: CardCatalogueSource, @unchecked Sendable {

    /// Pages returned in order. Each call to `fetchCards(query:page:)`
    /// consumes the next entry. If the queue empties, returns
    /// `CardCataloguePage(cards: [], hasMore: false)`.
    var queuedPages: [CardCataloguePage] = []

    private(set) var fetchCallCount: Int = 0
    private(set) var lastQuery: String?
    private(set) var lastPage: Int?

    /// Optional error to throw on the next fetch.
    var nextError: Error?

    func fetchCards(query: String, page: Int) async throws -> CardCataloguePage {
        fetchCallCount += 1
        lastQuery = query
        lastPage = page

        if let error = nextError {
            nextError = nil
            throw error
        }

        guard !queuedPages.isEmpty else {
            return CardCataloguePage(cards: [], hasMore: false)
        }
        return queuedPages.removeFirst()
    }
}

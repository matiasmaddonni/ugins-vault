//
//  ScryfallList.swift
//  UginsVault — Data layer / Scryfall DTOs
//
//  Generic envelope used by every Scryfall list endpoint (`/bulk-data`,
//  `/cards/search`, `/sets`, …). Pagination via `has_more` + `next_page`.
//

import Foundation

public struct ScryfallList<Item: Decodable & Sendable>: Decodable, Sendable {

    public let data: [Item]
    public let hasMore: Bool
    public let nextPage: URL?
    public let totalCards: Int?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore    = "has_more"
        case nextPage   = "next_page"
        case totalCards = "total_cards"
    }

    public init(data: [Item], hasMore: Bool = false, nextPage: URL? = nil, totalCards: Int? = nil) {
        self.data = data
        self.hasMore = hasMore
        self.nextPage = nextPage
        self.totalCards = totalCards
    }
}

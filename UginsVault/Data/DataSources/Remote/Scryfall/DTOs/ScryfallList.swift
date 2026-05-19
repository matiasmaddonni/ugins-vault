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
}

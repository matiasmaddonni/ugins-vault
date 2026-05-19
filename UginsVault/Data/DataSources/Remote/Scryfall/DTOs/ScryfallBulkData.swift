//
//  ScryfallBulkData.swift
//  UginsVault — Data layer / Scryfall DTOs
//
//  One bulk-data dump descriptor as returned by `GET /bulk-data`. We pull
//  the `download_uri` from the `oracle_cards` entry on first launch to
//  seed the local catalogue.
//

import Foundation

public struct ScryfallBulkData: Decodable, Sendable, Identifiable {

    public let id: UUID
    public let type: String       // "oracle_cards" | "default_cards" | "all_cards" | "unique_artwork" | "rulings"
    public let name: String
    public let description: String
    public let downloadURI: URL
    public let updatedAt: Date
    public let size: Int
    public let contentType: String
    public let contentEncoding: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case name
        case description
        case downloadURI      = "download_uri"
        case updatedAt        = "updated_at"
        case size
        case contentType      = "content_type"
        case contentEncoding  = "content_encoding"
    }
}

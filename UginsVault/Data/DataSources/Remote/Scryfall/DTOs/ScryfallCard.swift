//
//  ScryfallCard.swift
//  UginsVault — Data layer / Scryfall DTOs
//
//  Subset of the Scryfall card schema we currently care about. Extend as
//  features land — keep this DTO close to the wire format and let
//  `CardMapper` produce the Domain `Card` later.
//
//  Reference: https://scryfall.com/docs/api/cards
//

import Foundation

public struct ScryfallCard: Decodable, Sendable, Identifiable {

    // MARK: - Identifiers

    public let id: UUID
    public let oracleID: UUID?
    public let lang: String

    // MARK: - Names + types

    public let name: String
    public let typeLine: String?
    public let oracleText: String?

    // MARK: - Cost + colors

    public let manaCost: String?
    public let cmc: Double?
    public let colors: [String]?
    public let colorIdentity: [String]

    // MARK: - Set + collector info

    public let setCode: String
    public let setName: String
    public let collectorNumber: String
    public let rarity: String
    public let releasedAt: String?      // ISO-8601 yyyy-MM-dd

    // MARK: - Finishes + images + prices + legalities

    public let finishes: [String]?
    public let imageURIs: ImageURIs?
    public let prices: Prices?
    public let legalities: [String: String]?
    public let reserved: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case oracleID         = "oracle_id"
        case lang
        case name
        case typeLine         = "type_line"
        case oracleText       = "oracle_text"
        case manaCost         = "mana_cost"
        case cmc
        case colors
        case colorIdentity    = "color_identity"
        case setCode          = "set"
        case setName          = "set_name"
        case collectorNumber  = "collector_number"
        case rarity
        case releasedAt       = "released_at"
        case finishes
        case imageURIs        = "image_uris"
        case prices
        case legalities
        case reserved
    }

    // MARK: - Nested

    public struct ImageURIs: Decodable, Sendable {
        public let small:      URL?
        public let normal:     URL?
        public let large:      URL?
        public let png:        URL?
        public let artCrop:    URL?
        public let borderCrop: URL?

        enum CodingKeys: String, CodingKey {
            case small
            case normal
            case large
            case png
            case artCrop    = "art_crop"
            case borderCrop = "border_crop"
        }
    }

    public struct Prices: Decodable, Sendable {
        public let usd:     String?
        public let usdFoil: String?
        public let usdEtched: String?
        public let eur:     String?
        public let eurFoil: String?
        public let tix:     String?

        enum CodingKeys: String, CodingKey {
            case usd
            case usdFoil   = "usd_foil"
            case usdEtched = "usd_etched"
            case eur
            case eurFoil   = "eur_foil"
            case tix
        }
    }
}

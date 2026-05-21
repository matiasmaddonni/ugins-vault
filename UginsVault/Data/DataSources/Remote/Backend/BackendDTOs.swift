//
//  BackendDTOs.swift
//  UginsVault — Data layer / Backend
//
//  Codable wire shapes for the Ugin's Vault read API. Kept in the Data layer;
//  the Domain only ever sees mapped `PriceSnapshot` values.
//

import Foundation

// MARK: - GET /v1/prices

struct PricesResponseDTO: Decodable, Sendable {
    let source: String
    let window: Int
    let cards: [PriceCardDTO]
}

struct PriceCardDTO: Decodable, Sendable {
    let cardId: String
    let source: String
    let currency: String
    let current: Decimal?
    let history: [PricePointDTO]
}

struct PricePointDTO: Decodable, Sendable {
    let date: String   // calendar day, "yyyy-MM-dd"
    let price: Decimal
}

// MARK: - GET /v1/prices/status

struct PricesStatusDTO: Decodable, Sendable {
    let pending: [UUID]    // still fetching server-side
    let noData: [UUID]     // MTGJSON has no price — stop showing "fetching"
    let updatedAt: String? // "YYYY-MM-DD" or null
}


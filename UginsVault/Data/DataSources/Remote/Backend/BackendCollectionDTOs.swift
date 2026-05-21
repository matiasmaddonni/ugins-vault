//
//  BackendCollectionDTOs.swift
//  UginsVault — Data layer / Backend
//
//  Codable wire shapes for the `/v1/collection` endpoints + their mapping to
//  Domain entities. The backend is the source of truth for the collection; it
//  stores ZERO card metadata (only `cardId`, a Scryfall printing UUID) and
//  treats every enum-ish field (kind / finish / condition / format / colors /
//  language) as an opaque app-owned string — so mapping is just the enum
//  rawValue, with a safe fallback when decoding an unknown value.
//

import Foundation

// MARK: - Wire shapes (camelCase, 1:1 with the contract)

struct StackDTO: Codable, Sendable {
    let id: UUID
    let name: String
    let kind: String
    let sortOrder: Int
    let createdAt: Date
    let format: String?
    let colors: [String]
    let commander: String?
    let commanderCardId: UUID?
    let person: String?
    let since: Date?
}

struct CollectionItemDTO: Codable, Sendable {
    let id: UUID
    let cardId: UUID
    let stackId: UUID
    let quantity: Int
    let finish: String
    let condition: String
    let language: String
    let acquiredAt: Date?
    let notes: String?
}

// MARK: - GET /v1/collection

struct CollectionResponseDTO: Decodable, Sendable {
    let stacks: [StackDTO]
    let items: [CollectionItemDTO]
}

// MARK: - PUT /v1/collection (full replace — first import / hard reset only)

struct CollectionReplaceRequestDTO: Encodable, Sendable {
    let stacks: [StackDTO]
    let items: [CollectionItemDTO]
}

struct CollectionReplaceResponseDTO: Decodable, Sendable {
    let ok: Bool
    let stacks: Int
    let items: Int
    let dispatched: Bool?
}

// MARK: - Incremental items / stacks

struct ItemsUpsertRequestDTO: Encodable, Sendable {
    let items: [CollectionItemDTO]
}

struct ItemsUpsertResponseDTO: Decodable, Sendable {
    let ok: Bool
    let upserted: Int
    let dispatched: Bool?
}

struct StacksUpsertRequestDTO: Encodable, Sendable {
    let stacks: [StackDTO]
}

struct StacksUpsertResponseDTO: Decodable, Sendable {
    let ok: Bool
    let upserted: Int
}

struct IDsRequestDTO: Encodable, Sendable {
    let ids: [UUID]
}

struct DeleteResponseDTO: Decodable, Sendable {
    let ok: Bool
    let deleted: Int
}

// MARK: - Domain ⇄ DTO mapping

extension StackDTO {

    init(_ stack: Stack) {
        self.init(
            id: stack.id,
            name: stack.name,
            kind: stack.kind.rawValue,
            sortOrder: stack.sortOrder,
            createdAt: stack.createdAt,
            format: stack.format?.rawValue,
            colors: stack.colors.map(\.rawValue),
            commander: stack.commander,
            commanderCardId: stack.commanderCardID,
            person: stack.person,
            since: stack.since
        )
    }

    /// Opaque fields fall back to safe defaults if the server ever returns a
    /// value this app version doesn't know (forward-compat); colours are a set,
    /// so unknown entries are dropped.
    func toDomain() -> Stack {
        Stack(
            id: id,
            name: name,
            kind: StackKind(rawValue: kind) ?? .inbox,
            sortOrder: sortOrder,
            createdAt: createdAt,
            format: format.flatMap(Format.init(rawValue:)),
            colors: Set(colors.compactMap(ManaColor.init(rawValue:))),
            commander: commander,
            commanderCardID: commanderCardId,
            person: person,
            since: since
        )
    }
}

extension CollectionItemDTO {

    init(_ item: CollectionItem) {
        self.init(
            id: item.id,
            cardId: item.cardID,
            stackId: item.stackID,
            quantity: item.quantity,
            finish: item.finish.rawValue,
            condition: item.condition.rawValue,
            language: item.language,
            acquiredAt: item.acquiredAt,
            notes: item.notes
        )
    }

    func toDomain() -> CollectionItem {
        CollectionItem(
            id: id,
            cardID: cardId,
            stackID: stackId,
            quantity: max(1, quantity),
            finish: Finish(rawValue: finish) ?? .nonfoil,
            condition: CardCondition(rawValue: condition) ?? .nearMint,
            language: language,
            acquiredAt: acquiredAt,
            notes: notes
        )
    }
}

//
//  ScryfallCollection.swift
//  UginsVault — Data layer / Scryfall DTOs
//
//  Wire shapes for `POST /cards/collection`, which resolves up to 75 card
//  identifiers in a single request (vs. one round-trip per card). Used by the
//  deck-list importer for its bulk pass.
//

import Foundation

/// One identifier in a `/cards/collection` request. We only use the
/// name (+ optional set) form. `set` is omitted from the payload when nil.
public struct ScryfallCardIdentifier: Encodable, Sendable, Hashable {

    public let name: String
    public let set: String?

    public init(name: String, set: String? = nil) {
        self.name = name
        self.set = set
    }

    enum CodingKeys: String, CodingKey {
        case name, set
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        if let set, !set.isEmpty {
            try container.encode(set, forKey: .set)
        }
    }
}

struct ScryfallCollectionRequest: Encodable, Sendable {
    let identifiers: [ScryfallCardIdentifier]
}

/// Response from `/cards/collection`. `not_found` is intentionally ignored —
/// callers diff requested vs. returned (by name) to find the misses.
struct ScryfallCollectionResponse: Decodable, Sendable {
    let data: [ScryfallCard]
}

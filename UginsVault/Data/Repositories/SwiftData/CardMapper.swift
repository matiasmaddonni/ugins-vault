//
//  CardMapper.swift
//  UginsVault — Data layer / SwiftData
//
//  Bidirectional translation between the Domain `Card` (pure value type)
//  and the persistence-side `SwiftDataCard` (`@Model` reference type).
//

import Foundation

extension Card {

    /// Builds a Domain `Card` from a persisted row. Unknown enum cases
    /// fall back to `.unknown` / sensible defaults so legacy rows survive
    /// schema additions.
    init(from model: SwiftDataCard) {
        self.init(
            id: model.id,
            oracleID: model.oracleID,
            name: model.name,
            typeLine: model.typeLine,
            oracleText: model.oracleText,
            manaCost: model.manaCost,
            cmc: model.cmc,
            colors: Card.parseColors(model.colorsRaw),
            colorIdentity: Card.parseColors(model.colorIdentityRaw),
            rarity: Rarity(rawValue: model.rarityRaw) ?? .unknown,
            setCode: model.setCode,
            setName: model.setName,
            collectorNumber: model.collectorNumber,
            language: model.language,
            releasedAt: model.releasedAt,
            finishes: Card.parseFinishes(model.finishesRaw),
            images: CardImages(
                small: model.imageSmall,
                normal: model.imageNormal,
                large: model.imageLarge,
                png: model.imagePNG,
                artCrop: model.imageArtCrop,
                borderCrop: model.imageBorderCrop
            ),
            legalities: Card.parseLegalities(model.legalitiesJSON),
            isReserved: model.isReserved
        )
    }

    static func parseColors(_ raw: String) -> Set<ManaColor> {
        guard !raw.isEmpty else { return [] }
        return Set(raw.split(separator: ",").compactMap { ManaColor(rawValue: String($0)) })
    }

    static func parseFinishes(_ raw: String) -> Set<Finish> {
        guard !raw.isEmpty else { return [.nonfoil] }
        let parsed = Set(raw.split(separator: ",").compactMap { Finish(rawValue: String($0)) })
        return parsed.isEmpty ? [.nonfoil] : parsed
    }

    static func parseLegalities(_ json: String) -> [Format: Legality] {
        guard !json.isEmpty,
              let data = json.data(using: .utf8),
              let raw = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }

        var result: [Format: Legality] = [:]
        for (key, value) in raw {
            guard
                let format = Format(rawValue: key),
                let legality = Legality(rawValue: value)
            else { continue }
            result[format] = legality
        }
        return result
    }

    static func encodeLegalities(_ legalities: [Format: Legality]) -> String {
        guard !legalities.isEmpty else { return "" }
        let raw: [String: String] = Dictionary(uniqueKeysWithValues:
            legalities.map { ($0.key.rawValue, $0.value.rawValue) }
        )
        guard
            let data = try? JSONEncoder().encode(raw),
            let json = String(data: data, encoding: .utf8)
        else { return "" }
        return json
    }
}

extension SwiftDataCard {

    /// Builds a fresh `@Model` row from a Domain `Card`.
    convenience init(from card: Card) {
        self.init(
            id: card.id,
            oracleID: card.oracleID,
            name: card.name,
            typeLine: card.typeLine,
            oracleText: card.oracleText,
            manaCost: card.manaCost,
            cmc: card.cmc,
            colorsRaw: card.colors.map(\.rawValue).sorted().joined(separator: ","),
            colorIdentityRaw: card.colorIdentity.map(\.rawValue).sorted().joined(separator: ","),
            rarityRaw: card.rarity.rawValue,
            setCode: card.setCode,
            setName: card.setName,
            collectorNumber: card.collectorNumber,
            language: card.language,
            releasedAt: card.releasedAt,
            finishesRaw: card.finishes.map(\.rawValue).sorted().joined(separator: ","),
            imageSmall: card.images.small,
            imageNormal: card.images.normal,
            imageLarge: card.images.large,
            imagePNG: card.images.png,
            imageArtCrop: card.images.artCrop,
            imageBorderCrop: card.images.borderCrop,
            legalitiesJSON: Card.encodeLegalities(card.legalities),
            isReserved: card.isReserved
        )
    }

    /// Updates an existing row in place with values from a Domain `Card`.
    /// Used by `save(_:)` to make writes idempotent without deleting and
    /// re-inserting rows.
    func apply(_ card: Card) {
        oracleID         = card.oracleID
        name             = card.name
        typeLine         = card.typeLine
        oracleText       = card.oracleText
        manaCost         = card.manaCost
        cmc              = card.cmc
        colorsRaw        = card.colors.map(\.rawValue).sorted().joined(separator: ",")
        colorIdentityRaw = card.colorIdentity.map(\.rawValue).sorted().joined(separator: ",")
        rarityRaw        = card.rarity.rawValue
        setCode          = card.setCode
        setName          = card.setName
        collectorNumber  = card.collectorNumber
        language         = card.language
        releasedAt       = card.releasedAt
        finishesRaw      = card.finishes.map(\.rawValue).sorted().joined(separator: ",")
        imageSmall       = card.images.small
        imageNormal      = card.images.normal
        imageLarge       = card.images.large
        imagePNG         = card.images.png
        imageArtCrop     = card.images.artCrop
        imageBorderCrop  = card.images.borderCrop
        legalitiesJSON   = Card.encodeLegalities(card.legalities)
        isReserved       = card.isReserved
    }
}

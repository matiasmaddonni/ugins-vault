//
//  ScryfallCardMapper.swift
//  UginsVault — Data layer / Scryfall
//
//  Translates Scryfall's wire DTO into the Domain `Card` value type.
//  Returns `nil` when essential fields are missing — token / placeholder
//  rows that Scryfall ships without an `oracle_id` or `type_line` are
//  dropped at the boundary so the Domain never deals with half-cards.
//

import Foundation

extension Card {

    init?(from dto: ScryfallCard) {
        guard
            let oracleID = dto.oracleID,
            let typeLine = dto.typeLine
        else { return nil }

        let releasedAt: Date? = dto.releasedAt.flatMap(Card.parseReleaseDate)

        self.init(
            id: dto.id,
            oracleID: oracleID,
            name: dto.name,
            typeLine: typeLine,
            oracleText: dto.oracleText,
            manaCost: dto.manaCost,
            cmc: dto.cmc ?? 0,
            colors: Set((dto.colors ?? []).compactMap(ManaColor.init(rawValue:))),
            colorIdentity: Set(dto.colorIdentity.compactMap(ManaColor.init(rawValue:))),
            rarity: Rarity(rawValue: dto.rarity) ?? .unknown,
            setCode: dto.setCode,
            setName: dto.setName,
            collectorNumber: dto.collectorNumber,
            language: dto.lang,
            releasedAt: releasedAt,
            finishes: Set((dto.finishes ?? ["nonfoil"]).compactMap(Finish.init(rawValue:))),
            images: CardImages(
                // DFC / split / adventure cards put their image_uris on
                // each face — fall back to the first face when the
                // top-level is nil so the hero image isn't blank.
                small:      dto.imageURIs?.small      ?? dto.cardFaces?.first?.imageURIs?.small,
                normal:     dto.imageURIs?.normal     ?? dto.cardFaces?.first?.imageURIs?.normal,
                large:      dto.imageURIs?.large      ?? dto.cardFaces?.first?.imageURIs?.large,
                png:        dto.imageURIs?.png        ?? dto.cardFaces?.first?.imageURIs?.png,
                artCrop:    dto.imageURIs?.artCrop    ?? dto.cardFaces?.first?.imageURIs?.artCrop,
                borderCrop: dto.imageURIs?.borderCrop ?? dto.cardFaces?.first?.imageURIs?.borderCrop
            ),
            legalities: Self.parseLegalities(dto.legalities),
            isReserved: dto.reserved ?? false
        )
    }

    static func parseLegalities(_ raw: [String: String]?) -> [Format: Legality] {
        guard let raw else { return [:] }
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

    static func parseReleaseDate(_ raw: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: raw)
    }
}

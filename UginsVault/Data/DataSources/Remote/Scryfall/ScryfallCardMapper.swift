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
                small:      dto.imageURIs?.small,
                normal:     dto.imageURIs?.normal,
                large:      dto.imageURIs?.large,
                png:        dto.imageURIs?.png,
                artCrop:    dto.imageURIs?.artCrop,
                borderCrop: dto.imageURIs?.borderCrop
            ),
            prices: CardPrices(
                usd:       dto.prices?.usd.flatMap { Decimal(string: $0) },
                usdFoil:   dto.prices?.usdFoil.flatMap { Decimal(string: $0) },
                usdEtched: dto.prices?.usdEtched.flatMap { Decimal(string: $0) },
                eur:       dto.prices?.eur.flatMap { Decimal(string: $0) },
                eurFoil:   dto.prices?.eurFoil.flatMap { Decimal(string: $0) },
                tix:       dto.prices?.tix.flatMap { Decimal(string: $0) }
            )
        )
    }

    static func parseReleaseDate(_ raw: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: raw)
    }
}

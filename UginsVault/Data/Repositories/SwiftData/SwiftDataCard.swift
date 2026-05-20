//
//  SwiftDataCard.swift
//  UginsVault — Data layer / SwiftData
//
//  Persistence shape for Domain `Card`. Lives in the Data layer so the
//  Domain model never touches SwiftData. Mappers in `CardMapper.swift`
//  bridge the two.
//
//  Flat storage: every Domain collection (colours, finishes) is encoded
//  as a comma-separated string so SwiftData can index + query without
//  transformable detours. Image + price fields are flat optionals.
//

import Foundation
import SwiftData

@Model
public final class SwiftDataCard {

    // MARK: - Identifiers

    @Attribute(.unique) public var id: UUID
    public var oracleID: UUID

    // MARK: - Oracle

    public var name: String
    public var typeLine: String
    public var oracleText: String?
    public var manaCost: String?
    public var cmc: Double
    public var colorsRaw: String          // CSV — "R,G"
    public var colorIdentityRaw: String   // CSV

    // MARK: - Printing

    public var rarityRaw: String
    public var setCode: String
    public var setName: String
    public var collectorNumber: String
    public var language: String
    public var releasedAt: Date?
    public var finishesRaw: String        // CSV — "nonfoil,foil"

    // MARK: - Images

    public var imageSmall:      URL?
    public var imageNormal:     URL?
    public var imageLarge:      URL?
    public var imagePNG:        URL?
    public var imageArtCrop:    URL?
    public var imageBorderCrop: URL?

    // MARK: - Legalities + reserved list

    /// JSON-encoded `[String: String]` mapping `Format.rawValue` to
    /// `Legality.rawValue`. Empty string when no legalities are stored.
    /// Default supplied at property level so SwiftData lightweight
    /// migration can fill the column for pre-existing rows.
    public var legalitiesJSON: String = ""
    public var isReserved: Bool = false

    // MARK: - Init

    public init(
        id: UUID,
        oracleID: UUID,
        name: String,
        typeLine: String,
        oracleText: String? = nil,
        manaCost: String? = nil,
        cmc: Double = 0,
        colorsRaw: String = "",
        colorIdentityRaw: String = "",
        rarityRaw: String = Rarity.unknown.rawValue,
        setCode: String,
        setName: String,
        collectorNumber: String,
        language: String = "en",
        releasedAt: Date? = nil,
        finishesRaw: String = Finish.nonfoil.rawValue,
        imageSmall: URL? = nil,
        imageNormal: URL? = nil,
        imageLarge: URL? = nil,
        imagePNG: URL? = nil,
        imageArtCrop: URL? = nil,
        imageBorderCrop: URL? = nil,
        legalitiesJSON: String = "",
        isReserved: Bool = false
    ) {
        self.id = id
        self.oracleID = oracleID
        self.name = name
        self.typeLine = typeLine
        self.oracleText = oracleText
        self.manaCost = manaCost
        self.cmc = cmc
        self.colorsRaw = colorsRaw
        self.colorIdentityRaw = colorIdentityRaw
        self.rarityRaw = rarityRaw
        self.setCode = setCode
        self.setName = setName
        self.collectorNumber = collectorNumber
        self.language = language
        self.releasedAt = releasedAt
        self.finishesRaw = finishesRaw
        self.imageSmall = imageSmall
        self.imageNormal = imageNormal
        self.imageLarge = imageLarge
        self.imagePNG = imagePNG
        self.imageArtCrop = imageArtCrop
        self.imageBorderCrop = imageBorderCrop
        self.legalitiesJSON = legalitiesJSON
        self.isReserved = isReserved
    }
}

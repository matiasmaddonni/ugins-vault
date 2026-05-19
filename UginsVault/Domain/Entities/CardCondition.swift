//
//  CardCondition.swift
//  UginsVault — Domain layer
//
//  Industry-standard grading. Stored on `CollectionItem`, not on the
//  Scryfall-catalogue `Card`.
//

import Foundation

public enum CardCondition: String, Codable, CaseIterable, Sendable, Identifiable {
    case mint              = "M"
    case nearMint          = "NM"
    case lightlyPlayed     = "LP"
    case moderatelyPlayed  = "MP"
    case heavilyPlayed     = "HP"
    case damaged           = "DMG"

    public var id: String { rawValue }

    public var displayLabel: String {
        switch self {
        case .mint:             return "Mint"
        case .nearMint:         return "Near Mint"
        case .lightlyPlayed:    return "Lightly Played"
        case .moderatelyPlayed: return "Moderately Played"
        case .heavilyPlayed:    return "Heavily Played"
        case .damaged:          return "Damaged"
        }
    }
}

//
//  Rarity.swift
//  UginsVault — Domain layer
//

import Foundation

public enum Rarity: String, Codable, CaseIterable, Sendable {
    case common
    case uncommon
    case rare
    case mythic
    case special
    case bonus

    /// Unknown / malformed Scryfall rarity strings fall here.
    case unknown

    /// Localized, user-facing rarity name.
    public var displayName: String {
        switch self {
        case .common:   return String(localized: "Common")
        case .uncommon: return String(localized: "Uncommon")
        case .rare:     return String(localized: "Rare")
        case .mythic:   return String(localized: "Mythic")
        case .special:  return String(localized: "Special")
        case .bonus:    return String(localized: "Bonus")
        case .unknown:  return String(localized: "Unknown")
        }
    }
}

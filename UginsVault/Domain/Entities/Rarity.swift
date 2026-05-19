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
}

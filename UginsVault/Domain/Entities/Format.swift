//
//  Format.swift
//  UginsVault — Domain layer
//
//  Magic: The Gathering formats Scryfall reports in the `legalities` map.
//  Cases match Scryfall's snake-cased keys via `rawValue`. Unknown keys
//  in incoming data are dropped at the mapping boundary.
//

import Foundation

public enum Format: String, Codable, CaseIterable, Sendable {
    case standard
    case future
    case historic
    case timeless
    case gladiator
    case pioneer
    case explorer
    case modern
    case legacy
    case pauper
    case vintage
    case penny
    case commander
    case oathbreaker
    case standardbrawl
    case brawl
    case alchemy
    case paupercommander = "paupercommander"
    case duel
    case oldschool
    case premodern
    case predh

    public var displayName: String {
        switch self {
        case .standard:         return "Standard"
        case .future:           return "Future"
        case .historic:         return "Historic"
        case .timeless:         return "Timeless"
        case .gladiator:        return "Gladiator"
        case .pioneer:          return "Pioneer"
        case .explorer:         return "Explorer"
        case .modern:           return "Modern"
        case .legacy:           return "Legacy"
        case .pauper:           return "Pauper"
        case .vintage:          return "Vintage"
        case .penny:            return "Penny"
        case .commander:        return "Commander"
        case .oathbreaker:      return "Oathbreaker"
        case .standardbrawl:    return "Standard Brawl"
        case .brawl:            return "Brawl"
        case .alchemy:          return "Alchemy"
        case .paupercommander:  return "Pauper Commander"
        case .duel:             return "Duel Commander"
        case .oldschool:        return "Old School"
        case .premodern:        return "Premodern"
        case .predh:            return "PreDH"
        }
    }

    /// Subset shown in the card-detail summary panel. Other formats stay
    /// available via `legalities[.x]` but don't crowd the screen.
    public static let highlighted: [Format] = [
        .standard, .pioneer, .modern, .legacy, .vintage, .commander, .pauper
    ]
}

public enum Legality: String, Codable, CaseIterable, Sendable {
    case legal
    case notLegal   = "not_legal"
    case restricted
    case banned

    public var displayName: String {
        switch self {
        case .legal:      return "Legal"
        case .notLegal:   return "Not legal"
        case .restricted: return "Restricted"
        case .banned:     return "Banned"
        }
    }
}

//
//  ManaColor.swift
//  UginsVault — Domain layer
//
//  The five Magic colours plus colourless. Used in both `Card.colors`
//  (the cost-derived colour set) and `Card.colorIdentity` (the broader
//  identity used by Commander rules).
//

import Foundation

public enum ManaColor: String, Codable, CaseIterable, Sendable {
    case white     = "W"
    case blue      = "U"
    case black     = "B"
    case red       = "R"
    case green     = "G"
    case colorless = "C"

    public var displayName: String {
        switch self {
        case .white:     return String(localized: "White")
        case .blue:      return String(localized: "Blue")
        case .black:     return String(localized: "Black")
        case .red:       return String(localized: "Red")
        case .green:     return String(localized: "Green")
        case .colorless: return String(localized: "Colorless")
        }
    }
}

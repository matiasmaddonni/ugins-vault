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
        case .white:     return "White"
        case .blue:      return "Blue"
        case .black:     return "Black"
        case .red:       return "Red"
        case .green:     return "Green"
        case .colorless: return "Colorless"
        }
    }
}

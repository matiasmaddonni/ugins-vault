//
//  Format+Tint.swift
//  UginsVault — Presentation: Theme
//
//  Presentation-layer tint for each format. Lives outside the Domain so
//  the Domain `Format` enum stays pure (no SwiftUI imports).
//

import SwiftUI

extension Format {

    /// Accent colour used by `StackKindBadge` when the badge backs a
    /// deck-format pill (Modern blue, Commander gold, etc.). Defaults to
    /// gold for formats we haven't assigned bespoke tints to.
    public var tint: Color {
        switch self {
        case .standard:        return Color(hex: 0x8AB4F8) // light blue
        case .pioneer:         return Color(hex: 0xF2A33A) // amber
        case .modern:          return Color(hex: 0x4FC3F7) // cyan
        case .legacy:          return Color(hex: 0x9E70D6) // violet
        case .vintage:         return Color(hex: 0xE07A6A) // brick
        case .pauper:          return Color(hex: 0xA8B0B8) // silver
        case .commander:       return Color.uv.gold
        case .brawl:           return Color(hex: 0xD86AB8) // rose
        case .standardbrawl:   return Color(hex: 0xD86AB8)
        case .alchemy:         return Color(hex: 0xE6C572)
        case .historic:        return Color(hex: 0xC986D4)
        case .explorer:        return Color(hex: 0x8AB4F8)
        case .timeless:        return Color(hex: 0xE6C572)
        case .gladiator:       return Color(hex: 0x9E70D6)
        case .oathbreaker:     return Color.uv.gold
        case .paupercommander: return Color(hex: 0xA8B0B8)
        case .duel:            return Color.uv.gold
        case .oldschool:       return Color(hex: 0xE6C572)
        case .premodern:       return Color(hex: 0xA8B0B8)
        case .predh:           return Color.uv.gold
        case .penny:           return Color(hex: 0xA8B0B8)
        case .future:          return Color(hex: 0x4FC3F7)
        }
    }
}

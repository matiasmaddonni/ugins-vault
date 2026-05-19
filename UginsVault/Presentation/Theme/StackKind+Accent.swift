//
//  StackKind+Accent.swift
//  UginsVault — Presentation: Theme
//
//  Presentation-layer tint for each `StackKind`. Keeps SwiftUI imports
//  out of the Domain enum.
//

import SwiftUI

extension StackKind {

    /// Accent colour applied to badges, cover overlays, and icons.
    public var accentColor: Color {
        switch self {
        case .deck:     return Color.uv.gold
        case .binder:   return Color.uv.lavender
        case .loan:     return Color.uv.lavender
        case .sale:     return Color.uv.down
        case .showcase: return Color.uv.gold
        case .inbox:    return Color.uv.muted
        }
    }
}

extension ManaColor {

    /// Hex tint used by `ManaPipsView` + deck-cover gradients.
    public var tintColor: Color {
        switch self {
        case .white:     return Color.uv.manaW
        case .blue:      return Color.uv.manaU
        case .black:     return Color.uv.manaB
        case .red:       return Color.uv.manaR
        case .green:     return Color.uv.manaG
        case .colorless: return Color.uv.manaC
        }
    }
}

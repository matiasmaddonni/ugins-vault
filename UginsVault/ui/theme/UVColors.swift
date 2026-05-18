//
//  UVColors.swift
//  UginsVault — UI: Theme tokens
//
//  Obsidian Vault palette, adaptive (dark / light). Never write hex literals
//  in views — reach for tokens here. Mana / colour-identity values are
//  invariant across themes.
//

import SwiftUI

public extension Color {

    /// Namespace for Ugin's Vault colour tokens.
    enum uv {

        // MARK: Surface
        public static let bg        = adaptive(dark: 0x0E0D14, light: 0xF4EEDF)
        public static let bgDeep    = adaptive(dark: 0x08070E, light: 0xECE4CC)
        public static let panel     = adaptive(dark: 0x17162A, light: 0xFFFBEE)
        public static let panelHi   = adaptive(dark: 0x1F1D33, light: 0xFFFFFF)
        public static let panelLo   = adaptive(dark: 0x110F1F, light: 0xF0E8D0)
        public static let stroke    = adaptive(dark: 0x2A2741, light: 0xE2D7BB)
        public static let strokeHi  = adaptive(dark: 0x383456, light: 0xD3C4A0)

        // MARK: Ink
        public static let text      = adaptive(dark: 0xF1ECDE, light: 0x1F1A2E)
        public static let text2     = adaptive(dark: 0xC9C4B5, light: 0x3F374D)
        public static let muted     = adaptive(dark: 0x7E7A93, light: 0x6B6580)
        public static let muted2    = adaptive(dark: 0x565272, light: 0x8C879D)

        // MARK: Accents
        public static let gold      = adaptive(dark: 0xC9A24B, light: 0xA6802A)
        public static let goldHi    = adaptive(dark: 0xE6C572, light: 0xC9A24B)
        public static let goldLo    = adaptive(dark: 0x9A7424, light: 0x745A18)
        public static let lavender  = adaptive(dark: 0xB9A4D6, light: 0x5A4290)

        // MARK: Status
        public static let up        = adaptive(dark: 0x7BC58F, light: 0x2D7A4A)
        public static let down      = adaptive(dark: 0xE07A6A, light: 0xB84A3A)
        public static let warn      = adaptive(dark: 0xE0B068, light: 0xB07A1A)

        // MARK: Mana / colour identity (theme-invariant)
        public static let manaW = Color(hex: 0xF1E9C8)
        public static let manaU = Color(hex: 0x6BA8D8)
        public static let manaB = Color(hex: 0x6B5D7A)
        public static let manaR = Color(hex: 0xD87858)
        public static let manaG = Color(hex: 0x6FA67A)
        public static let manaC = Color(hex: 0xC7C2B5)
    }
}

// MARK: - Helpers

public extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

private func adaptive(dark: UInt32, light: UInt32) -> Color {
    Color(UIColor { trait in
        let hex = trait.userInterfaceStyle == .dark ? dark : light
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    })
}

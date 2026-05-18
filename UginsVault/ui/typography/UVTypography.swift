//
//  UVTypography.swift
//  UginsVault — UI: Typography tokens
//
//  Geist for display / body, Geist Mono for numbers. Falls back to system
//  fonts if the .ttf bundles are not registered in `Info.plist`.
//

import SwiftUI

public extension Font {

    /// Namespace for Ugin's Vault font tokens.
    enum uv {

        /// Large titles, hero numbers. Defaults to weight `.semibold`.
        public static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
            .custom("Geist", size: size, relativeTo: .largeTitle).weight(weight)
        }

        /// Paragraph + UI text.
        public static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
            .custom("Geist", size: size, relativeTo: .body).weight(weight)
        }

        /// Tabular: set codes, prices, deltas.
        public static func mono(_ size: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
            .custom("Geist Mono", size: size, relativeTo: .body).weight(weight)
        }

        /// Small uppercase mono with tracking — section headers.
        public static var sectionLabel: Font {
            mono(10, weight: .semibold)
        }
    }
}

// MARK: - Section label view modifier

public struct UVSectionLabelStyle: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .font(.uv.sectionLabel)
            .foregroundStyle(Color.uv.muted)
            .textCase(.uppercase)
            .tracking(2.2)
    }
}

public extension View {
    /// `LABEL · LIKE · THIS` — uppercase mono with letterspacing.
    func uvSectionLabel() -> some View { modifier(UVSectionLabelStyle()) }
}

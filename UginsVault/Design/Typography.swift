//
//  Typography.swift
//  UginsVault
//
//  Type tokens. Tries Geist first, falls back to SF Pro Rounded / SF Pro / SF Mono.
//  Add the .ttf files to the project + Info.plist > UIAppFonts to enable Geist.
//

import SwiftUI

extension Font {
    enum uv {
        // Display — large titles, hero numbers
        static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
            .custom("Geist", size: size, relativeTo: .largeTitle)
                .weight(weight)
        }

        // Body — paragraph + UI text
        static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
            .custom("Geist", size: size, relativeTo: .body)
                .weight(weight)
        }

        // Mono — set codes, prices, deltas, tabular numbers
        static func mono(_ size: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
            .custom("Geist Mono", size: size, relativeTo: .body)
                .weight(weight)
        }

        // Section label — small uppercase mono with tracking
        static var sectionLabel: Font {
            mono(10, weight: .semibold)
        }
    }
}

// MARK: - Convenience text-style view modifier

struct SectionLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.uv.sectionLabel)
            .foregroundStyle(Color.uv.muted)
            .textCase(.uppercase)
            .tracking(2.2)
    }
}

extension View {
    /// `LABEL · LIKE · THIS` formatted small caps for section headers.
    func sectionLabel() -> some View { modifier(SectionLabelStyle()) }
}

//
//  Spacing.swift
//  UginsVault — Presentation: Theme
//
//  Spacing + radius + shadow tokens. Per the project's UI rules, **no
//  numeric literal that represents a dimension may appear in a feature
//  view** — every padding / spacing / corner radius / icon size must come
//  from `Spacing` (general) or `Layout` (fixed component dimensions).
//
//  Add new constants here when a screen needs a value that doesn't exist
//  yet — never inline the number.
//

import SwiftUI

public enum Spacing {

    // MARK: - Scale

    /// 4 pt — micro gaps between tightly-related labels.
    public static let xs:  CGFloat = 4

    /// 8 pt — small gaps (between sub-labels, dense rows).
    public static let sm:  CGFloat = 8

    /// 12 pt — default vertical padding inside list rows.
    public static let md:  CGFloat = 12

    /// 16 pt — section padding, screen edge padding.
    public static let lg:  CGFloat = 16

    /// 24 pt — group spacing, header padding.
    public static let xl:  CGFloat = 24

    /// 32 pt — section-bottom breathing room.
    public static let xxl: CGFloat = 32

    /// 40 pt — splash / empty-state outer padding.
    public static let xxxl: CGFloat = 40

    /// 60 pt — large vertical pads (empty states, splash hero).
    public static let huge: CGFloat = 60

    // MARK: - Semantic

    /// Horizontal padding from the screen edge.
    public static let screenEdge: CGFloat = 16

    /// Inner horizontal padding inside a card / row.
    public static let rowHorizontal: CGFloat = 14

    /// Inner vertical padding inside a card / row.
    public static let rowVertical: CGFloat = 12

    /// Padding between rows inside a settings group's content card.
    public static let rowDividerLeading: CGFloat = 50

    /// Padding around big circular buttons (FAB).
    public static let fabBottomPad: CGFloat = 35

    /// Standard tab-bar clearance for scroll-view bottom inset.
    public static let tabBarClearance: CGFloat = 24

    // MARK: - Corner radii

    public enum Radius {
        public static let xs:   CGFloat = 6
        public static let sm:   CGFloat = 8
        public static let md:   CGFloat = 12
        public static let lg:   CGFloat = 16
        public static let xl:   CGFloat = 22
        public static let card: CGFloat = 14
        /// Pill: large enough to round any reasonable height.
        public static let pill: CGFloat = 9999
    }

    // MARK: - Shadow recipes

    public enum Shadow {

        public static func card<V: View>(_ view: V) -> some View {
            view.shadow(color: .black.opacity(0.28), radius: 12, y: 4)
        }

        public static func pop<V: View>(_ view: V) -> some View {
            view.shadow(color: .black.opacity(0.45), radius: 24, y: 12)
        }

        public static func goldGlow<V: View>(_ view: V) -> some View {
            view.shadow(color: Color.uv.gold.opacity(0.35), radius: 18)
        }
    }
}

// MARK: - Identifier helper

/// Builds an accessibility identifier from a `prefix` + free-form `value`
/// (typically a label). Always lowercased + space-stripped so the result
/// is XCUITest-friendly. Used inside `*AccessibilityFields.swift` files.
public func accessibilityId(_ prefix: String, _ value: String) -> String {
    let slug = value
        .lowercased()
        .replacingOccurrences(of: " ", with: "_")
        .filter { $0.isLetter || $0.isNumber || $0 == "_" }
    return "\(prefix)_\(slug)"
}

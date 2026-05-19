//
//  Layout.swift
//  UginsVault — Presentation: Theme
//
//  Fixed component dimensions. Sibling to `Spacing` — `Spacing` is for
//  layout *spacing*, `Layout` is for the *size* of specific components.
//
//  Add new constants here when a screen needs a fixed dimension that
//  doesn't exist yet — never inline the number.
//

import SwiftUI

public enum Layout {

    // MARK: - Buttons

    public static let primaryButtonHeight: CGFloat = 48
    public static let secondaryButtonHeight: CGFloat = 40

    // MARK: - Settings primitives

    /// Width reserved for the leading icon in a SettingsRow.
    public static let settingsRowIconWidth: CGFloat = 24

    /// Width cap for the inline appearance segmented control.
    public static let appearancePickerMaxWidth: CGFloat = 200

    /// Hairline divider thickness.
    public static let hairline: CGFloat = 0.5

    /// Vertical divider thickness + height inside the stat strip.
    public static let statDividerWidth: CGFloat = 1
    public static let statDividerHeight: CGFloat = 20

    /// Avatar diameter on the Profile hero card.
    public static let profileAvatarDiameter: CGFloat = 52

    /// Tint chip diameter on EditProfileSheet.
    public static let monogramTintChipDiameter: CGFloat = 36

    /// Avatar diameter for empty-state mark.
    public static let emptyStateMarkSize: CGFloat = 60

    // MARK: - Splash / Login

    public static let splashMarkSize: CGFloat = 120
    public static let loginMarkSize:  CGFloat = 72
    public static let loginRingDiameter: CGFloat = 144

    // MARK: - Brand mark inset on app icon

    public static let appIconCornerRatio: CGFloat = 0.225

    // MARK: - System icons / glyphs

    public static let smallIcon: CGFloat = 16
    public static let mediumIcon: CGFloat = 18
    public static let largeIcon: CGFloat = 24
    public static let heroIcon: CGFloat = 36
}

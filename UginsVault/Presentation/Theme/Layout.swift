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

    // MARK: - Account login

    /// Brand mark size on the account-login screen.
    public static let accountLoginMarkSize: CGFloat = 72

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

    // MARK: - Chips

    /// SF Symbol point size used inside `UVChip` (filter row, etc.).
    public static let chipIconSize: CGFloat = 12

    // MARK: - Mana / colour identity

    /// Pip diameter on `StackRow`'s sub-line + deck-cover overlays.
    public static let manaPipSmall: CGFloat = 9

    /// Pip diameter on the Stack-detail hero card.
    public static let manaPipMedium: CGFloat = 12

    // MARK: - Stack cover (Stacks tab list row)

    /// Outer width / height of the square cover thumbnail on `StackRow`.
    public static let stackCoverSize: CGFloat = 64

    /// Width of each rotated card "leaf" in deck-fan mode. The 3-card
    /// fan is composed of three of these stacked behind each other.
    public static let stackFanCardWidth: CGFloat = 38

    /// Height of each rotated card "leaf" in deck-fan mode.
    public static let stackFanCardHeight: CGFloat = 54

    /// Horizontal offset between the three fan leaves on `StackCover`.
    public static let stackFanOffset: CGFloat = 8

    /// SF Symbol point size rendered on a non-deck `StackCover`.
    public static let stackCoverGlyph: CGFloat = 26

    // MARK: - Stack kind badge

    /// SF Symbol point size for the leading glyph inside `StackKindBadge`.
    public static let stackBadgeIconSize: CGFloat = 10

    // MARK: - Stack list row

    /// Vertical padding inside a single `StackRow`.
    public static let stackRowVertical: CGFloat = 10

    // MARK: - Stack detail

    /// Cover size on `StackHeroCard`.
    public static let stackHeroCoverSize: CGFloat = 108

    /// SF Symbol point size for the basic-icon fallback inside
    /// `StackHeroCard` when no image is available.
    public static let stackHeroIconSize: CGFloat = 44

    /// Width of each kind-aware action tile inside `StackActionBar`.
    public static let stackActionWidth: CGFloat = 88

    /// Height of each action tile inside `StackActionBar`.
    public static let stackActionHeight: CGFloat = 72

    /// Minimum height of the deck-list paste TextEditor in
    /// `ImportDeckListSheet`.
    public static let importEditorMinHeight: CGFloat = 280

    /// Thumbnail width on `StackDetailView`'s card list rows.
    public static let stackDetailRowThumbWidth: CGFloat = 40

    /// Thumbnail height on `StackDetailView`'s card list rows.
    public static let stackDetailRowThumbHeight: CGFloat = 56

    /// Thumbnail width on `CollectionView`'s card list rows.
    public static let collectionRowThumbWidth: CGFloat = 48

    /// Thumbnail height on `CollectionView`'s card list rows.
    public static let collectionRowThumbHeight: CGFloat = 68

    /// Max scrollable height of the unresolved-names list inside
    /// `ImportResultToast`.
    public static let importToastUnresolvedMaxHeight: CGFloat = 180

    /// Bottom inset for the floating import progress pill so it floats just
    /// above the tab bar.
    public static let importPillBottomInset: CGFloat = 56

    // MARK: - Dashboard

    /// Vertical spacing between Dashboard sections. Bumped from 12 →
    /// 20 because the cards' panel chrome eats so much of the gutter
    /// that a 12pt gap reads as "touching" against the dark bg.
    public static let dashboardSectionSpacing: CGFloat = 20

    /// Horizontal padding around the Dashboard scroll content.
    public static let dashboardSidePadding: CGFloat = 12

    /// Horizontal spacing between cards inside a single Dashboard row
    /// (hero tiles, movers cards, quick stats).
    public static let dashboardRowSpacing: CGFloat = 12

    /// Hero row total height (TotalValueTile + WeekMoversTile).
    public static let dashboardHeroHeight: CGFloat = 168

    /// MoversRow card height.
    public static let dashboardMoversCardHeight: CGFloat = 188

    /// Donut diameter inside ByFormatPanel.
    /// Diameter of an inline mana / ability symbol pip in rules text.
    public static let manaSymbolSize: CGFloat = 18

    public static let dashboardDonutSize: CGFloat = 96

    /// Donut stroke thickness inside ByFormatPanel.
    public static let dashboardDonutThickness: CGFloat = 20

    /// Legend swatch size beside the donut.
    public static let dashboardLegendSwatchSize: CGFloat = 10

    /// Set-bar height in BySetPanel.
    public static let dashboardSetBarHeight: CGFloat = 6

    /// Hero sparkline height inside TotalValueTile.
    public static let dashboardSparklineHeight: CGFloat = 42

    /// 1pt finishing dot rendered at the latest sparkline point.
    public static let sparklineDotSize: CGFloat = 4

    /// Wishlist tile leading icon square diameter.
    public static let dashboardWishlistIconSize: CGFloat = 42

    /// Wishlist icon point size inside the tile.
    public static let dashboardWishlistIconGlyph: CGFloat = 20

    /// QuickStatCard inner spacing (label / value / sub).
    public static let dashboardQuickStatSpacing: CGFloat = 2

    /// Tracking applied to the section-label uppercase mono text.
    public static let sectionLabelTracking: CGFloat = 1.7

    /// Width of the leading index column inside `MoversCard` rows.
    public static let dashboardMoverIndexWidth: CGFloat = 12

    // MARK: - Dashboard skeleton

    /// Cap on the right hero block so the skeleton mirrors the real
    /// 1.4 / 1 split.
    public static let dashboardSkeletonHeroRight: CGFloat = 140

    /// Approximate height of the by-format panel in skeleton mode.
    public static let dashboardSkeletonFormatHeight: CGFloat = 200

    /// Approximate height of the by-set panel in skeleton mode.
    public static let dashboardSkeletonSetHeight: CGFloat = 240

    /// Approximate height of the wishlist teaser in skeleton mode.
    public static let dashboardSkeletonWishlistHeight: CGFloat = 80

    /// Approximate height of each quick-stat card in skeleton mode.
    public static let dashboardSkeletonStatHeight: CGFloat = 84
}

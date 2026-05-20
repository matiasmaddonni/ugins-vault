//
//  WishlistTeaser.swift
//  UginsVault — Presentation: Dashboard
//
//  Tile that previews the Wishlist screen. v0.4 ships it as a
//  disabled stub — full visual treatment but no tap-through and a
//  "Coming soon" sub-line — so the rhythm between the bars panel
//  and the quick-stats row stays balanced.
//

import SwiftUI

public struct WishlistTeaser: View {

    public let trackedCount: Int
    public let readyToBuyCount: Int

    public init(trackedCount: Int, readyToBuyCount: Int) {
        self.trackedCount = trackedCount
        self.readyToBuyCount = readyToBuyCount
    }

    public var body: some View {
        HStack(spacing: Spacing.md + 2) {
            iconSquare

            VStack(alignment: .leading, spacing: Spacing.xs - 2) {
                Text("Wishlist")
                    .font(.uv.display(15, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                Text(subtitle)
                    .font(.uv.mono(10.5))
                    .tracking(0.5)
                    .foregroundStyle(Color.uv.muted)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: Layout.smallIcon - 2, weight: .semibold))
                .foregroundStyle(Color.uv.muted)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md + 2)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.lg)
                .fill(Color.uv.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.lg)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(DashboardAccessibilityFields.wishlistTile)
        .accessibilityLabel("Wishlist")
    }

    private var subtitle: String {
        switch trackedCount {
        case 0:  return String(localized: "Track cards you want")
        case 1:  return String(localized: "1 card tracked")
        default: return String(localized: "\(trackedCount) cards tracked")
        }
    }

    private var iconSquare: some View {
        ZStack {
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.lavender.opacity(0.18))
            Image(systemName: "heart.fill")
                .font(.system(size: Layout.dashboardWishlistIconGlyph, weight: .semibold))
                .foregroundStyle(Color.uv.lavender.opacity(0.5))
        }
        .frame(
            width: Layout.dashboardWishlistIconSize,
            height: Layout.dashboardWishlistIconSize
        )
    }
}

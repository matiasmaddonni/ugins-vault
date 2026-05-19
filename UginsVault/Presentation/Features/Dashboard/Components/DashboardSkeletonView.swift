//
//  DashboardSkeletonView.swift
//  UginsVault — Presentation: Dashboard
//
//  Loading-state placeholder. Mirrors the final layout's dimensions
//  so swapping in the real snapshot doesn't shift anything.
//

import SwiftUI

public struct DashboardSkeletonView: View {

    public init() {}

    public var body: some View {
        VStack(spacing: Layout.dashboardSectionSpacing) {
            // Hero row
            HStack(spacing: Spacing.sm) {
                SkeletonBlock(cornerRadius: UVRadius.lg)
                SkeletonBlock(cornerRadius: UVRadius.lg)
                    .frame(maxWidth: Layout.dashboardSkeletonHeroRight)
            }
            .frame(height: Layout.dashboardHeroHeight)

            // Movers row
            HStack(spacing: Spacing.sm) {
                SkeletonBlock(cornerRadius: UVRadius.lg)
                SkeletonBlock(cornerRadius: UVRadius.lg)
            }
            .frame(height: Layout.dashboardMoversCardHeight)

            SkeletonBlock(cornerRadius: UVRadius.lg)
                .frame(height: Layout.dashboardSkeletonFormatHeight)

            SkeletonBlock(cornerRadius: UVRadius.lg)
                .frame(height: Layout.dashboardSkeletonSetHeight)

            SkeletonBlock(cornerRadius: UVRadius.lg)
                .frame(height: Layout.dashboardSkeletonWishlistHeight)

            HStack(spacing: Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonBlock(cornerRadius: UVRadius.md)
                        .frame(height: Layout.dashboardSkeletonStatHeight)
                }
            }
        }
        .padding(.horizontal, Layout.dashboardSidePadding)
        .padding(.vertical, Spacing.md)
    }
}

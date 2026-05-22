//
//  ListSkeleton.swift
//  UginsVault — Presentation: Design System
//
//  Placeholder rows for first-load list states (Collection, Stacks,
//  Stack detail). Mirrors a thumbnail + two text lines per row using the
//  shimmering `SkeletonBlock`, so swapping in real rows doesn't jump and
//  the user sees structured progress instead of a bare spinner.
//

import SwiftUI

public struct ListSkeleton: View {

    private let rows: Int
    private let thumbWidth: CGFloat
    private let thumbHeight: CGFloat

    public init(
        rows: Int = Layout.skeletonRowCount,
        thumbWidth: CGFloat = Layout.collectionRowThumbWidth,
        thumbHeight: CGFloat = Layout.collectionRowThumbHeight
    ) {
        self.rows = rows
        self.thumbWidth = thumbWidth
        self.thumbHeight = thumbHeight
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: Spacing.md) {
                    SkeletonBlock(cornerRadius: UVRadius.sm)
                        .frame(width: thumbWidth, height: thumbHeight)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        SkeletonBlock(cornerRadius: UVRadius.sm)
                            .frame(height: Layout.skeletonTextLineHeight)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SkeletonBlock(cornerRadius: UVRadius.sm)
                            .frame(width: Layout.skeletonTextShortWidth,
                                   height: Layout.skeletonTextLineHeight)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.top, Spacing.md)
        .accessibilityHidden(true)
    }
}

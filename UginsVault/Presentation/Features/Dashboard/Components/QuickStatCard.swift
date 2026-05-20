//
//  QuickStatCard.swift
//  UginsVault — Presentation: Dashboard
//
//  One tile in the 4-up quick-stats grid at the bottom of the
//  Dashboard. Pure presentation — every value is pre-formatted by
//  the caller.
//

import SwiftUI

public struct QuickStatCard: View {

    public let key: String              // accessibility key
    public let label: LocalizedStringKey // uppercase label
    public let value: String            // big number
    public let sublabel: LocalizedStringKey // sub copy under the value

    public init(key: String, label: LocalizedStringKey, value: String, sublabel: LocalizedStringKey) {
        self.key = key
        self.label = label
        self.value = value
        self.sublabel = sublabel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Layout.dashboardQuickStatSpacing) {
            Text(label)
                .uvSectionLabel()

            Text(value)
                .font(.uv.display(18, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(Color.uv.text)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(sublabel)
                .font(.uv.body(10))
                .foregroundStyle(Color.uv.muted2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(DashboardAccessibilityFields.quickStatCard(key))
    }
}

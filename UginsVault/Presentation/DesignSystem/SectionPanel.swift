//
//  SectionPanel.swift
//  UginsVault — Presentation: Design System
//
//  Reusable "label + content card" wrapper. Title rendered as the
//  small uppercase tracked-mono section header, with content packed
//  underneath inside the standard panel chrome (panel fill + stroke
//  + large corner radius). Used by every block on the Dashboard, and
//  open for re-use on future screens.
//

import SwiftUI

public struct SectionPanel<Content: View>: View {

    public let title: String
    private let content: Content

    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title.uppercased())
                .font(.uv.sectionLabel)
                .foregroundStyle(Color.uv.muted)
                .textCase(.uppercase)
                .tracking(Layout.sectionLabelTracking)
                .accessibilityAddTraits(.isHeader)

            content
        }
        .padding(Spacing.lg - 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: RoundedRectangle(cornerRadius: UVRadius.lg))
    }
}

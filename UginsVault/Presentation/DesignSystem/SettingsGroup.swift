//
//  SettingsGroup.swift
//  UginsVault — Presentation: DesignSystem
//
//  Section container used by Settings. Renders a small-caps gold header
//  above a panel-coloured rounded card that holds `SettingsRow`s.
//

import SwiftUI

public struct SettingsGroup<Content: View>: View {

    private let title: LocalizedStringKey
    private let footer: String?
    private let content: Content

    public init(
        _ title: LocalizedStringKey,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .uvSectionLabel()
                .padding(.horizontal, Spacing.lg)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: UVRadius.lg)
                    .fill(Color.uv.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: UVRadius.lg)
                            .strokeBorder(Color.uv.stroke, lineWidth: 1)
                    )
            )

            if let footer {
                Text(footer)
                    .font(.uv.body(11))
                    .foregroundStyle(Color.uv.muted)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xs)
            }
        }
    }
}

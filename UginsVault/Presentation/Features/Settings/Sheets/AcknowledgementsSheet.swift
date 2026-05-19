//
//  AcknowledgementsSheet.swift
//  UginsVault — Presentation: Settings
//
//  Credits + tooling list shown from About → Acknowledgements.
//

import SwiftUI

public struct AcknowledgementsSheet: View {

    private struct Credit: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
    }

    private let credits: [Credit] = [
        Credit(title: "Card data", detail: "Scryfall API · scryfall.com"),
        Credit(title: "Set data", detail: "MTGJson · mtgjson.com"),
        Credit(title: "Typography", detail: "Geist + Geist Mono (Vercel)"),
        Credit(title: "Iconography", detail: "SF Symbols (Apple)"),
        Credit(title: "Project generation", detail: "XcodeGen by Yonas Kolb"),
        Credit(title: "Testing", detail: "Swift Testing (Apple)")
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    ForEach(Array(credits.enumerated()), id: \.offset) { index, credit in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(credit.title)
                                .font(.uv.body(13, weight: .semibold))
                                .foregroundStyle(Color.uv.muted)
                                .accessibilityIdentifier("lbl_settings_ack_title_\(index)")

                            Text(credit.detail)
                                .font(.uv.body(15, weight: .medium))
                                .foregroundStyle(Color.uv.text)
                                .accessibilityIdentifier("lbl_settings_ack_detail_\(index)")
                        }
                    }

                    Divider()
                        .background(Color.uv.stroke)
                        .padding(.vertical, Spacing.xs)

                    Text("Magic: The Gathering is © Wizards of the Coast. Ugin's Vault is an unofficial fan tool and is not produced, endorsed, supported, or affiliated with Wizards of the Coast.")
                        .font(.uv.body(12))
                        .foregroundStyle(Color.uv.muted)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.vertical, Spacing.xl - 4)
            }
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Acknowledgements")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.uv.bg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SettingsAccessibilityFields.acknowledgementsSheet)
    }
}

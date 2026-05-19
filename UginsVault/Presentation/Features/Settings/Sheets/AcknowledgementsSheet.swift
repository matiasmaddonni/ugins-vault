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
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(credits) { credit in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(credit.title)
                                .font(.uv.body(13, weight: .semibold))
                                .foregroundStyle(Color.uv.muted)

                            Text(credit.detail)
                                .font(.uv.body(15, weight: .medium))
                                .foregroundStyle(Color.uv.text)
                        }
                    }

                    Divider()
                        .background(Color.uv.stroke)
                        .padding(.vertical, 4)

                    Text("Magic: The Gathering is © Wizards of the Coast. Ugin's Vault is an unofficial fan tool and is not produced, endorsed, supported, or affiliated with Wizards of the Coast.")
                        .font(.uv.body(12))
                        .foregroundStyle(Color.uv.muted)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Acknowledgements")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.uv.bg)
    }
}

//
//  EditProfileSheet.swift
//  UginsVault — Presentation: Settings
//
//  Modal editor for the local user's name + monogram tint. Avatar upload
//  is deferred to v0.2 — for now the avatar is always a monogram letter.
//

import SwiftUI

public struct EditProfileSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var monogramTint: MonogramTint

    private let memberSince: Int
    private let onSave: (UserProfile) -> Void

    public init(
        profile: UserProfile,
        onSave: @escaping (UserProfile) -> Void
    ) {
        self._name = State(initialValue: profile.name)
        self._monogramTint = State(initialValue: profile.monogramTint)
        self.memberSince = profile.memberSince
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    nameField
                    tintPicker
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.uv.muted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(UserProfile(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Vaultkeeper" : name,
                            monogramTint: monogramTint,
                            memberSince: memberSince
                        ))
                        dismiss()
                    }
                    .foregroundStyle(Color.uv.gold)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.uv.bg)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Name")
                .uvSectionLabel()

            TextField("Your name", text: $name)
                .font(.uv.body(16))
                .foregroundStyle(Color.uv.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .fill(Color.uv.panel)
                        .overlay(
                            RoundedRectangle(cornerRadius: UVRadius.md)
                                .strokeBorder(Color.uv.stroke, lineWidth: 1)
                        )
                )
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
        }
    }

    private var tintPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monogram tint")
                .uvSectionLabel()

            HStack(spacing: 12) {
                ForEach(MonogramTint.allCases) { tint in
                    tintChip(tint: tint)
                }
            }
        }
    }

    private func tintChip(tint: MonogramTint) -> some View {
        Button {
            monogramTint = tint
        } label: {
            Circle()
                .fill(fill(for: tint))
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .strokeBorder(
                            monogramTint == tint ? Color.uv.gold : Color.uv.stroke,
                            lineWidth: monogramTint == tint ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tint.rawValue) tint")
    }

    private func fill(for tint: MonogramTint) -> Color {
        switch tint {
        case .gold:     return Color.uv.gold.opacity(0.5)
        case .lavender: return Color.uv.lavender.opacity(0.6)
        case .verdant:  return Color.uv.up.opacity(0.55)
        case .crimson:  return Color.uv.down.opacity(0.55)
        case .mist:     return Color.uv.panelHi
        }
    }
}

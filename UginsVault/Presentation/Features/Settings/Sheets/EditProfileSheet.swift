//
//  EditProfileSheet.swift
//  UginsVault — Presentation: Settings
//
//  Modal editor for the local user's name, monogram tint, and (v0.8)
//  avatar photo. Avatar can come from the photo library (PhotosPicker)
//  or the device camera (`UIImagePickerController`). Falls back to the
//  monogram circle when no photo is set.
//

import SwiftUI
import PhotosUI
import UIKit

public struct EditProfileSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var monogramTint: MonogramTint
    @State private var avatarFilename: String?
    @State private var avatarPreview: UIImage?

    @State private var pickerItem: PhotosPickerItem?
    @State private var isPresentingCamera: Bool = false

    private let memberSince: Int
    private let avatarStorage: AvatarStorage
    private let onSave: (UserProfile) -> Void

    public init(
        profile: UserProfile,
        avatarStorage: AvatarStorage,
        onSave: @escaping (UserProfile) -> Void
    ) {
        self._name = State(initialValue: profile.name)
        self._monogramTint = State(initialValue: profile.monogramTint)
        self._avatarFilename = State(initialValue: profile.avatarFilename)
        self._avatarPreview = State(
            initialValue: profile.avatarFilename.flatMap(avatarStorage.loadImage)
        )
        self.memberSince = profile.memberSince
        self.avatarStorage = avatarStorage
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    avatarBlock
                    nameField
                    tintPicker
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.vertical, Spacing.xl - 4)
            }
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.uv.muted)
                        .accessibilityIdentifier(SettingsAccessibilityFields.editProfileCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(UserProfile(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Vaultkeeper" : name,
                            monogramTint: monogramTint,
                            memberSince: memberSince,
                            avatarFilename: avatarFilename
                        ))
                        dismiss()
                    }
                    .foregroundStyle(Color.uv.gold)
                    .fontWeight(.semibold)
                    .accessibilityIdentifier(SettingsAccessibilityFields.editProfileSave)
                }
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await persistAvatar(image)
                    }
                }
            }
            .fullScreenCover(isPresented: $isPresentingCamera) {
                CameraCaptureSheet(
                    onCapture: { image in
                        Task { await persistAvatar(image) }
                        isPresentingCamera = false
                    },
                    onCancel: { isPresentingCamera = false }
                )
                .ignoresSafeArea()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.uv.bg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SettingsAccessibilityFields.editProfileSheet)
    }

    // MARK: - Avatar

    private var avatarBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Avatar")
                .uvSectionLabel()

            HStack(spacing: Spacing.lg) {
                avatarPreviewCircle

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    AvatarPicker(
                        pickerItem: $pickerItem,
                        allowCamera: true,
                        allowRemove: avatarFilename != nil,
                        onCameraTap: { isPresentingCamera = true },
                        onRemove: { removeAvatar() }
                    )
                }
            }
        }
    }

    private var avatarPreviewCircle: some View {
        Group {
            if let avatarPreview {
                Image(uiImage: avatarPreview)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Layout.profileAvatarDiameter, height: Layout.profileAvatarDiameter)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.uv.gold.opacity(0.15))
                    Text(monogramFallback)
                        .font(.uv.mono(20, weight: .semibold))
                        .foregroundStyle(Color.uv.gold)
                }
                .frame(width: Layout.profileAvatarDiameter, height: Layout.profileAvatarDiameter)
            }
        }
        .overlay(Circle().strokeBorder(Color.uv.gold, lineWidth: 1.5))
    }

    private var monogramFallback: String {
        let first = name.trimmingCharacters(in: .whitespacesAndNewlines).first.map(String.init) ?? "·"
        return first.uppercased()
    }

    @MainActor
    private func persistAvatar(_ image: UIImage) async {
        if let oldFilename = avatarFilename {
            avatarStorage.deleteImage(filename: oldFilename)
        }
        if let filename = try? avatarStorage.saveImage(image) {
            avatarFilename = filename
            avatarPreview = image
        }
    }

    private func removeAvatar() {
        if let oldFilename = avatarFilename {
            avatarStorage.deleteImage(filename: oldFilename)
        }
        avatarFilename = nil
        avatarPreview = nil
        pickerItem = nil
    }

    // MARK: - Existing fields

    private var nameField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm - 2) {
            Text("Name")
                .uvSectionLabel()

            TextField("Your name", text: $name)
                .font(.uv.body(16))
                .foregroundStyle(Color.uv.text)
                .padding(.horizontal, Spacing.rowHorizontal)
                .padding(.vertical, Spacing.rowVertical)
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
                .accessibilityIdentifier(SettingsAccessibilityFields.editProfileName)
        }
    }

    private var tintPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Monogram tint")
                .uvSectionLabel()

            HStack(spacing: Spacing.md) {
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
                .frame(width: Layout.monogramTintChipDiameter, height: Layout.monogramTintChipDiameter)
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
        .accessibilityIdentifier(SettingsAccessibilityFields.tintChip(tint))
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

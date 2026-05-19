//
//  SettingsView.swift
//  UginsVault — Presentation: Settings
//
//  The Settings tab. Hero card + Display, Privacy & Security, and About
//  sections. Currency + Language pickers land in Steps 4–5; the rows are
//  visible here but the pickers light up after those steps ship.
//

import SwiftUI

public struct SettingsView: View {

    @State private var viewModel: SettingsViewModel

    @State private var isEditingProfile: Bool = false
    @State private var isPresentingAcknowledgements: Bool = false
    @State private var presentedSheet: ActiveSheet?

    private enum ActiveSheet: Identifiable {
        case language
        case currency

        var id: String {
            switch self {
            case .language: return "language"
            case .currency: return "currency"
            }
        }
    }

    public init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeroCard(
                        profile: viewModel.profile,
                        onTap: { isEditingProfile = true }
                    )

                    displayGroup
                    privacyGroup
                    aboutGroup
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isEditingProfile) {
                EditProfileSheet(profile: viewModel.profile) { updated in
                    viewModel.updateProfile(updated)
                }
            }
            .sheet(isPresented: $isPresentingAcknowledgements) {
                AcknowledgementsSheet()
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .language:
                    SheetPicker(
                        title: "Language",
                        options: languageOptions,
                        selection: viewModel.language,
                        onSelect: { viewModel.setLanguage($0) }
                    )
                case .currency:
                    SheetPicker(
                        title: "Display currency",
                        options: currencyOptions,
                        selection: viewModel.currency,
                        onSelect: { viewModel.setCurrency($0) }
                    )
                }
            }
        }
    }

    // MARK: - Display

    private var displayGroup: some View {
        SettingsGroup("Display") {
            // Appearance (segmented)
            HStack(spacing: 12) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.uv.gold)
                    .frame(width: 24)

                Text("Appearance")
                    .font(.uv.body(15, weight: .medium))
                    .foregroundStyle(Color.uv.text)

                Spacer()

                Picker("Appearance", selection: appearanceBinding) {
                    Text("System").tag(AppTheme.system)
                    Text("Light").tag(AppTheme.light)
                    Text("Dark").tag(AppTheme.dark)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            divider

            // Language (sheet picker)
            SettingsRow(
                icon: "character.bubble",
                title: "Language",
                value: languageLabel(for: viewModel.language)
            ) {
                presentedSheet = .language
            }

            // Currency (sheet picker)
            SettingsRow(
                icon: "dollarsign.circle",
                title: "Display currency",
                subtitle: "Values shown in USD until conversion rates ship in v0.3",
                value: viewModel.currency.rawValue
            ) {
                presentedSheet = .currency
            }

            divider

            // Reduce motion (toggle)
            HStack(spacing: 12) {
                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.uv.gold)
                    .frame(width: 24)

                Text("Reduce motion")
                    .font(.uv.body(15, weight: .medium))
                    .foregroundStyle(Color.uv.text)

                Spacer()

                Toggle("", isOn: reduceMotionBinding)
                    .labelsHidden()
                    .tint(Color.uv.gold)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Privacy

    private var privacyGroup: some View {
        SettingsGroup("Privacy & security") {
            HStack(spacing: 12) {
                Image(systemName: "faceid")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.uv.gold)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Face ID lock")
                        .font(.uv.body(15, weight: .medium))
                        .foregroundStyle(Color.uv.text)

                    Text("Require Face ID or passcode on launch")
                        .font(.uv.body(12))
                        .foregroundStyle(Color.uv.muted)
                }

                Spacer()

                Toggle("", isOn: faceIDLockBinding)
                    .labelsHidden()
                    .tint(Color.uv.gold)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    // MARK: - About

    private var aboutGroup: some View {
        VStack(spacing: 16) {
            SettingsGroup("About") {
                SettingsRow(
                    icon: "info.circle",
                    title: "Version"
                ) {
                    Text("0.1.0 (1)")
                        .font(.uv.mono(13, weight: .medium))
                        .foregroundStyle(Color.uv.muted)
                }

                SettingsRow(
                    icon: "doc.text",
                    title: "Acknowledgements",
                    value: nil
                ) {
                    isPresentingAcknowledgements = true
                }
            }

            Text("Magic: The Gathering is © Wizards of the Coast. Ugin's Vault is an unofficial fan tool.")
                .font(.uv.body(11))
                .foregroundStyle(Color.uv.muted2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Bindings

    private var appearanceBinding: Binding<AppTheme> {
        Binding(
            get: { viewModel.theme },
            set: { viewModel.setTheme($0) }
        )
    }

    private var reduceMotionBinding: Binding<Bool> {
        Binding(
            get: { viewModel.reduceMotion },
            set: { viewModel.setReduceMotion($0) }
        )
    }

    private var faceIDLockBinding: Binding<Bool> {
        Binding(
            get: { viewModel.faceIDLock },
            set: { viewModel.setFaceIDLock($0) }
        )
    }

    // MARK: - Options

    private var languageOptions: [SheetPicker<Language>.Option] {
        [
            .init(id: .system,  label: "System",   detail: "Follow device"),
            .init(id: .english, label: "English"),
            .init(id: .spanish, label: "Español")
        ]
    }

    private var currencyOptions: [SheetPicker<Currency>.Option] {
        [
            .init(id: .usd, label: "USD", detail: "US Dollar"),
            .init(id: .eur, label: "EUR", detail: "Euro"),
            .init(id: .ars, label: "ARS", detail: "Argentine Peso")
        ]
    }

    private func languageLabel(for language: Language) -> String {
        switch language {
        case .system:  return "System"
        case .english: return "English"
        case .spanish: return "Español"
        }
    }

    // MARK: - Decorations

    private var divider: some View {
        Rectangle()
            .fill(Color.uv.stroke.opacity(0.6))
            .frame(height: 0.5)
            .padding(.leading, 50)
    }
}

#Preview {
    SettingsView(viewModel: DependencyContainer.shared.makeSettingsViewModel())
        .preferredColorScheme(.dark)
}

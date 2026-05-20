//
//  SettingsView.swift
//  UginsVault — Presentation: Settings
//
//  The Settings tab. Hero card + Display, Privacy & Security, and About
//  sections.
//

import SwiftUI

public struct SettingsView: View {

    @State private var viewModel: SettingsViewModel

    @State private var isEditingProfile: Bool = false
    @State private var isPresentingAcknowledgements: Bool = false
    @State private var presentedSheet: ActiveSheet?
    @State private var isConfirmingReset: Bool = false
    @State private var isConfirmingSignOut: Bool = false
    @State private var isShowingWishlist: Bool = false
    @State private var languageChangePending: Bool = false
    @State private var isShowingLanguageRestart: Bool = false

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
                VStack(spacing: Spacing.xl) {
                    ProfileHeroCard(
                        profile: viewModel.profile,
                        cardCount: viewModel.catalogueCount > 0 ? viewModel.catalogueCount : nil,
                        totalValueLabel: viewModel.profileValueLabel,
                        deckCount: viewModel.deckCount,
                        avatarImage: viewModel.profile.avatarFilename.flatMap(
                            DependencyContainer.shared.avatarStorage.loadImage
                        ),
                        onTap: { isEditingProfile = true }
                    )

                    wishlistGroup
                    displayGroup
                    privacyGroup
                    PricingSettingsGroup(
                        sessionRepository: DependencyContainer.shared.sessionRepository,
                        exchangeRateRepository: DependencyContainer.shared.exchangeRateRepository
                    )
                    dataGroup
                    aboutGroup
                    accountGroup
                }
                .padding(.horizontal, Spacing.screenEdge)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task { await viewModel.onAppear() }
            .navigationDestination(isPresented: $isShowingWishlist) {
                WishlistView(viewModel: DependencyContainer.shared.makeWishlistViewModel())
            }
            .confirmationDialog(
                "Reset the catalogue?",
                isPresented: $isConfirmingReset,
                titleVisibility: .visible
            ) {
                Button("Reset catalogue", role: .destructive) {
                    Task { await viewModel.resetCatalogueNow() }
                }
                .accessibilityIdentifier(SettingsAccessibilityFields.resetConfirmButton)

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Wipes every card stored locally and re-downloads the seed set from Scryfall. Your preferences are not affected.")
            }
            .confirmationDialog(
                "Sign out?",
                isPresented: $isConfirmingSignOut,
                titleVisibility: .visible
            ) {
                Button("Sign out", role: .destructive) {
                    Task { await viewModel.signOut() }
                }
                .accessibilityIdentifier(SettingsAccessibilityFields.signOutConfirmButton)

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to sync prices. Your local collection stays on this device.")
            }
            .sheet(isPresented: $isEditingProfile) {
                EditProfileSheet(
                    profile: viewModel.profile,
                    avatarStorage: DependencyContainer.shared.avatarStorage
                ) { updated in
                    viewModel.updateProfile(updated)
                }
            }
            .sheet(isPresented: $isPresentingAcknowledgements) {
                AcknowledgementsSheet()
            }
            .sheet(item: $presentedSheet, onDismiss: {
                if languageChangePending {
                    languageChangePending = false
                    isShowingLanguageRestart = true
                }
            }) { sheet in
                switch sheet {
                case .language:
                    SheetPicker(
                        title: String(localized: "Language"),
                        options: languageOptions,
                        selection: viewModel.language,
                        onSelect: { newLanguage in
                            guard newLanguage != viewModel.language else { return }
                            viewModel.setLanguage(newLanguage)
                            languageChangePending = true
                        }
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SettingsAccessibilityFields.languageSheet)
                case .currency:
                    SheetPicker(
                        title: String(localized: "Display currency"),
                        options: currencyOptions,
                        selection: viewModel.currency,
                        onSelect: { viewModel.setCurrency($0) }
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SettingsAccessibilityFields.currencySheet)
                }
            }
        }
        .alert("Restart to apply language", isPresented: $isShowingLanguageRestart) {
            Button("Restart now", role: .destructive) {
                UginsVaultApp.applyLanguageOverride(viewModel.language)
                exit(EXIT_SUCCESS)
            }
        } message: {
            Text("UginsVault will close so the new language applies everywhere. Tap its icon to reopen.")
        }
        .accessibilityIdentifier(SettingsAccessibilityFields.screen)
    }

    // MARK: - Collection

    private var wishlistGroup: some View {
        SettingsGroup("Collection") {
            SettingsRow(
                icon: "heart",
                title: "Wishlist",
                value: nil
            ) {
                isShowingWishlist = true
            }
            .accessibilityIdentifier(SettingsAccessibilityFields.wishlistRow)
        }
    }

    // MARK: - Display

    private var displayGroup: some View {
        SettingsGroup("Display") {
            appearanceRow
            divider
            languageRow
            currencyRow
            divider
            reduceMotionRow
        }
    }

    private var appearanceRow: some View {
        HStack(spacing: Spacing.md) {
            iconLeading(systemName: "circle.lefthalf.filled")

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
            .frame(maxWidth: Layout.appearancePickerMaxWidth)
            .accessibilityIdentifier(SettingsAccessibilityFields.appearancePicker)
        }
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.rowVertical)
    }

    private var languageRow: some View {
        SettingsRow(
            icon: "character.bubble",
            title: "Language",
            value: languageLabel(for: viewModel.language)
        ) {
            presentedSheet = .language
        }
        .accessibilityIdentifier(SettingsAccessibilityFields.languageRow)
    }

    private var currencyRow: some View {
        SettingsRow(
            icon: "dollarsign.circle",
            title: "Display currency",
            subtitle: String(localized: "Convert with live blue-dollar / ECB rates"),
            value: viewModel.currency.rawValue
        ) {
            presentedSheet = .currency
        }
        .accessibilityIdentifier(SettingsAccessibilityFields.currencyRow)
    }

    private var reduceMotionRow: some View {
        HStack(spacing: Spacing.md) {
            iconLeading(systemName: "wand.and.stars.inverse")

            Text("Reduce motion")
                .font(.uv.body(15, weight: .medium))
                .foregroundStyle(Color.uv.text)

            Spacer()

            Toggle("", isOn: reduceMotionBinding)
                .labelsHidden()
                .tint(Color.uv.gold)
                .accessibilityIdentifier(SettingsAccessibilityFields.reduceMotionToggle)
        }
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.rowVertical)
    }

    // MARK: - Privacy

    private var privacyGroup: some View {
        SettingsGroup("Privacy & security") {
            HStack(spacing: Spacing.md) {
                iconLeading(systemName: "faceid")

                VStack(alignment: .leading, spacing: Spacing.xs / 2) {
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
                    .accessibilityIdentifier(SettingsAccessibilityFields.faceIDLockToggle)
            }
            .padding(.horizontal, Spacing.rowHorizontal)
            .padding(.vertical, Spacing.rowVertical)
        }
    }

    // MARK: - Data

    private var dataGroup: some View {
        SettingsGroup("Data") {
            SettingsRow(
                icon: "rectangle.stack",
                title: "Catalogue size"
            ) {
                Text(catalogueSizeLabel)
                    .font(.uv.mono(13, weight: .medium))
                    .foregroundStyle(Color.uv.muted)
            }
            .accessibilityIdentifier(SettingsAccessibilityFields.catalogueSizeRow)

            SettingsPriceSyncRow(
                priceRepository: DependencyContainer.shared.priceRepository,
                makeSyncViewModel: { DependencyContainer.shared.makePriceSyncViewModel() }
            )

            SettingsRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Reset catalogue",
                subtitle: String(localized: "Wipe local cards + re-download the seed set"),
                isDestructive: true,
                action: { isConfirmingReset = true }
            ) {
                if viewModel.isResetting {
                    if case .resetting(let saved) = viewModel.dataStatus {
                        Text("\(saved)")
                            .font(.uv.mono(13, weight: .medium))
                            .foregroundStyle(Color.uv.muted)
                    } else {
                        ProgressView().tint(Color.uv.gold)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.uv.muted)
                }
            }
            .accessibilityIdentifier(SettingsAccessibilityFields.resetCatalogueRow)
            .disabled(viewModel.isResetting)
        }
    }

    private var catalogueSizeLabel: String {
        if viewModel.catalogueCount == 1 {
            return "1 card"
        }
        return "\(viewModel.catalogueCount) cards"
    }

    // MARK: - Account

    private var accountGroup: some View {
        SettingsGroup("Account") {
            SettingsRow(
                icon: "person.crop.circle",
                title: "Signed in as"
            ) {
                Text(viewModel.accountEmail ?? String(localized: "Not signed in"))
                    .font(.uv.mono(13, weight: .medium))
                    .foregroundStyle(Color.uv.muted)
                    .lineLimit(1)
            }
            .accessibilityIdentifier(SettingsAccessibilityFields.accountEmailRow)

            SettingsRow(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Sign out",
                subtitle: String(localized: "Disconnect this device from your account"),
                isDestructive: true,
                action: { isConfirmingSignOut = true }
            ) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.uv.muted)
            }
            .accessibilityIdentifier(SettingsAccessibilityFields.signOutRow)
        }
    }

    // MARK: - About

    private var aboutGroup: some View {
        VStack(spacing: Spacing.lg) {
            SettingsGroup("About") {
                SettingsRow(
                    icon: "info.circle",
                    title: "Version"
                ) {
                    Text("0.1.0 (1)")
                        .font(.uv.mono(13, weight: .medium))
                        .foregroundStyle(Color.uv.muted)
                }
                .accessibilityIdentifier(SettingsAccessibilityFields.versionRow)

                SettingsRow(
                    icon: "doc.text",
                    title: "Acknowledgements",
                    value: nil
                ) {
                    isPresentingAcknowledgements = true
                }
                .accessibilityIdentifier(SettingsAccessibilityFields.acknowledgementsRow)
            }

            Text("Magic: The Gathering is © Wizards of the Coast. Ugin's Vault is an unofficial fan tool.")
                .font(.uv.body(11))
                .foregroundStyle(Color.uv.muted2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .accessibilityIdentifier(SettingsAccessibilityFields.mtgFooterLabel)
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
            .init(id: .system,  label: String(localized: "System"), detail: String(localized: "Follow device")),
            .init(id: .english, label: String(localized: "English")),
            .init(id: .spanish, label: String(localized: "Español"))
        ]
    }

    private var currencyOptions: [SheetPicker<Currency>.Option] {
        [
            .init(id: .usd, label: "USD", detail: String(localized: "US Dollar")),
            .init(id: .eur, label: "EUR", detail: String(localized: "Euro")),
            .init(id: .ars, label: "ARS", detail: String(localized: "Argentine Peso"))
        ]
    }

    private func languageLabel(for language: Language) -> String {
        switch language {
        case .system:  return String(localized: "System")
        case .english: return String(localized: "English")
        case .spanish: return String(localized: "Español")
        }
    }

    // MARK: - Decorations

    private var divider: some View {
        Rectangle()
            .fill(Color.uv.stroke.opacity(0.6))
            .frame(height: Layout.hairline)
            .padding(.leading, Spacing.rowDividerLeading)
    }

    private func iconLeading(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: Layout.smallIcon, weight: .medium))
            .foregroundStyle(Color.uv.gold)
            .frame(width: Layout.settingsRowIconWidth)
    }
}

#Preview {
    SettingsView(viewModel: DependencyContainer.shared.makeSettingsViewModel())
        .preferredColorScheme(.dark)
}

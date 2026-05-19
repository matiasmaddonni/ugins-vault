//
//  SettingsPriceSyncRow.swift
//  UginsVault — Presentation: Settings
//
//  Settings → Data → "Refresh prices". Self-contained: owns the
//  modal sheet that re-uses `PriceSyncView`, and reads the last-sync
//  timestamp straight off `PriceRepository`.
//

import SwiftUI

public struct SettingsPriceSyncRow: View {

    private let priceRepository: PriceRepository
    private let makeSyncViewModel: () -> PriceSyncViewModel

    @State private var isPresentingSync: Bool = false

    public init(
        priceRepository: PriceRepository,
        makeSyncViewModel: @escaping () -> PriceSyncViewModel
    ) {
        self.priceRepository = priceRepository
        self.makeSyncViewModel = makeSyncViewModel
    }

    public var body: some View {
        SettingsRow(
            icon: "arrow.down.circle",
            title: "Refresh prices",
            subtitle: subtitleCopy,
            action: { isPresentingSync = true }
        ) {
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.uv.muted)
        }
        .accessibilityIdentifier(PriceSyncAccessibilityFields.settingsRefresh)
        .sheet(isPresented: $isPresentingSync) {
            PriceSyncView(
                viewModel: makeSyncViewModel(),
                onFinish: { isPresentingSync = false }
            )
        }
    }

    private var subtitleCopy: String {
        guard let stamp = priceRepository.lastSyncedAt else {
            return String(localized: "Never synced")
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return String(
            localized: "Last synced \(formatter.localizedString(for: stamp, relativeTo: Date()))"
        )
    }
}

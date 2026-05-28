//
//  SettingsPriceSyncRow.swift
//  UginsVault — Presentation: Settings
//
//  Settings → Data → "Refresh prices". Self-contained: owns the
//  modal sheet that re-uses `PriceSyncView`, and loads the last-sync
//  timestamp from `PriceRepository` on appear.
//

import SwiftUI

public struct SettingsPriceSyncRow: View {

    private let priceRepository: PriceRepository
    private let makeSyncViewModel: () -> PriceSyncViewModel

    @State private var isPresentingSync: Bool = false
    @State private var lastSyncedAt: Date?

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
        .task { await reloadStamp() }
        .onChange(of: isPresentingSync) { _, presenting in
            // Sheet just closed — sync may have stamped a new value.
            if !presenting { Task { await reloadStamp() } }
        }
        .sheet(isPresented: $isPresentingSync) {
            PriceSyncView(
                viewModel: makeSyncViewModel(),
                onFinish: { isPresentingSync = false }
            )
        }
    }

    private var subtitleCopy: String {
        guard let stamp = lastSyncedAt else {
            return String(localized: "Never synced")
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return String(
            localized: "Last synced \(formatter.localizedString(for: stamp, relativeTo: Date()))"
        )
    }

    private func reloadStamp() async {
        lastSyncedAt = (try? await priceRepository.lastSyncedAt()) ?? nil
    }
}

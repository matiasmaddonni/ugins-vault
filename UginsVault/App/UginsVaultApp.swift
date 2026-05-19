//
//  UginsVaultApp.swift
//  UginsVault
//
//  App entry. Builds the dependency graph at launch, registers the
//  weekly price-sync background task, and mounts `RootView`.
//

import SwiftUI
import Kingfisher

@main
struct UginsVaultApp: App {

    private let container = DependencyContainer.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Self.configureImageCache()
        PriceSyncScheduler.registerTaskHandler(container: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                viewModel: container.makeRootViewModel(),
                container: container
            )
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                PriceSyncScheduler.scheduleNextRun()
            }
        }
    }

    /// Caps Kingfisher's disk image cache at ~1 GB. ~25 k card faces at
    /// ~100 KB each would otherwise reach ~2.5 GB. The in-memory cache
    /// is bounded separately by Kingfisher's defaults.
    private static func configureImageCache() {
        let oneGigabyte: UInt = 1_024 * 1_024 * 1_024
        ImageCache.default.diskStorage.config.sizeLimit = oneGigabyte
    }
}

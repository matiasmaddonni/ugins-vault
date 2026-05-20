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
        Self.applyLanguageOverride(container.sessionRepository.language)
        Self.configureImageCache()
        PriceSyncScheduler.registerTaskHandler(container: container)
    }

    /// Pins the bundle's resolved localization to the user's in-app
    /// language choice. `.environment(\.locale, …)` alone only steers
    /// SwiftUI `Text` literals — strings built via `String(localized:)`
    /// (most VM-side labels) and system controls follow
    /// `Bundle.main.preferredLocalizations`, which is derived from the
    /// `AppleLanguages` default. Setting it here, before any view or
    /// localized lookup runs, makes a Spanish-device user who forces
    /// English actually see English everywhere. `.system` clears the
    /// override so the device language wins again. Takes full effect on
    /// the next launch after a change (the live session still gets the
    /// SwiftUI-`Text` half from the environment locale).
    static func applyLanguageOverride(_ language: Language) {
        let defaults = UserDefaults.standard
        switch language {
        case .system:  defaults.removeObject(forKey: "AppleLanguages")
        case .english: defaults.set(["en"], forKey: "AppleLanguages")
        case .spanish: defaults.set(["es"], forKey: "AppleLanguages")
        }
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

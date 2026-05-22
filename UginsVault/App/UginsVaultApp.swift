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

    /// Tunes Kingfisher's image cache.
    ///
    /// - Disk: capped at ~1 GB (7-day default expiry). ~25 k card faces at
    ///   ~100 KB each would otherwise reach ~2.5 GB.
    /// - Memory: Kingfisher's default expiration is only 5 minutes, so a
    ///   decoded thumbnail gets evicted from RAM after brief idle and the
    ///   next display has to re-read from disk and **re-decode on the main
    ///   actor** — the stutter when scrolling a list back into view or
    ///   reopening the commander picker. Keep decoded images resident for the
    ///   whole session (iOS still purges the memory cache on memory pressure)
    ///   and cap the cost so it can't grow unbounded.
    private static func configureImageCache() {
        let cache = ImageCache.default
        let oneGigabyte: UInt = 1_024 * 1_024 * 1_024
        cache.diskStorage.config.sizeLimit = oneGigabyte

        cache.memoryStorage.config.expiration = .seconds(60 * 60) // 1 hour
        cache.memoryStorage.config.totalCostLimit = 256 * 1_024 * 1_024 // ~256 MB
    }
}

//
//  AppPhase.swift
//  UginsVault — Domain layer
//
//  Top-level navigation phase. Pure Swift — no SwiftUI / UIKit dependency.
//

import Foundation

public enum AppPhase: String, Codable, Sendable, CaseIterable {
    case splash
    case login
    /// First-launch (or manually triggered) pricing-data sync. Displayed
    /// between `.login` and `.home`. Skipped once the user has at least
    /// one successful sync stamped in `PriceRepository.lastSyncedAt`.
    case priceSync
    case home
}

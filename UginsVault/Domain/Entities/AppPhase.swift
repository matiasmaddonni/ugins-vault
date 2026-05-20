//
//  AppPhase.swift
//  UginsVault — Domain layer
//
//  Top-level navigation phase. Pure Swift — no SwiftUI / UIKit dependency.
//

import Foundation

public enum AppPhase: String, Codable, Sendable, CaseIterable {
    case splash
    /// Backend account sign-in (Supabase email/password). Shown when no
    /// session can be restored. Precedes the local `.login` Face ID gate.
    case accountLogin
    case login
    /// First-launch (or manually triggered) pricing-data sync. Displayed
    /// between `.login` and `.home`. Skipped once the user has at least
    /// one successful sync stamped in `PriceRepository.lastSyncedAt`.
    case priceSync
    case home
}

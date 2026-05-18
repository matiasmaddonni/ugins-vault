//
//  AppPhase.swift
//  UginsVault
//
//  Top-level phase: splash → login → home.
//  Persisted across launches via AppState.
//

import Foundation
import SwiftUI

enum AppPhase: String, Codable {
    case splash
    case login
    case home
}

/// User-controlled theme preference. `.system` follows the OS.
enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case dark
    case light
    case system

    var id: String { rawValue }

    var colorScheme: SwiftUI.ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}

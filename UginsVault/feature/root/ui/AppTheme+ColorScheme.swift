//
//  AppTheme+ColorScheme.swift
//  UginsVault — Presentation
//
//  Maps the framework-agnostic `AppTheme` (Domain) into SwiftUI's
//  `ColorScheme`. This adapter lives in the Presentation layer so the
//  Domain stays free of SwiftUI imports.
//

import SwiftUI

public extension AppTheme {

    /// `nil` means "follow system".
    var colorScheme: ColorScheme? {
        switch self {
        case .dark:   .dark
        case .light:  .light
        case .system: nil
        }
    }
}

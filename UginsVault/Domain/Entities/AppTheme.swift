//
//  AppTheme.swift
//  UginsVault — Domain layer
//
//  User-controlled color scheme preference. Mapping to UIKit / SwiftUI
//  happens in the Presentation layer.
//

import Foundation

public enum AppTheme: String, Codable, Sendable, CaseIterable, Identifiable {
    case dark
    case light
    case system

    public var id: String { rawValue }
}

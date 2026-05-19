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
    case home
}

//
//  BiometricsDataSource.swift
//  UginsVault — Data layer
//
//  Wraps the platform biometrics surface. Tests inject a mock; the live impl
//  uses `LocalAuthentication`.
//

import Foundation

public protocol BiometricsDataSource: Sendable {

    /// Whether biometry is currently usable (enrolled + available).
    var isAvailable: Bool { get }

    /// Triggers the system authentication prompt.
    func authenticate(reason: String) async -> AuthOutcome
}

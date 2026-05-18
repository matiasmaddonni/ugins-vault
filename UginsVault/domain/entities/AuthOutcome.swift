//
//  AuthOutcome.swift
//  UginsVault — Domain layer
//
//  Result of a biometric / passcode authentication attempt. Framework-agnostic
//  — the Data layer maps LAError into one of these cases.
//

import Foundation

public enum AuthOutcome: Equatable, Sendable {
    /// Authentication succeeded.
    case success
    /// User cancelled the prompt.
    case userCancelled
    /// User chose the fallback option (e.g. "Enter PIN").
    case fallback
    /// Biometry / passcode is not available on this device.
    case unavailable
    /// Generic failure with a localised description.
    case failed(reason: String)
}

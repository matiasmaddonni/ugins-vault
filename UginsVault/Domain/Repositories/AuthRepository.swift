//
//  AuthRepository.swift
//  UginsVault — Domain layer
//
//  Abstracts authentication away from `LocalAuthentication`. The Data layer
//  provides an implementation backed by `LAContext` (and a mock for tests).
//

import Foundation

public protocol AuthRepository: AnyObject, Sendable {

    /// Whether the device has biometry enrolled and available *right now*.
    var isBiometryAvailable: Bool { get }

    /// Prompts the user to authenticate. Falls back to device passcode where supported.
    /// - Parameter reason: Human-readable explanation shown in the system prompt.
    func authenticate(reason: String) async -> AuthOutcome
}

//
//  AccountAuthError.swift
//  UginsVault — Domain layer
//
//  Framework-agnostic auth failures surfaced by `AccountRepository`. The Data
//  layer maps Supabase / transport errors onto these cases so the Presentation
//  layer never sees an SDK type.
//

import Foundation

public enum AccountAuthError: Error, Equatable, LocalizedError {

    /// Email/password rejected by the auth server.
    case invalidCredentials

    /// The account exists but its email hasn't been confirmed yet.
    case emailNotConfirmed

    /// Network / transport failure reaching the auth server.
    case network

    /// Any other failure — carries a human-readable message for display.
    case unknown(message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return String(localized: "Incorrect email or password.")
        case .emailNotConfirmed:
            return String(localized: "Confirm your email before signing in.")
        case .network:
            return String(localized: "Couldn't reach the server. Check your connection.")
        case .unknown(let message):
            return message
        }
    }
}

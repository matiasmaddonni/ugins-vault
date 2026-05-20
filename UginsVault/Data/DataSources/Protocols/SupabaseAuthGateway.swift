//
//  SupabaseAuthGateway.swift
//  UginsVault — Data layer
//
//  Thin seam over the Supabase Auth SDK so `SupabaseAccountRepository` stays
//  free of the SDK and unit-testable. The live implementation wraps
//  `AuthClient`; tests inject a fake.
//

import Foundation

/// Minimal session info the repository needs — decoupled from the SDK's
/// `Session` type.
public struct AccountSession: Sendable, Equatable {
    public let email: String?
    public let accessToken: String

    public init(email: String?, accessToken: String) {
        self.email = email
        self.accessToken = accessToken
    }
}

public protocol SupabaseAuthGateway: Sendable {

    /// Email/password sign-in.
    /// - Throws: `AccountAuthError` on failure.
    func signIn(email: String, password: String) async throws -> AccountSession

    /// Clears this device's session.
    func signOut() async

    /// A valid (refreshed) session, or `nil` when there is nothing to restore.
    func refreshedSession() async -> AccountSession?
}

//
//  SupabaseAccountRepository.swift
//  UginsVault — Data layer
//
//  `AccountRepository` over a `SupabaseAuthGateway`. Email/password sign-in,
//  Keychain-persisted session, and automatic token refresh are handled by the
//  gateway's SDK-backed implementation; this type only mirrors the resulting
//  identity into observable state. Also fronts the `AccessTokenProviding` seam
//  the backend API client consumes, so the API client never imports the SDK.
//

import Foundation
import Observation

@MainActor
@Observable
public final class SupabaseAccountRepository: AccountRepository, AccessTokenProviding {

    // MARK: - Observable state

    public private(set) var isSignedIn: Bool
    public private(set) var userEmail: String?

    // MARK: - Dependencies

    @ObservationIgnored private let gateway: SupabaseAuthGateway

    // MARK: - Init

    public init(gateway: SupabaseAuthGateway) {
        self.gateway = gateway

        // Start signed-out and cheap — no SDK/Keychain work on the launch path.
        // `restore()` (async, off-main) establishes the real state once the
        // splash is on screen.
        self.isSignedIn = false
        self.userEmail = nil
    }

    // MARK: - AccountRepository

    public func signIn(email: String, password: String) async throws {
        let session = try await gateway.signIn(email: email, password: password)
        isSignedIn = true
        userEmail = session.email
    }

    public func signOut() async {
        await gateway.signOut()
        isSignedIn = false
        userEmail = nil
    }

    public func restore() async {
        if let session = await gateway.refreshedSession() {
            isSignedIn = true
            userEmail = session.email
        } else {
            isSignedIn = false
            userEmail = nil
        }
    }

    // MARK: - AccessTokenProviding

    public func accessToken() async -> String? {
        await gateway.refreshedSession()?.accessToken
    }
}

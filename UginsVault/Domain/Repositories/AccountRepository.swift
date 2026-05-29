//
//  AccountRepository.swift
//  UginsVault — Domain layer
//
//  Abstracts the user's backend identity (Supabase account) away from the
//  Presentation layer. The Data layer provides an implementation backed by the
//  Supabase Auth SDK; tests inject a mock.
//
//  This protocol is intentionally identity-only. The bearer access token used
//  to call the price API is an infrastructure concern and lives behind a
//  separate Data-layer seam, so the Domain stays free of transport details.
//

import Foundation
import Observation

@MainActor
public protocol AccountRepository: AnyObject, Observable, Sendable {

    /// Whether a valid (restorable) session currently exists.
    var isSignedIn: Bool { get }

    /// Email of the signed-in user, when known.
    var userEmail: String? { get }

    /// Signs in with email + password.
    /// - Throws: `AccountAuthError` on failure.
    func signIn(email: String, password: String) async throws

    /// Clears the local session.
    func signOut() async

    /// Restores any persisted session at launch. Safe to call repeatedly.
    func restore() async
}

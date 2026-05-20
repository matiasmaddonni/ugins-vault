//
//  MockAccountRepository.swift
//  UginsVaultTests
//

import Foundation
import Observation
@testable import UginsVault

@Observable
@MainActor
final class MockAccountRepository: AccountRepository {

    // Observable state
    var isSignedIn: Bool = false
    var userEmail: String?

    // Stubs
    @ObservationIgnored var stubbedSignInError: Error?
    @ObservationIgnored var stubbedSignInEmail: String? = "user@example.com"
    @ObservationIgnored var restoresToSignedIn: Bool = false
    @ObservationIgnored var restoredEmail: String?

    // Spies
    @ObservationIgnored private(set) var signInCallCount = 0
    @ObservationIgnored private(set) var signOutCallCount = 0
    @ObservationIgnored private(set) var restoreCallCount = 0
    @ObservationIgnored private(set) var lastSignInEmail: String?
    @ObservationIgnored private(set) var lastSignInPassword: String?

    func signIn(email: String, password: String) async throws {
        signInCallCount += 1
        lastSignInEmail = email
        lastSignInPassword = password
        await Task.yield()
        if let stubbedSignInError { throw stubbedSignInError }
        isSignedIn = true
        userEmail = stubbedSignInEmail
    }

    func signOut() async {
        signOutCallCount += 1
        isSignedIn = false
        userEmail = nil
    }

    func restore() async {
        restoreCallCount += 1
        await Task.yield()
        isSignedIn = restoresToSignedIn
        userEmail = restoresToSignedIn ? restoredEmail : nil
    }
}

//
//  MockAuthRepository.swift
//  UginsVaultTests
//

import Foundation
@testable import UginsVault

final class MockAuthRepository: AuthRepositoryProtocol, @unchecked Sendable {

    // Stubs
    var stubbedIsBiometryAvailable: Bool = true
    var stubbedAuthenticateOutcome: AuthOutcome = .success

    // Spies
    private(set) var authenticateCallCount: Int = 0
    private(set) var lastReason: String?

    var isBiometryAvailable: Bool { stubbedIsBiometryAvailable }

    func authenticate(reason: String) async -> AuthOutcome {
        authenticateCallCount += 1
        lastReason = reason
        return stubbedAuthenticateOutcome
    }
}

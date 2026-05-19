//
//  MockAuthRepository.swift
//  UginsVaultTests
//

import Foundation
import Observation
@testable import UginsVault

@Observable
final class MockAuthRepository: AuthRepository, @unchecked Sendable {

    // Stubs
    @ObservationIgnored var stubbedIsBiometryAvailable: Bool = true
    @ObservationIgnored var stubbedAuthenticateOutcome: AuthOutcome = .success

    // Spies
    @ObservationIgnored private(set) var authenticateCallCount: Int = 0
    @ObservationIgnored private(set) var lastReason: String?

    var isBiometryAvailable: Bool { stubbedIsBiometryAvailable }

    func authenticate(reason: String) async -> AuthOutcome {
        authenticateCallCount += 1
        lastReason = reason
        return stubbedAuthenticateOutcome
    }
}

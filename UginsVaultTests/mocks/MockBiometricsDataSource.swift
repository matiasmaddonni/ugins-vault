//
//  MockBiometricsDataSource.swift
//  UginsVaultTests
//

import Foundation
@testable import UginsVault

final class MockBiometricsDataSource: BiometricsDataSource, @unchecked Sendable {

    var stubbedIsAvailable: Bool = true
    var stubbedOutcome: AuthOutcome = .success
    private(set) var authenticateCallCount: Int = 0

    var isAvailable: Bool { stubbedIsAvailable }

    func authenticate(reason: String) async -> AuthOutcome {
        authenticateCallCount += 1
        return stubbedOutcome
    }
}

//
//  AuthRepositoryTests.swift
//  UginsVaultTests — Data
//

import Testing
@testable import UginsVault

@Suite("AuthRepository")
struct AuthRepositoryTests {

    @Test("Forwards isBiometryAvailable from data source")
    func forwardsAvailability() {
        let ds = MockBiometricsDataSource()
        ds.stubbedIsAvailable = false
        let sut = LocalAuthRepository(biometrics: ds)

        #expect(sut.isBiometryAvailable == false)
    }

    @Test("Forwards authenticate() outcome and call count")
    func forwardsAuthenticate() async {
        let ds = MockBiometricsDataSource()
        ds.stubbedOutcome = .userCancelled
        let sut = LocalAuthRepository(biometrics: ds)

        let outcome = await sut.authenticate(reason: "test")

        #expect(outcome == .userCancelled)
        #expect(ds.authenticateCallCount == 1)
    }
}

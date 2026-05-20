//
//  AccountAuthErrorTests.swift
//  UginsVaultTests — Domain
//

import Testing
@testable import UginsVault

@Suite("AccountAuthError")
struct AccountAuthErrorTests {

    @Test("every case has a non-empty description")
    func allCasesHaveDescriptions() {
        let cases: [AccountAuthError] = [
            .invalidCredentials,
            .emailNotConfirmed,
            .network,
            .unknown(message: "boom")
        ]
        for error in cases {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test("unknown surfaces its underlying message verbatim")
    func unknownMessage() {
        #expect(AccountAuthError.unknown(message: "boom").errorDescription == "boom")
    }
}

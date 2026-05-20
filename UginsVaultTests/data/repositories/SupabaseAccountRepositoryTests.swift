//
//  SupabaseAccountRepositoryTests.swift
//  UginsVaultTests — Data
//

import Testing
@testable import UginsVault

/// Single-threaded test fake — `@unchecked Sendable` is safe here.
final class FakeSupabaseAuthGateway: SupabaseAuthGateway, @unchecked Sendable {
    var signInResult: Result<AccountSession, Error> = .success(
        AccountSession(email: "u@x.com", accessToken: "tok")
    )
    var refreshed: AccountSession?
    private(set) var signOutCount = 0

    func signIn(email: String, password: String) async throws -> AccountSession {
        try signInResult.get()
    }

    func signOut() async { signOutCount += 1 }

    func refreshedSession() async -> AccountSession? { refreshed }
}

@Suite("SupabaseAccountRepository")
@MainActor
struct SupabaseAccountRepositoryTests {

    @Test("init is cheap and signed-out (no SDK work on the launch path)")
    func initSignedOut() {
        let sut = SupabaseAccountRepository(gateway: FakeSupabaseAuthGateway())

        #expect(sut.isSignedIn == false)
        #expect(sut.userEmail == nil)
    }

    @Test("signIn success updates state")
    func signInSuccess() async throws {
        let gateway = FakeSupabaseAuthGateway()
        gateway.signInResult = .success(AccountSession(email: "a@b.com", accessToken: "tok"))
        let sut = SupabaseAccountRepository(gateway: gateway)

        try await sut.signIn(email: "a@b.com", password: "pw")

        #expect(sut.isSignedIn)
        #expect(sut.userEmail == "a@b.com")
    }

    @Test("signIn failure stays signed-out and rethrows")
    func signInFailure() async {
        let gateway = FakeSupabaseAuthGateway()
        gateway.signInResult = .failure(AccountAuthError.invalidCredentials)
        let sut = SupabaseAccountRepository(gateway: gateway)

        await #expect(throws: AccountAuthError.invalidCredentials) {
            try await sut.signIn(email: "a@b.com", password: "x")
        }
        #expect(sut.isSignedIn == false)
    }

    @Test("signOut clears state and calls the gateway")
    func signOut() async {
        let gateway = FakeSupabaseAuthGateway()
        gateway.refreshed = AccountSession(email: "me@x.com", accessToken: "t")
        let sut = SupabaseAccountRepository(gateway: gateway)
        await sut.restore() // sign in first
        #expect(sut.isSignedIn)

        await sut.signOut()

        #expect(sut.isSignedIn == false)
        #expect(sut.userEmail == nil)
        #expect(gateway.signOutCount == 1)
    }

    @Test("restore reflects a refreshed session")
    func restoreSignedIn() async {
        let gateway = FakeSupabaseAuthGateway()
        gateway.refreshed = AccountSession(email: "me@x.com", accessToken: "t")
        let sut = SupabaseAccountRepository(gateway: gateway)

        await sut.restore()

        #expect(sut.isSignedIn)
        #expect(sut.userEmail == "me@x.com")
    }

    @Test("restore signs out when nothing can be refreshed")
    func restoreSignedOut() async {
        let gateway = FakeSupabaseAuthGateway()
        gateway.refreshed = AccountSession(email: "me@x.com", accessToken: "t")
        let sut = SupabaseAccountRepository(gateway: gateway)
        await sut.restore()
        #expect(sut.isSignedIn)

        gateway.refreshed = nil
        await sut.restore()

        #expect(sut.isSignedIn == false)
        #expect(sut.userEmail == nil)
    }

    @Test("accessToken returns the refreshed token")
    func accessToken() async {
        let gateway = FakeSupabaseAuthGateway()
        gateway.refreshed = AccountSession(email: nil, accessToken: "tok-123")
        let sut = SupabaseAccountRepository(gateway: gateway)

        let token = await sut.accessToken()

        #expect(token == "tok-123")
    }
}

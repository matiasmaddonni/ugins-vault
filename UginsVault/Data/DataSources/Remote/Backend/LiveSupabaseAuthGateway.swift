//
//  LiveSupabaseAuthGateway.swift
//  UginsVault — Data layer / Backend
//
//  `SupabaseAuthGateway` backed by the Supabase Auth SDK. Owns the `AuthClient`
//  (configured with `KeychainLocalStorage`, the SDK's default Keychain store)
//  and translates SDK / transport errors into the domain's `AccountAuthError`.
//  This is the only file in the auth path that imports the SDK.
//
//  The `AuthClient` is built lazily on first use: constructing it (and its
//  first Keychain access) is kept OFF the launch / first-frame path so the
//  splash paints immediately. All public methods here are `async` and run off
//  the main actor.
//

import Foundation
import Auth

public final class LiveSupabaseAuthGateway: SupabaseAuthGateway, @unchecked Sendable {

    private let lock = NSLock()
    private var cachedClient: AuthClient?

    public init() {}

    /// Lazily builds the `AuthClient`. Guarded so concurrent first calls share
    /// one instance.
    private var client: AuthClient {
        lock.lock()
        defer { lock.unlock() }
        if let cachedClient { return cachedClient }
        let configuration = AuthClient.Configuration(
            url: BackendConfig.supabaseURL.appendingPathComponent("auth/v1"),
            headers: [
                "apikey": BackendConfig.supabaseAnonKey,
                "Authorization": "Bearer \(BackendConfig.supabaseAnonKey)"
            ],
            localStorage: KeychainLocalStorage(),
            logger: nil
        )
        let client = AuthClient(configuration: configuration)
        cachedClient = client
        return client
    }

    public func signIn(email: String, password: String) async throws -> AccountSession {
        do {
            let session = try await client.signIn(email: email, password: password)
            return Self.session(from: session)
        } catch {
            throw Self.map(error)
        }
    }

    public func signOut() async {
        // `.local` clears this device's session without a server round-trip.
        try? await client.signOut(scope: .local)
    }

    public func refreshedSession() async -> AccountSession? {
        // `session` loads from the Keychain and refreshes if expired; throws
        // `AuthError.sessionMissing` when there is nothing to restore.
        guard let session = try? await client.session else { return nil }
        return Self.session(from: session)
    }

    // MARK: - Mapping

    private static func session(from session: Session) -> AccountSession {
        AccountSession(email: session.user.email, accessToken: session.accessToken)
    }

    /// Collapses Supabase / transport errors onto the domain's
    /// `AccountAuthError`.
    private static func map(_ error: Error) -> AccountAuthError {
        if let authError = error as? AuthError {
            switch authError {
            case let .api(_, errorCode, _, _):
                let code = errorCode.rawValue.lowercased()
                if code.contains("email_not_confirmed") { return .emailNotConfirmed }
                if code.contains("invalid") || code.contains("credentials") {
                    return .invalidCredentials
                }
                return .unknown(message: authError.message)
            case .sessionMissing:
                return .invalidCredentials
            default:
                return .unknown(message: authError.message)
            }
        }
        if error is URLError { return .network }
        return .unknown(message: error.localizedDescription)
    }
}

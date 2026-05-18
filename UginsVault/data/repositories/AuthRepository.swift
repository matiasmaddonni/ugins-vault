//
//  AuthRepository.swift
//  UginsVault — Data layer
//
//  Default implementation of `AuthRepositoryProtocol`. Thin pass-through to a
//  `BiometricsDataSource` — kept separate so future flows (e.g. cached
//  session token, lockout cooldown) have a place to live.
//

import Foundation

public final class AuthRepository: AuthRepositoryProtocol {

    private let biometrics: BiometricsDataSourceProtocol

    public init(biometrics: BiometricsDataSourceProtocol) {
        self.biometrics = biometrics
    }

    public var isBiometryAvailable: Bool {
        biometrics.isAvailable
    }

    public func authenticate(reason: String) async -> AuthOutcome {
        await biometrics.authenticate(reason: reason)
    }
}

//
//  LocalAuthRepository.swift
//  UginsVault — Data layer
//
//  Default implementation of the `AuthRepository` domain protocol. Thin
//  pass-through to a `BiometricsDataSource` — kept separate so future flows
//  (e.g. cached session token, lockout cooldown) have a place to live.
//

import Foundation
import Observation

@Observable
public final class LocalAuthRepository: AuthRepository {

    @ObservationIgnored private let biometrics: BiometricsDataSource

    public init(biometrics: BiometricsDataSource) {
        self.biometrics = biometrics
    }

    public var isBiometryAvailable: Bool {
        biometrics.isAvailable
    }

    public func authenticate(reason: String) async -> AuthOutcome {
        await biometrics.authenticate(reason: reason)
    }
}

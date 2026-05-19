//
//  LocalBiometricsDataSource.swift
//  UginsVault — Data layer
//
//  Live biometrics data source backed by `LAContext`. Maps every `LAError`
//  code into the framework-agnostic `AuthOutcome` cases the Domain layer
//  understands.
//

import Foundation
import LocalAuthentication

public final class LocalBiometricsDataSource: BiometricsDataSource, @unchecked Sendable {

    public init() {}

    public var isAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    public func authenticate(reason: String) async -> AuthOutcome {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .unavailable
        }

        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return ok ? .success : .failed(reason: "Authentication failed")
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                return .userCancelled
            case .userFallback:
                return .fallback
            case .biometryNotEnrolled, .biometryNotAvailable, .passcodeNotSet:
                return .unavailable
            default:
                return .failed(reason: laError.localizedDescription)
            }
        } catch {
            return .failed(reason: error.localizedDescription)
        }
    }
}

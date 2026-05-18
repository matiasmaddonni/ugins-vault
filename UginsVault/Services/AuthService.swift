//
//  AuthService.swift
//  UginsVault
//
//  Thin wrapper over LocalAuthentication. Stateless.
//  Caller drives state transitions on .success / .failure.
//

import Foundation
import LocalAuthentication

enum AuthOutcome: Equatable {
    case success
    case userCancelled
    case fallback        // user tapped "Enter PIN" (or biometry not enrolled)
    case unavailable     // device has no biometry / no passcode
    case failed(String)  // generic failure with message
}

enum AuthService {
    /// Returns the biometry kind available on the device, or nil if none.
    static var biometry: LABiometryType {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return ctx.biometryType
    }

    /// Prompts for biometric authentication. Falls back to device passcode if available.
    static func authenticate(reason: String = "Unlock your vault") async -> AuthOutcome {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Use Passcode"

        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .unavailable
        }

        do {
            let ok = try await ctx.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return ok ? .success : .failed("Authentication failed")
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                return .userCancelled
            case .userFallback:
                return .fallback
            case .biometryNotEnrolled, .biometryNotAvailable, .passcodeNotSet:
                return .unavailable
            default:
                return .failed(laError.localizedDescription)
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}

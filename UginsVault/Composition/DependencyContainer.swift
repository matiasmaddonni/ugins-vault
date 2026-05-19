//
//  DependencyContainer.swift
//  UginsVault — Dependency Injection
//
//  Singleton container with factory methods. Wires the three layers together.
//  Tests instantiate their own use cases with mocks — they do not go through
//  this container.
//
//  Conventions:
//  • Long-lived shared instances (data sources, repositories) are `lazy var`.
//  • Use cases are *factory* methods (`make…UseCase`) — each call produces a
//    fresh instance so unit-of-work scoping is explicit.
//  • ViewModel factories return new instances on every call; views own them
//    via `@State` and never recreate them mid-lifecycle.
//

import Foundation

public final class DependencyContainer {

    // MARK: - Singleton

    public static let shared = DependencyContainer()

    private init() {}

    // MARK: - Data sources

    public lazy var biometricsDataSource: BiometricsDataSource = LocalBiometricsDataSource()
    public lazy var sessionStorage:       SessionStorageDataSource = UserDefaultsSessionStorage()

    // MARK: - Repositories

    public lazy var authRepository:    AuthRepository    = LocalAuthRepository(biometrics: biometricsDataSource)
    public lazy var sessionRepository: SessionRepository = UserDefaultsSessionRepository(storage: sessionStorage)

    // MARK: - Use case factories

    public func makeAuthenticateUseCase() -> AuthenticateUseCase {
        AuthenticateUseCase(authRepository: authRepository, sessionRepository: sessionRepository)
    }

    public func makeGetCurrentPhaseUseCase() -> GetCurrentPhaseUseCase {
        GetCurrentPhaseUseCase(sessionRepository: sessionRepository)
    }

    public func makeAdvanceFromSplashUseCase() -> AdvanceFromSplashUseCase {
        AdvanceFromSplashUseCase(sessionRepository: sessionRepository)
    }

    public func makeSignOutUseCase() -> SignOutUseCase {
        SignOutUseCase(sessionRepository: sessionRepository)
    }

    // MARK: - ViewModel factories

    @MainActor public func makeRootViewModel() -> RootViewModel {
        RootViewModel(
            getCurrentPhaseUseCase: makeGetCurrentPhaseUseCase()
        )
    }

    @MainActor public func makeSplashViewModel(onAdvance: @escaping (AppPhase) -> Void) -> SplashViewModel {
        SplashViewModel(
            advanceFromSplashUseCase: makeAdvanceFromSplashUseCase(),
            onAdvance: onAdvance
        )
    }

    @MainActor public func makeLoginViewModel(onAuthenticated: @escaping () -> Void) -> LoginViewModel {
        LoginViewModel(
            authenticateUseCase: makeAuthenticateUseCase(),
            isBiometryAvailable: authRepository.isBiometryAvailable,
            onAuthenticated: onAuthenticated
        )
    }

    @MainActor public func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            sessionRepository: sessionRepository
        )
    }
}

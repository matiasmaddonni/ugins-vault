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

@MainActor
public final class DependencyContainer {

    // MARK: - Singleton

    public static let shared = DependencyContainer()

    private init() {}

    // MARK: - Data sources

    public lazy var biometricsDataSource: BiometricsDataSource = LocalBiometricsDataSource()
    public lazy var sessionStorage:       SessionStorageDataSource = UserDefaultsSessionStorage()
    public lazy var scryfallClient:       any ScryfallClientProtocol = ScryfallClient()

    // MARK: - Repositories

    public lazy var authRepository:        AuthRepository        = LocalAuthRepository(biometrics: biometricsDataSource)
    public lazy var sessionRepository:     SessionRepository     = UserDefaultsSessionRepository(storage: sessionStorage)
    public lazy var userProfileRepository: UserProfileRepository = UserDefaultsUserProfileRepository(storage: sessionStorage)

    // MARK: - Use case factories — auth

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

    // MARK: - Use case factories — preferences

    public func makeGetThemeUseCase() -> GetThemeUseCase {
        GetThemeUseCase(sessionRepository: sessionRepository)
    }

    public func makeSetThemeUseCase() -> SetThemeUseCase {
        SetThemeUseCase(sessionRepository: sessionRepository)
    }

    public func makeGetPreferredLanguageUseCase() -> GetPreferredLanguageUseCase {
        GetPreferredLanguageUseCase(sessionRepository: sessionRepository)
    }

    public func makeSetPreferredLanguageUseCase() -> SetPreferredLanguageUseCase {
        SetPreferredLanguageUseCase(sessionRepository: sessionRepository)
    }

    public func makeGetCurrencyUseCase() -> GetCurrencyUseCase {
        GetCurrencyUseCase(sessionRepository: sessionRepository)
    }

    public func makeSetCurrencyUseCase() -> SetCurrencyUseCase {
        SetCurrencyUseCase(sessionRepository: sessionRepository)
    }

    public func makeGetReduceMotionUseCase() -> GetReduceMotionUseCase {
        GetReduceMotionUseCase(sessionRepository: sessionRepository)
    }

    public func makeSetReduceMotionUseCase() -> SetReduceMotionUseCase {
        SetReduceMotionUseCase(sessionRepository: sessionRepository)
    }

    public func makeGetFaceIDLockUseCase() -> GetFaceIDLockUseCase {
        GetFaceIDLockUseCase(sessionRepository: sessionRepository)
    }

    public func makeSetFaceIDLockUseCase() -> SetFaceIDLockUseCase {
        SetFaceIDLockUseCase(sessionRepository: sessionRepository)
    }

    // MARK: - Use case factories — profile

    public func makeGetUserProfileUseCase() -> GetUserProfileUseCase {
        GetUserProfileUseCase(userProfileRepository: userProfileRepository)
    }

    public func makeUpdateUserProfileUseCase() -> UpdateUserProfileUseCase {
        UpdateUserProfileUseCase(userProfileRepository: userProfileRepository)
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

    @MainActor public func makeCollectionViewModel() -> CollectionViewModel {
        CollectionViewModel(
            sessionRepository: sessionRepository
        )
    }

    @MainActor public func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            sessionRepository:           sessionRepository,
            userProfileRepository:       userProfileRepository,
            getThemeUseCase:             makeGetThemeUseCase(),
            setThemeUseCase:             makeSetThemeUseCase(),
            getPreferredLanguageUseCase: makeGetPreferredLanguageUseCase(),
            setPreferredLanguageUseCase: makeSetPreferredLanguageUseCase(),
            getCurrencyUseCase:          makeGetCurrencyUseCase(),
            setCurrencyUseCase:          makeSetCurrencyUseCase(),
            getReduceMotionUseCase:      makeGetReduceMotionUseCase(),
            setReduceMotionUseCase:      makeSetReduceMotionUseCase(),
            getFaceIDLockUseCase:        makeGetFaceIDLockUseCase(),
            setFaceIDLockUseCase:        makeSetFaceIDLockUseCase(),
            getUserProfileUseCase:       makeGetUserProfileUseCase(),
            updateUserProfileUseCase:    makeUpdateUserProfileUseCase()
        )
    }
}

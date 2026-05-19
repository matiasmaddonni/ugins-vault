//
//  SettingsViewModel.swift
//  UginsVault — Presentation: Settings
//
//  Surfaces the four user-controlled preferences (theme, language,
//  currency, reduce-motion, Face ID lock) plus the local profile. All
//  mutations go through use cases so business logic stays out of the VM.
//

import Foundation
import Observation

@MainActor
@Observable
public final class SettingsViewModel {

    // MARK: - Dependencies

    @ObservationIgnored private let sessionRepository:    SessionRepository
    @ObservationIgnored private let userProfileRepo:      UserProfileRepository

    @ObservationIgnored private let getThemeUseCase:      GetThemeUseCase
    @ObservationIgnored private let setThemeUseCase:      SetThemeUseCase
    @ObservationIgnored private let getLanguageUseCase:   GetPreferredLanguageUseCase
    @ObservationIgnored private let setLanguageUseCase:   SetPreferredLanguageUseCase
    @ObservationIgnored private let getCurrencyUseCase:   GetCurrencyUseCase
    @ObservationIgnored private let setCurrencyUseCase:   SetCurrencyUseCase
    @ObservationIgnored private let getReduceMotionUC:    GetReduceMotionUseCase
    @ObservationIgnored private let setReduceMotionUC:    SetReduceMotionUseCase
    @ObservationIgnored private let getFaceIDLockUseCase: GetFaceIDLockUseCase
    @ObservationIgnored private let setFaceIDLockUseCase: SetFaceIDLockUseCase
    @ObservationIgnored private let getProfileUseCase:    GetUserProfileUseCase
    @ObservationIgnored private let updateProfileUseCase: UpdateUserProfileUseCase

    // MARK: - Init

    public init(
        sessionRepository: SessionRepository,
        userProfileRepository: UserProfileRepository,
        getThemeUseCase: GetThemeUseCase,
        setThemeUseCase: SetThemeUseCase,
        getPreferredLanguageUseCase: GetPreferredLanguageUseCase,
        setPreferredLanguageUseCase: SetPreferredLanguageUseCase,
        getCurrencyUseCase: GetCurrencyUseCase,
        setCurrencyUseCase: SetCurrencyUseCase,
        getReduceMotionUseCase: GetReduceMotionUseCase,
        setReduceMotionUseCase: SetReduceMotionUseCase,
        getFaceIDLockUseCase: GetFaceIDLockUseCase,
        setFaceIDLockUseCase: SetFaceIDLockUseCase,
        getUserProfileUseCase: GetUserProfileUseCase,
        updateUserProfileUseCase: UpdateUserProfileUseCase
    ) {
        self.sessionRepository    = sessionRepository
        self.userProfileRepo      = userProfileRepository
        self.getThemeUseCase      = getThemeUseCase
        self.setThemeUseCase      = setThemeUseCase
        self.getLanguageUseCase   = getPreferredLanguageUseCase
        self.setLanguageUseCase   = setPreferredLanguageUseCase
        self.getCurrencyUseCase   = getCurrencyUseCase
        self.setCurrencyUseCase   = setCurrencyUseCase
        self.getReduceMotionUC    = getReduceMotionUseCase
        self.setReduceMotionUC    = setReduceMotionUseCase
        self.getFaceIDLockUseCase = getFaceIDLockUseCase
        self.setFaceIDLockUseCase = setFaceIDLockUseCase
        self.getProfileUseCase    = getUserProfileUseCase
        self.updateProfileUseCase = updateUserProfileUseCase
    }

    // MARK: - Derived state (reads observable repos directly)

    public var theme:        AppTheme    { getThemeUseCase.execute() }
    public var language:     Language    { getLanguageUseCase.execute() }
    public var currency:     Currency    { getCurrencyUseCase.execute() }
    public var reduceMotion: Bool        { getReduceMotionUC.execute() }
    public var faceIDLock:   Bool        { getFaceIDLockUseCase.execute() }
    public var profile:      UserProfile { getProfileUseCase.execute() }

    // MARK: - Intents

    public func setTheme(_ theme: AppTheme) {
        setThemeUseCase.execute(theme)
    }

    public func setLanguage(_ language: Language) {
        setLanguageUseCase.execute(language)
    }

    public func setCurrency(_ currency: Currency) {
        setCurrencyUseCase.execute(currency)
    }

    public func setReduceMotion(_ value: Bool) {
        setReduceMotionUC.execute(value)
    }

    public func setFaceIDLock(_ value: Bool) {
        setFaceIDLockUseCase.execute(value)
        if value == false {
            // Disabling Face ID also clears the lock-on-background gate.
            // (Lock-on-background is gated to faceIDLock = true in the UI.)
        }
    }

    public func updateProfile(_ profile: UserProfile) {
        updateProfileUseCase.execute(profile)
    }
}

//
//  SettingsViewModel.swift
//  UginsVault — Presentation: Settings
//
//  Surfaces the user-controlled preferences (theme, language, currency,
//  reduce-motion, Face ID lock), the local profile, and the
//  data-management surface (catalogue size + reset). All mutations go
//  through use cases so business logic stays out of the VM.
//

import Foundation
import Observation

@MainActor
@Observable
public final class SettingsViewModel {

    // MARK: - Data-management status

    public enum DataStatus: Equatable {
        case idle
        case resetting(savedSoFar: Int)
        case error(message: String)
    }

    // MARK: - Observable state

    public private(set) var catalogueCount: Int = 0
    public private(set) var dataStatus: DataStatus = .idle

    // MARK: - Dependencies

    @ObservationIgnored private let sessionRepository:    SessionRepository
    @ObservationIgnored private let userProfileRepo:      UserProfileRepository
    @ObservationIgnored private let cardRepository:       CardRepository

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
    @ObservationIgnored private let resetCatalogue:       ResetCatalogueUseCase

    /// Seed query used when the user taps "Reset catalogue". Matches the
    /// CollectionViewModel default so the reset lands on the same set.
    @ObservationIgnored private let seedQuery: String

    // MARK: - Init

    public init(
        sessionRepository: SessionRepository,
        userProfileRepository: UserProfileRepository,
        cardRepository: CardRepository,
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
        updateUserProfileUseCase: UpdateUserProfileUseCase,
        resetCatalogueUseCase: ResetCatalogueUseCase,
        seedQuery: String = "set:fdn"
    ) {
        self.sessionRepository    = sessionRepository
        self.userProfileRepo      = userProfileRepository
        self.cardRepository       = cardRepository
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
        self.resetCatalogue       = resetCatalogueUseCase
        self.seedQuery            = seedQuery
    }

    // MARK: - Derived state (reads observable repos directly)

    public var theme:        AppTheme    { getThemeUseCase.execute() }
    public var language:     Language    { getLanguageUseCase.execute() }
    public var currency:     Currency    { getCurrencyUseCase.execute() }
    public var reduceMotion: Bool        { getReduceMotionUC.execute() }
    public var faceIDLock:   Bool        { getFaceIDLockUseCase.execute() }
    public var profile:      UserProfile { getProfileUseCase.execute() }

    public var isResetting: Bool {
        if case .resetting = dataStatus { return true }
        return false
    }

    // MARK: - Lifecycle

    public func onAppear() async {
        await refreshCatalogueCount()
    }

    // MARK: - Preference intents

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
    }

    public func updateProfile(_ profile: UserProfile) {
        updateProfileUseCase.execute(profile)
    }

    // MARK: - Data intents

    public func refreshCatalogueCount() async {
        do {
            catalogueCount = try await cardRepository.totalCount()
        } catch {
            dataStatus = .error(message: error.localizedDescription)
        }
    }

    /// Wipes the local catalogue and re-seeds it from Scryfall.
    public func resetCatalogueNow() async {
        dataStatus = .resetting(savedSoFar: 0)

        do {
            let saved = try await resetCatalogue.execute(
                seedQuery: seedQuery,
                progress: { [weak self] progress in
                    Task { @MainActor in
                        self?.dataStatus = .resetting(savedSoFar: progress.savedCount)
                    }
                }
            )
            catalogueCount = saved
            dataStatus = .idle
        } catch {
            dataStatus = .error(message: error.localizedDescription)
        }
    }
}

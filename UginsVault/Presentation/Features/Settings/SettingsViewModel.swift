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
        case clearing
        case error(message: String)
    }

    // MARK: - Observable state

    public private(set) var catalogueCount: Int = 0
    public private(set) var dataStatus: DataStatus = .idle

    /// Profile hero stat-strip values: owned collection value (USD) +
    /// number of deck-kind stacks. `nil` until `loadProfileStats()` runs.
    public private(set) var ownedValueUSD: Decimal?
    public private(set) var deckCount: Int?

    // MARK: - Dependencies

    @ObservationIgnored private let sessionRepository:    SessionStateStore
    @ObservationIgnored private let userProfileRepo:      UserProfileRepository
    @ObservationIgnored private let cardRepository:       CardRepository
    @ObservationIgnored private let dashboardRepository:  DashboardRepository?
    @ObservationIgnored private let stackRepository:      StackRepository?
    @ObservationIgnored private let exchangeRateRepository: ExchangeRateRepository?

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
    @ObservationIgnored private let hardReset:            HardResetCollectionUseCase?
    @ObservationIgnored private let signOutAccount:       SignOutAccountUseCase
    @ObservationIgnored private let onSignedOut:          () -> Void
    @ObservationIgnored private let accountRepository:    AccountRepository

    // MARK: - Init

    public init(
        sessionRepository: SessionStateStore,
        userProfileRepository: UserProfileRepository,
        cardRepository: CardRepository,
        dashboardRepository: DashboardRepository? = nil,
        stackRepository: StackRepository? = nil,
        exchangeRateRepository: ExchangeRateRepository? = nil,
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
        hardResetUseCase: HardResetCollectionUseCase? = nil,
        signOutAccount: SignOutAccountUseCase,
        accountRepository: AccountRepository,
        onSignedOut: @escaping () -> Void = {}
    ) {
        self.sessionRepository    = sessionRepository
        self.userProfileRepo      = userProfileRepository
        self.cardRepository       = cardRepository
        self.dashboardRepository  = dashboardRepository
        self.stackRepository      = stackRepository
        self.exchangeRateRepository = exchangeRateRepository
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
        self.hardReset            = hardResetUseCase
        self.signOutAccount       = signOutAccount
        self.onSignedOut          = onSignedOut
        self.accountRepository    = accountRepository
    }

    /// Email of the signed-in backend account, or `nil` in local-only mode.
    public var accountEmail: String? { accountRepository.userEmail }

    // MARK: - Account

    /// Clears the backend session, then asks the root router to return to the
    /// account-login screen.
    public func signOut() async {
        await signOutAccount.execute()
        onSignedOut()
    }

    // MARK: - Derived state (reads observable repos directly)

    public var theme:        AppTheme    { getThemeUseCase.execute() }
    public var language:     Language    { getLanguageUseCase.execute() }
    public var currency:     Currency    { getCurrencyUseCase.execute() }
    public var reduceMotion: Bool        { getReduceMotionUC.execute() }
    public var faceIDLock:   Bool        { getFaceIDLockUseCase.execute() }
    public var profile:      UserProfile { getProfileUseCase.execute() }

    /// Owned-collection value formatted in the active display currency
    /// (FX-converted when a rate is available). `nil` until
    /// `loadProfileStats()` populates `ownedValueUSD`.
    public var profileValueLabel: String? {
        ownedValueUSD.map {
            CurrencyFormatter.format(
                $0,
                currency: currency,
                rate: exchangeRateRepository?.rate(toQuote: currency)
            )
        }
    }

    public var isResetting: Bool {
        if case .clearing = dataStatus { return true }
        return false
    }

    // MARK: - Lifecycle

    public func onAppear() async {
        await refreshCatalogueCount()
        await loadProfileStats()
    }

    /// Populates the profile hero stat strip: owned collection value
    /// (reuses the shared Dashboard snapshot — fetched once if the
    /// Dashboard tab hasn't already produced it) + the number of deck
    /// stacks.
    public func loadProfileStats() async {
        if let dashboardRepository {
            if dashboardRepository.snapshot == nil {
                _ = try? await dashboardRepository.fetch()
            }
            ownedValueUSD = dashboardRepository.snapshot?.totalValueUSD
        }
        if let stackRepository, let stacks = try? await stackRepository.refresh() {
            deckCount = stacks.filter { $0.kind == .deck }.count
        }
        // Keep FX fresh so the value label converts correctly.
        if let exchangeRateRepository {
            Task { try? await exchangeRateRepository.refresh() }
        }
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

    /// Real, full wipe: clears the entire collection on the backend AND the
    /// local cache (items + stacks + card catalogue), so the next launch's
    /// restore finds nothing to repopulate. Falls back to a local-only card
    /// wipe when the backend use case isn't wired (e.g. tests).
    public func clearCatalogueNow() async {
        dataStatus = .clearing
        do {
            if let hardReset {
                try await hardReset.execute()
            } else {
                try await resetCatalogue.execute()
            }
            catalogueCount = 0
            dataStatus = .idle
        } catch {
            dataStatus = .error(message: error.localizedDescription)
        }
    }
}

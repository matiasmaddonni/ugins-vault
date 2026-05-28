//
//  SettingsViewModel.swift
//  UginsVault — Presentation: Settings
//
//  Surfaces the user-controlled preferences (theme, language, currency,
//  reduce-motion, Face ID lock), the local profile, and the
//  data-management surface (catalogue size + reset).
//
//  Per `.claude/Architecture.md` the trivial Get/Set session/profile
//  use cases were inlined — `SessionStateStore` and `UserProfileStore`
//  are already the canonical access surface, and wrapping a single
//  property read/write in a one-line use case was pure ceremony. Real
//  business operations (clear catalogue, sign out, hard reset) still go
//  through their use cases.
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

    @ObservationIgnored private let sessionRepository:      SessionStateStore
    @ObservationIgnored private let userProfileRepo:        UserProfileStore
    @ObservationIgnored private let cardRepository:         CardRepository
    @ObservationIgnored private let dashboardRepository:    DashboardRepository?
    @ObservationIgnored private let stackRepository:        StackRepository?
    @ObservationIgnored private let exchangeRateRepository: ExchangeRateStore?

    @ObservationIgnored private let resetCatalogue:         ResetCatalogueUseCase
    @ObservationIgnored private let hardReset:              HardResetCollectionUseCase?
    @ObservationIgnored private let signOutAccount:         SignOutAccountUseCase
    @ObservationIgnored private let onSignedOut:            () -> Void
    @ObservationIgnored private let accountRepository:      AccountRepository

    // MARK: - Init

    public init(
        sessionRepository: SessionStateStore,
        userProfileRepository: UserProfileStore,
        cardRepository: CardRepository,
        dashboardRepository: DashboardRepository? = nil,
        stackRepository: StackRepository? = nil,
        exchangeRateRepository: ExchangeRateStore? = nil,
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

    // MARK: - Derived state (passthrough to the stores so views observe)

    public var theme:        AppTheme    { sessionRepository.theme }
    public var language:     Language    { sessionRepository.language }
    public var currency:     Currency    { sessionRepository.currency }
    public var reduceMotion: Bool        { sessionRepository.reduceMotion }
    public var faceIDLock:   Bool        { sessionRepository.faceIDLock }
    public var profile:      UserProfile { userProfileRepo.profile }

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
        sessionRepository.saveTheme(theme)
    }

    public func setLanguage(_ language: Language) {
        sessionRepository.saveLanguage(language)
    }

    public func setCurrency(_ currency: Currency) {
        sessionRepository.saveCurrency(currency)
    }

    public func setReduceMotion(_ value: Bool) {
        sessionRepository.saveReduceMotion(value)
    }

    public func setFaceIDLock(_ value: Bool) {
        sessionRepository.saveFaceIDLock(value)
    }

    public func updateProfile(_ profile: UserProfile) {
        userProfileRepo.save(profile)
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

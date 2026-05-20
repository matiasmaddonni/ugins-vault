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
import SwiftData

@MainActor
public final class DependencyContainer {

    // MARK: - Singleton

    public static let shared = DependencyContainer()

    private init() {}

    // MARK: - Data sources

    public lazy var biometricsDataSource: BiometricsDataSource = LocalBiometricsDataSource()
    public lazy var sessionStorage:       SessionStorageDataSource = UserDefaultsSessionStorage()
    public lazy var scryfallClient:       any ScryfallClientProtocol = ScryfallClient()
    public lazy var avatarStorage:        AvatarStorage = FileAvatarStorage()

    // MARK: - Repositories

    public lazy var authRepository:        AuthRepository        = LocalAuthRepository(biometrics: biometricsDataSource)
    public lazy var sessionRepository:     SessionRepository     = UserDefaultsSessionRepository(storage: sessionStorage)
    public lazy var userProfileRepository: UserProfileRepository = UserDefaultsUserProfileRepository(storage: sessionStorage)

    public lazy var modelContainer: ModelContainer = {
        // SwiftUI Previews don't share storage with the running simulator
        // and don't run schema migrations cleanly across edits — always
        // build an in-memory container there to keep #Preview crash-free.
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return Self.makeInMemoryContainer()
        }

        do {
            return try ModelContainer(
                for: SwiftDataCard.self,
                SwiftDataStack.self,
                SwiftDataCollectionItem.self,
                SwiftDataPriceSnapshot.self,
                SwiftDataWishlistItem.self
            )
        } catch {
            // On-disk store failed to open (most often a lightweight
            // migration failure after a schema bump). Fall back to a
            // fresh in-memory store so the app launches; the catalogue
            // simply re-seeds from Scryfall on first onAppear.
            return Self.makeInMemoryContainer()
        }
    }()

    private static func makeInMemoryContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(
                for: SwiftDataCard.self,
                SwiftDataStack.self,
                SwiftDataCollectionItem.self,
                SwiftDataPriceSnapshot.self,
                SwiftDataWishlistItem.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to construct in-memory ModelContainer: \(error)")
        }
    }

    public lazy var cardRepository: CardRepository = SwiftDataCardRepository(modelContainer: modelContainer)
    public lazy var stackRepository: StackRepository = SwiftDataStackRepository(modelContainer: modelContainer)
    public lazy var collectionItemRepository: CollectionItemRepository = SwiftDataCollectionItemRepository(modelContainer: modelContainer)
    public lazy var priceRepository: PriceRepository = SwiftDataPriceRepository(
        modelContainer: modelContainer,
        lastSyncStorage: sessionStorage
    )
    public lazy var wishlistRepository: WishlistRepository = SwiftDataWishlistRepository(modelContainer: modelContainer)

    // MARK: - Pricing wiring (v0.5)

    public lazy var networkReachability: NetworkReachability = NWPathReachability()
    public lazy var mtgjsonClient: MTGJSONClient = MTGJSONClient()
    public lazy var priceCatalogueSource: PriceCatalogueSource = MTGJSONPriceCatalogueSource(client: mtgjsonClient)

    // MARK: - FX wiring (v0.7)

    public lazy var dolarAPIClient: DolarAPIClient = DolarAPIClient()
    public lazy var frankfurterClient: FrankfurterClient = FrankfurterClient()
    public lazy var exchangeRateRepository: ExchangeRateRepository = RemoteExchangeRateRepository(
        dolarClient: dolarAPIClient,
        frankfurterClient: frankfurterClient,
        sessionRepository: sessionRepository,
        storage: sessionStorage
    )

    public lazy var cardCatalogueSource: CardCatalogueSource = ScryfallCardCatalogueSource(client: scryfallClient)

    // v0.6: real catalogue-derived stats; mock-only historical bits
    // (sparkline / gainers / losers / wishlist counts) come from
    // `MockDashboardRepository.seed` until the price-history backend
    // lands and we wire `RealDashboardSnapshotProducer.assemble(...)`.
    public lazy var dashboardRepository: DashboardRepository = RealDashboardRepository(
        cardRepository: cardRepository,
        collectionItemRepository: collectionItemRepository,
        stackRepository: stackRepository,
        priceRepository: priceRepository,
        sessionRepository: sessionRepository,
        wishlistRepository: wishlistRepository
    )

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

    // MARK: - Use case factories — catalogue

    public func makeSeedCatalogueUseCase() -> SeedCatalogueUseCase {
        SeedCatalogueUseCase(source: cardCatalogueSource, repository: cardRepository)
    }

    public func makeResetCatalogueUseCase() -> ResetCatalogueUseCase {
        ResetCatalogueUseCase(
            cardRepository: cardRepository,
            seedCatalogue: makeSeedCatalogueUseCase()
        )
    }

    // MARK: - Use case factories — pricing prefs

    public func makeGetPreferredPriceSourceUseCase() -> GetPreferredPriceSourceUseCase {
        GetPreferredPriceSourceUseCase(sessionRepository: sessionRepository)
    }

    public func makeSetPreferredPriceSourceUseCase() -> SetPreferredPriceSourceUseCase {
        SetPreferredPriceSourceUseCase(sessionRepository: sessionRepository)
    }

    public func makeGetDashboardMoverThresholdUseCase() -> GetDashboardMoverThresholdUseCase {
        GetDashboardMoverThresholdUseCase(sessionRepository: sessionRepository)
    }

    public func makeSetDashboardMoverThresholdUseCase() -> SetDashboardMoverThresholdUseCase {
        SetDashboardMoverThresholdUseCase(sessionRepository: sessionRepository)
    }

    public func makeGetManualARSRateUseCase() -> GetManualARSRateUseCase {
        GetManualARSRateUseCase(sessionRepository: sessionRepository)
    }

    public func makeSetManualARSRateUseCase() -> SetManualARSRateUseCase {
        SetManualARSRateUseCase(sessionRepository: sessionRepository)
    }

    public func makeLatestPriceUseCase() -> LatestPriceUseCase {
        LatestPriceUseCase(priceRepository: priceRepository)
    }

    // MARK: - Use case factories — wishlist

    public func makeGetWishlistUseCase() -> GetWishlistUseCase {
        GetWishlistUseCase(repository: wishlistRepository)
    }

    public func makeAddToWishlistUseCase() -> AddToWishlistUseCase {
        AddToWishlistUseCase(repository: wishlistRepository)
    }

    public func makeRemoveFromWishlistUseCase() -> RemoveFromWishlistUseCase {
        RemoveFromWishlistUseCase(repository: wishlistRepository)
    }

    @MainActor public func makeWishlistViewModel() -> WishlistViewModel {
        WishlistViewModel(
            getWishlist: makeGetWishlistUseCase(),
            addToWishlist: makeAddToWishlistUseCase(),
            removeFromWishlist: makeRemoveFromWishlistUseCase(),
            scryfallClient: scryfallClient,
            sessionRepository: sessionRepository,
            exchangeRateRepository: exchangeRateRepository
        )
    }

    // MARK: - Use case factories — pricing

    public func makeSyncPricesUseCase() -> SyncPricesUseCase {
        SyncPricesUseCase(
            priceRepository: priceRepository,
            cardRepository: cardRepository,
            priceSource: priceCatalogueSource
        )
    }

    @MainActor public func makePriceSyncViewModel(fullHistory: Bool = true) -> PriceSyncViewModel {
        PriceSyncViewModel(
            useCase: makeSyncPricesUseCase(),
            seedCatalogue: makeSeedCatalogueUseCase(),
            cardRepository: cardRepository,
            reachability: networkReachability,
            fullHistory: fullHistory
        )
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

    @MainActor public func makeCardDetailViewModel(
        card: Card,
        displayCurrency: Currency
    ) -> CardDetailViewModel {
        CardDetailViewModel(
            card: card,
            displayCurrency: displayCurrency,
            client: scryfallClient,
            stackRepository: stackRepository,
            addCardToStack: makeAddCardToStackUseCase(),
            cardRepository: cardRepository,
            priceRepository: priceRepository,
            latestPriceUseCase: makeLatestPriceUseCase(),
            sessionRepository: sessionRepository
        )
    }

    // MARK: - Use case factories — stacks

    public func makeAddCardToStackUseCase() -> AddCardToStackUseCase {
        AddCardToStackUseCase(itemRepository: collectionItemRepository)
    }

    public func makeMoveCollectionItemUseCase() -> MoveCollectionItemUseCase {
        MoveCollectionItemUseCase(itemRepository: collectionItemRepository)
    }

    public func makeImportDeckListUseCase() -> ImportDeckListUseCase {
        ImportDeckListUseCase(
            cardRepository: cardRepository,
            scryfallClient: scryfallClient,
            addCardToStack: makeAddCardToStackUseCase()
        )
    }

    @MainActor public func makeCollectionViewModel() -> CollectionViewModel {
        CollectionViewModel(
            sessionRepository: sessionRepository,
            cardRepository: cardRepository,
            seedCatalogue: makeSeedCatalogueUseCase(),
            exchangeRateRepository: exchangeRateRepository
        )
    }

    @MainActor public func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            repository: dashboardRepository,
            sessionRepository: sessionRepository,
            syncPrices: makeSyncPricesUseCase(),
            reachability: networkReachability,
            exchangeRateRepository: exchangeRateRepository
        )
    }

    @MainActor public func makeStacksListViewModel() -> StacksListViewModel {
        StacksListViewModel(
            stackRepository: stackRepository,
            itemRepository: collectionItemRepository,
            sessionRepository: sessionRepository,
            cardRepository: cardRepository
        )
    }

    @MainActor public func makeStackDetailViewModel(stack: Stack) -> StackDetailViewModel {
        StackDetailViewModel(
            stack: stack,
            itemRepository: collectionItemRepository,
            sessionRepository: sessionRepository,
            cardRepository: cardRepository,
            stackRepository: stackRepository,
            exchangeRateRepository: exchangeRateRepository,
            importDeckList: makeImportDeckListUseCase(),
            scryfallClient: scryfallClient
        )
    }

    @MainActor public func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            sessionRepository:           sessionRepository,
            userProfileRepository:       userProfileRepository,
            cardRepository:              cardRepository,
            dashboardRepository:         dashboardRepository,
            stackRepository:             stackRepository,
            exchangeRateRepository:      exchangeRateRepository,
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
            updateUserProfileUseCase:    makeUpdateUserProfileUseCase(),
            resetCatalogueUseCase:       makeResetCatalogueUseCase()
        )
    }
}

//
//  DashboardViewModelTests.swift
//  UginsVaultTests
//

import Foundation
import Observation
import SwiftData
import Testing
@testable import UginsVault

@Suite("DashboardViewModel")
@MainActor
struct DashboardViewModelTests {

    // MARK: - Mock repo

    @MainActor
    @Observable
    final class MockRepo: DashboardRepository {
        var snapshot: DashboardSnapshot?
        var isFetching: Bool = false
        @ObservationIgnored var queuedResult: Result<DashboardSnapshot, Error>?
        @ObservationIgnored private(set) var fetchCallCount: Int = 0

        @discardableResult
        func fetch() async throws -> DashboardSnapshot {
            fetchCallCount += 1
            isFetching = true
            defer { isFetching = false }
            switch queuedResult {
            case .success(let snap):
                snapshot = snap
                return snap
            case .failure(let err):
                throw err
            case .none:
                let snap = DashboardSnapshot.assemble(
                    realStats: .init(),
                    mockedHistory: MockDashboardRepository.seed
                )
                snapshot = snap
                return snap
            }
        }
    }

    private struct DummyError: Error, LocalizedError {
        var errorDescription: String? { "boom" }
    }

    // MARK: - Tests

    @Test("Defaults: idle, no snapshot, mirrors session currency")
    func defaultsReflectSession() throws {
        let repo = MockRepo()
        let session = SessionStateStore(storage: MockSessionStorage())
        session.saveCurrency(.eur)
        let sut = DashboardViewModel(repository: repo, sessionRepository: session)

        #expect(sut.snapshot == nil)
        #expect(sut.status == .idle)
        #expect(sut.currency == .eur)
    }

    @Test("load transitions idle → loaded with the seed snapshot")
    func loadHappyPath() async throws {
        let repo = MockRepo()
        let sut = DashboardViewModel(
            repository: repo,
            sessionRepository: SessionStateStore(storage: MockSessionStorage())
        )

        await sut.load()

        #expect(sut.status == .loaded)
        #expect(sut.snapshot != nil)
        #expect(repo.fetchCallCount == 1)
    }

    @Test("load surfaces repository failures as .error")
    func loadFailurePath() async throws {
        let repo = MockRepo()
        repo.queuedResult = .failure(DummyError())
        let sut = DashboardViewModel(
            repository: repo,
            sessionRepository: SessionStateStore(storage: MockSessionStorage())
        )

        await sut.load()

        guard case .error = sut.status else {
            Issue.record("Expected .error, got \(sut.status)")
            return
        }
        #expect(sut.snapshot == nil)
    }

    @Test("Switching the session currency does NOT trigger a refetch")
    func currencyChangeDoesNotRefetch() async throws {
        let repo = MockRepo()
        let session = SessionStateStore(storage: MockSessionStorage())
        let sut = DashboardViewModel(repository: repo, sessionRepository: session)

        await sut.load()
        #expect(repo.fetchCallCount == 1)

        session.saveCurrency(.eur)
        sut.refreshCurrencyIfNeeded()

        #expect(sut.currency == .eur)
        #expect(repo.fetchCallCount == 1)
    }

    @Test("onAppear is a no-op when the snapshot is already loaded")
    func onAppearNoopsAfterFirstLoad() async throws {
        let repo = MockRepo()
        let sut = DashboardViewModel(
            repository: repo,
            sessionRepository: SessionStateStore(storage: MockSessionStorage())
        )
        await sut.load()
        #expect(repo.fetchCallCount == 1)

        await sut.onAppear()

        #expect(repo.fetchCallCount == 1)
    }

    @Test("refresh always triggers a fetch and replaces the snapshot")
    func refreshAlwaysFetches() async throws {
        let repo = MockRepo()
        let sut = DashboardViewModel(
            repository: repo,
            sessionRepository: SessionStateStore(storage: MockSessionStorage())
        )
        await sut.load()
        let initialSnapshot = sut.snapshot

        await sut.refresh()

        #expect(repo.fetchCallCount == 2)
        #expect(sut.snapshot != nil)
        #expect(sut.snapshot == initialSnapshot) // mock returns the same seed
    }

    // MARK: - Sync behaviour

    @MainActor
    final class StubReach: NetworkReachability {
        var isOnWiFi: Bool = true
    }

    @MainActor
    final class CaptureSource: PriceCatalogueSource {
        var error: Error?
        func fetchSnapshots(ownedCardIDs: Set<UUID>) async throws -> [PriceSnapshot] {
            if let error { throw error }
            return []
        }
    }

    /// Builds a Dashboard VM whose price sync hits a controllable backend
    /// source. Seeds one owned card so the sync reaches the backend fetch.
    private func makeSyncSUT(
        sourceError: Error?,
        onRequireSignIn: @escaping () -> Void = {}
    ) async throws -> (DashboardViewModel, MockRepo) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SwiftDataCollectionItem.self, configurations: config)
        let items = SwiftDataCollectionItemRepository(modelContainer: container)
        try await items.save(CollectionItem(cardID: UUID(), stackID: UUID()))

        let backend = CaptureSource()
        backend.error = sourceError
        let sync = SyncPricesUseCase(
            priceRepository: MockPriceRepository(),
            collectionItemRepository: items,
            backendSource: backend
        )
        let repo = MockRepo()
        let sut = DashboardViewModel(
            repository: repo,
            sessionRepository: SessionStateStore(storage: MockSessionStorage()),
            syncPrices: sync,
            reachability: StubReach(),
            signOutAccount: SignOutAccountUseCase(accountRepository: MockAccountRepository()),
            onRequireSignIn: onRequireSignIn
        )
        return (sut, repo)
    }

    @Test("auto-sync on first appear runs a sync + reloads")
    func autoSyncOnAppear() async throws {
        let (sut, repo) = try await makeSyncSUT(sourceError: nil)

        await sut.onAppear()

        // initial load (snapshot nil) + post-sync reload
        #expect(repo.fetchCallCount == 2)
        // backend returned no prices for the owned card → pending
        #expect(sut.priceSyncState == .pending)
    }

    @Test("expired session during sync routes to sign-in")
    func unauthorizedRoutesToLogin() async throws {
        var routed = false
        let (sut, _) = try await makeSyncSUT(
            sourceError: PriceSourceError.unauthorized,
            onRequireSignIn: { routed = true }
        )

        await sut.refresh()

        #expect(routed)
        #expect(sut.priceSyncState == .idle)
    }

    @Test("network/server error during sync flags .failed")
    func syncFailureFlag() async throws {
        let (sut, _) = try await makeSyncSUT(sourceError: DummyError())

        await sut.refresh()

        #expect(sut.priceSyncState == .failed)
    }
}

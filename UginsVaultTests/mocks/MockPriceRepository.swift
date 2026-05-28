//
//  MockPriceRepository.swift
//  UginsVaultTests
//

import Foundation
@testable import UginsVault

@MainActor
final class MockPriceRepository: PriceRepository {

    private var _lastSyncedAt: Date?

    // Spies
    private(set) var upserts: [[PriceSnapshot]] = []

    // Stubs
    var stubLatest: PriceSnapshot?
    var latestBySource: [PriceSource: PriceSnapshot] = [:]

    func lastSyncedAt() async throws -> Date? { _lastSyncedAt }

    func latest(cardID: UUID, source: PriceSource) async throws -> PriceSnapshot? {
        latestBySource[source] ?? stubLatest
    }

    func history(cardID: UUID, source: PriceSource, since: Date) async throws -> [PriceSnapshot] { [] }

    func latestByCard(source: PriceSource) async throws -> [UUID: PriceSnapshot] { [:] }

    func upsert(_ snapshots: [PriceSnapshot], keepingSince: Date) async throws {
        upserts.append(snapshots)
    }

    func markSyncCompleted(at date: Date) async throws {
        _lastSyncedAt = date
    }

    func deleteAll() async throws {
        upserts.removeAll()
        _lastSyncedAt = nil
    }
}

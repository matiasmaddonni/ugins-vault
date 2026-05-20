//
//  MockPriceRepository.swift
//  UginsVaultTests
//

import Foundation
import Observation
@testable import UginsVault

@Observable
@MainActor
final class MockPriceRepository: PriceRepository {

    var lastSyncedAt: Date?
    var isWriting: Bool = false

    // Spies
    @ObservationIgnored private(set) var upserts: [[PriceSnapshot]] = []

    // Stubs
    @ObservationIgnored var stubLatest: PriceSnapshot?
    @ObservationIgnored var latestBySource: [PriceSource: PriceSnapshot] = [:]

    func latest(cardID: UUID, source: PriceSource) async throws -> PriceSnapshot? {
        latestBySource[source] ?? stubLatest
    }

    func history(cardID: UUID, source: PriceSource, since: Date) async throws -> [PriceSnapshot] { [] }

    func latestByCard(source: PriceSource) async throws -> [UUID: PriceSnapshot] { [:] }

    func upsert(_ snapshots: [PriceSnapshot], keepingSince: Date) async throws {
        upserts.append(snapshots)
    }

    func markSyncCompleted(at date: Date) async throws {
        lastSyncedAt = date
    }

    func deleteAll() async throws {
        upserts.removeAll()
        lastSyncedAt = nil
    }
}

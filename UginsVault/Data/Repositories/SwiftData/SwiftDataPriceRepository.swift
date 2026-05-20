//
//  SwiftDataPriceRepository.swift
//  UginsVault — Data layer / SwiftData
//
//  `PriceRepository` backed by SwiftData. The unique key on the
//  storage shape is the snapshot UUID, but the *logical* key is
//  (cardID, source, calendarDay) — `upsert(_:keepingSince:)` collapses
//  duplicates on that triple before writing.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
public final class SwiftDataPriceRepository: PriceRepository {

    public private(set) var lastSyncedAt: Date?
    public private(set) var isWriting: Bool = false

    @ObservationIgnored private let modelContainer: ModelContainer
    @ObservationIgnored private var context: ModelContext { modelContainer.mainContext }
    @ObservationIgnored private let lastSyncStorage: SessionStorageDataSource

    /// UserDefaults key — survives app relaunches separately from the
    /// SwiftData store. Wiping the SwiftData store doesn't clear it
    /// automatically; `deleteAll()` does.
    @ObservationIgnored private let lastSyncedKey = "uv.priceRepository.lastSyncedAt"

    public init(
        modelContainer: ModelContainer,
        lastSyncStorage: SessionStorageDataSource
    ) {
        self.modelContainer = modelContainer
        self.lastSyncStorage = lastSyncStorage
        if let raw = lastSyncStorage.string(forKey: lastSyncedKey),
           let interval = TimeInterval(raw) {
            self.lastSyncedAt = Date(timeIntervalSince1970: interval)
        } else {
            self.lastSyncedAt = nil
        }
    }

    // MARK: - Reads

    public func latest(cardID: UUID, source: PriceSource) async throws -> PriceSnapshot? {
        let sourceRaw = source.rawValue
        var descriptor = FetchDescriptor<SwiftDataPriceSnapshot>(
            predicate: #Predicate<SwiftDataPriceSnapshot> {
                $0.cardID == cardID && $0.sourceRaw == sourceRaw
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first.flatMap(PriceSnapshot.init(from:))
    }

    public func history(
        cardID: UUID,
        source: PriceSource,
        since: Date
    ) async throws -> [PriceSnapshot] {
        let sourceRaw = source.rawValue
        let descriptor = FetchDescriptor<SwiftDataPriceSnapshot>(
            predicate: #Predicate<SwiftDataPriceSnapshot> {
                $0.cardID == cardID
                && $0.sourceRaw == sourceRaw
                && $0.date >= since
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try context.fetch(descriptor).compactMap(PriceSnapshot.init(from:))
    }

    public func latestByCard(source: PriceSource) async throws -> [UUID: PriceSnapshot] {
        let sourceRaw = source.rawValue
        let descriptor = FetchDescriptor<SwiftDataPriceSnapshot>(
            predicate: #Predicate<SwiftDataPriceSnapshot> { $0.sourceRaw == sourceRaw },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let rows = try context.fetch(descriptor).compactMap(PriceSnapshot.init(from:))
        var map: [UUID: PriceSnapshot] = [:]
        for row in rows where map[row.cardID] == nil {
            map[row.cardID] = row
        }
        return map
    }

    public func allSince(source: PriceSource, since: Date) async throws -> [PriceSnapshot] {
        let sourceRaw = source.rawValue
        let descriptor = FetchDescriptor<SwiftDataPriceSnapshot>(
            predicate: #Predicate<SwiftDataPriceSnapshot> {
                $0.sourceRaw == sourceRaw && $0.date >= since
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return try context.fetch(descriptor).compactMap(PriceSnapshot.init(from:))
    }

    // MARK: - Writes

    public func upsert(
        _ snapshots: [PriceSnapshot],
        keepingSince: Date
    ) async throws {
        isWriting = true
        defer { isWriting = false }

        // Collapse incoming dupes on the logical (cardID, source, day)
        // key — last one wins.
        var dedup: [String: PriceSnapshot] = [:]
        for snapshot in snapshots {
            let key = "\(snapshot.cardID.uuidString)|\(snapshot.source.rawValue)|\(snapshot.date.timeIntervalSince1970)"
            dedup[key] = snapshot
        }

        // Pull every row for the affected (cardID, source, day) tuples
        // in one fetch to avoid N round-trips.
        let cardIDs = Set(dedup.values.map(\.cardID))
        let existing = try context.fetch(
            FetchDescriptor<SwiftDataPriceSnapshot>(
                predicate: #Predicate<SwiftDataPriceSnapshot> { cardIDs.contains($0.cardID) }
            )
        )
        var existingByKey: [String: SwiftDataPriceSnapshot] = [:]
        for row in existing {
            let key = "\(row.cardID.uuidString)|\(row.sourceRaw)|\(row.date.timeIntervalSince1970)"
            existingByKey[key] = row
        }

        for (key, snapshot) in dedup {
            if let row = existingByKey[key] {
                row.apply(snapshot)
            } else {
                context.insert(SwiftDataPriceSnapshot(from: snapshot))
            }
        }

        // Prune anything older than the rolling window.
        try context.delete(
            model: SwiftDataPriceSnapshot.self,
            where: #Predicate<SwiftDataPriceSnapshot> { $0.date < keepingSince }
        )

        try context.save()
    }

    public func markSyncCompleted(at date: Date) async throws {
        lastSyncedAt = date
        lastSyncStorage.set(String(date.timeIntervalSince1970), forKey: lastSyncedKey)
    }

    public func deleteAll() async throws {
        isWriting = true
        defer { isWriting = false }
        try context.delete(model: SwiftDataPriceSnapshot.self)
        try context.save()
        lastSyncedAt = nil
        lastSyncStorage.set(nil, forKey: lastSyncedKey)
    }
}

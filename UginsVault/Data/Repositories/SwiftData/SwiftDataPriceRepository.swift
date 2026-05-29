//
//  SwiftDataPriceRepository.swift
//  UginsVault — Data layer / SwiftData
//
//  `PriceRepository` backed by SwiftData via `@ModelActor`. Owns its
//  own background `ModelContext`. Custom init wires an extra
//  `SessionStorageDataSource` for the last-sync stamp (UserDefaults
//  alongside the SwiftData snapshot store).
//

import Foundation
import SwiftData

public actor SwiftDataPriceRepository: PriceRepository, ModelActor {

    public nonisolated let modelExecutor: any ModelExecutor
    public nonisolated let modelContainer: ModelContainer

    private let lastSyncStorage: SessionStorageDataSource

    /// UserDefaults key — survives app relaunches separately from the
    /// SwiftData store. Wiping the SwiftData store doesn't clear it
    /// automatically; `deleteAll()` does.
    private let lastSyncedKey = "uv.priceRepository.lastSyncedAt"

    public init(
        modelContainer: ModelContainer,
        lastSyncStorage: SessionStorageDataSource
    ) {
        let modelContext = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
        self.lastSyncStorage = lastSyncStorage
    }

    public func lastSyncedAt() async throws -> Date? {
        guard let raw = lastSyncStorage.string(forKey: lastSyncedKey),
              let interval = TimeInterval(raw) else { return nil }
        return Date(timeIntervalSince1970: interval)
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
        return try modelContext.fetch(descriptor).first.flatMap(PriceSnapshot.init(from:))
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
        return try modelContext.fetch(descriptor).compactMap(PriceSnapshot.init(from:))
    }

    public func latestByCard(source: PriceSource) async throws -> [UUID: PriceSnapshot] {
        let sourceRaw = source.rawValue
        let descriptor = FetchDescriptor<SwiftDataPriceSnapshot>(
            predicate: #Predicate<SwiftDataPriceSnapshot> { $0.sourceRaw == sourceRaw },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let rows = try modelContext.fetch(descriptor).compactMap(PriceSnapshot.init(from:))
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
        return try modelContext.fetch(descriptor).compactMap(PriceSnapshot.init(from:))
    }

    // MARK: - Writes

    public func upsert(
        _ snapshots: [PriceSnapshot],
        keepingSince: Date
    ) async throws {
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
        let existing = try modelContext.fetch(
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
                modelContext.insert(SwiftDataPriceSnapshot(from: snapshot))
            }
        }

        // Prune anything older than the rolling window.
        try modelContext.delete(
            model: SwiftDataPriceSnapshot.self,
            where: #Predicate<SwiftDataPriceSnapshot> { $0.date < keepingSince }
        )

        try modelContext.save()
    }

    public func markSyncCompleted(at date: Date) async throws {
        lastSyncStorage.set(String(date.timeIntervalSince1970), forKey: lastSyncedKey)
    }

    public func deleteAll() async throws {
        try modelContext.delete(model: SwiftDataPriceSnapshot.self)
        try modelContext.save()
        lastSyncStorage.set(nil, forKey: lastSyncedKey)
    }
}

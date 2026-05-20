//
//  MTGJSONPriceCatalogueSource.swift
//  UginsVault — Data layer / MTGJSON
//
//  Glues `MTGJSONClient` (download) + `MTGJSONPriceParser` (decode)
//  behind the `PriceCatalogueSource` Domain protocol. The use case
//  doesn't know — or care — that the data comes from MTGJSON.
//

import Foundation

@MainActor
public final class MTGJSONPriceCatalogueSource: PriceCatalogueSource {

    private let client: MTGJSONClient

    public init(client: MTGJSONClient) {
        self.client = client
    }

    public func fetchSnapshots(ownedCardIDs: Set<UUID>) async throws -> [PriceSnapshot] {
        guard !ownedCardIDs.isEmpty else { return [] }

        let fileURL = try await client.downloadAllPricesToday()
        defer { try? FileManager.default.removeItem(at: fileURL) }

        return try MTGJSONPriceParser.parse(
            fileURL: fileURL,
            ownedCardIDs: ownedCardIDs
        )
    }

    public func fetchFullHistory(ownedCardIDs: Set<UUID>, windowStart: Date?) async throws -> [PriceSnapshot] {
        guard !ownedCardIDs.isEmpty else { return [] }

        let fileURL = try await client.downloadAllPrices()
        defer { try? FileManager.default.removeItem(at: fileURL) }

        return try MTGJSONStreamingPriceParser.parse(
            fileURL: fileURL,
            ownedCardIDs: ownedCardIDs,
            windowStart: windowStart
        )
    }
}

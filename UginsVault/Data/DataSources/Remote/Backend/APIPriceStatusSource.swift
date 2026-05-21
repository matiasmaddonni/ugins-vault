//
//  APIPriceStatusSource.swift
//  UginsVault — Data layer / Backend
//
//  `PriceStatusSource` over `GET /v1/prices/status`.
//

import Foundation

public struct APIPriceStatusSource: PriceStatusSource {

    private let client: UginsVaultAPIClient

    public init(client: UginsVaultAPIClient) {
        self.client = client
    }

    public func status() async throws -> PriceStatus {
        let dto = try await client.pricesStatus()
        return PriceStatus(
            pending: Set(dto.pending),
            noData: Set(dto.noData),
            updatedAt: dto.updatedAt
        )
    }
}

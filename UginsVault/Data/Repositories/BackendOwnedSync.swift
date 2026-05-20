//
//  BackendOwnedSync.swift
//  UginsVault — Data layer
//
//  `RemoteOwnedSync` over `PUT /v1/owned`.
//

import Foundation

public struct BackendOwnedSync: RemoteOwnedSync {

    private let client: UginsVaultAPIClient

    public init(client: UginsVaultAPIClient) {
        self.client = client
    }

    public func push(_ cards: [OwnedCardCount]) async throws {
        let dtos = cards.map {
            OwnedCardDTO(cardId: $0.cardID.uuidString.lowercased(), quantity: $0.quantity)
        }
        _ = try await client.putOwned(OwnedRequestDTO(cards: dtos))
    }
}

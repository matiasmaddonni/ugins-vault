//
//  RemoteOwnedSync.swift
//  UginsVault — Domain layer
//
//  Pushes the user's owned-card list to the backend so its server-side ingest
//  covers them. Concrete implementation (`BackendOwnedSync`) lives in Data.
//

import Foundation

public protocol RemoteOwnedSync: Sendable {

    /// Atomically replaces the caller's owned list on the backend.
    func push(_ cards: [OwnedCardCount]) async throws
}

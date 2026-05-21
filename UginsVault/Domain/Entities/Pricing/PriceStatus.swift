//
//  PriceStatus.swift
//  UginsVault — Domain layer
//
//  Server-side pricing progress for the owned set (from `/v1/prices/status`).
//  An owned card that is neither priced nor in `noData` is still "fetching"
//  (the backend pulls MTGJSON on demand, which can take minutes for brand-new
//  cards).
//

import Foundation

public struct PriceStatus: Sendable, Equatable {

    /// Cards the backend is still fetching a price for.
    public let pending: Set<UUID>

    /// Cards MTGJSON has no price for — stop showing a "fetching" state.
    public let noData: Set<UUID>

    /// Day of the latest priced snapshot ("YYYY-MM-DD"), or nil if none yet.
    public let updatedAt: String?

    public init(pending: Set<UUID>, noData: Set<UUID>, updatedAt: String?) {
        self.pending = pending
        self.noData = noData
        self.updatedAt = updatedAt
    }

    public static let empty = PriceStatus(pending: [], noData: [], updatedAt: nil)
}

//
//  CollectionStats.swift
//  UginsVault — Domain layer / Dashboard
//
//  Quick-stats strip values rendered at the bottom of the Dashboard
//  tab: total cards owned, distinct printings, foils, average value.
//

import Foundation

public struct CollectionStats: Equatable, Sendable {

    public let totalCards: Int
    public let uniqueCards: Int
    public let foils: Int
    public let avgValueUSD: Decimal

    public init(
        totalCards: Int,
        uniqueCards: Int,
        foils: Int,
        avgValueUSD: Decimal
    ) {
        self.totalCards  = totalCards
        self.uniqueCards = uniqueCards
        self.foils       = foils
        self.avgValueUSD = avgValueUSD
    }

    public static let zero = CollectionStats(
        totalCards: 0, uniqueCards: 0, foils: 0, avgValueUSD: .zero
    )
}

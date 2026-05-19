//
//  Mover.swift
//  UginsVault — Domain layer / Dashboard
//
//  A single gainer or loser row on the Dashboard. The Domain stays
//  pure — Presentation colour-codes positives vs negatives at the
//  view layer.
//

import Foundation

public struct Mover: Identifiable, Equatable, Sendable {

    public let id: String          // card id slug (matches the seed)
    public let name: String
    public let setCode: String
    public let deltaUSD: Decimal   // signed
    public let pct: Double         // signed (e.g. 4.5 ⇒ +4.5%)

    public init(
        id: String,
        name: String,
        setCode: String,
        deltaUSD: Decimal,
        pct: Double
    ) {
        self.id       = id
        self.name     = name
        self.setCode  = setCode
        self.deltaUSD = deltaUSD
        self.pct      = pct
    }

    public var isUp: Bool { pct >= 0 }
}

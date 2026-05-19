//
//  SetBar.swift
//  UginsVault — Domain layer / Dashboard
//
//  Single bar in the value-by-set panel. `code` is the Scryfall set
//  code (lowercased on the wire, uppercased when rendered).
//

import Foundation

public struct SetBar: Identifiable, Equatable, Sendable {

    public var id: String { code }
    public let code: String
    public let name: String
    public let valueUSD: Decimal

    public init(code: String, name: String, valueUSD: Decimal) {
        self.code     = code
        self.name     = name
        self.valueUSD = valueUSD
    }
}

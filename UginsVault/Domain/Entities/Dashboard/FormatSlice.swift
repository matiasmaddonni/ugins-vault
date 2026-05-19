//
//  FormatSlice.swift
//  UginsVault — Domain layer / Dashboard
//
//  Slice of the value-by-format donut. `colorHex` lives in the Domain
//  as a raw integer so the Domain stays SwiftUI-free; Presentation
//  builds a `Color` from it via an extension.
//

import Foundation

public struct FormatSlice: Identifiable, Equatable, Sendable {

    public let id: String           // e.g. "modern", "commander"
    public let displayName: String  // e.g. "Modern"
    public let valueUSD: Decimal
    public let colorHex: UInt32     // sRGB hex, no alpha

    public init(
        id: String,
        displayName: String,
        valueUSD: Decimal,
        colorHex: UInt32
    ) {
        self.id          = id
        self.displayName = displayName
        self.valueUSD    = valueUSD
        self.colorHex    = colorHex
    }
}

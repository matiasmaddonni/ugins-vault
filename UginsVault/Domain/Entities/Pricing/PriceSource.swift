//
//  PriceSource.swift
//  UginsVault — Domain layer / Pricing
//
//  Marketplaces we surface prices from. MTGJSON publishes more
//  (TCGplayer + Cardmarket + Card Kingdom + Cardhoarder + MTGO Traders);
//  v0.5 keeps the three paper retail sources users actually care about.
//

import Foundation

public enum PriceSource: String, Codable, CaseIterable, Sendable, Identifiable {
    case cardkingdom
    case tcgplayer
    case cardmarket

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cardkingdom: return "Card Kingdom"
        case .tcgplayer:   return "TCGplayer"
        case .cardmarket:  return "Cardmarket"
        }
    }

    /// ISO 4217 code each source's retail prices ship in. Lets the
    /// view layer hand a known-currency snapshot off to the FX layer
    /// (v0.7) without a separate lookup.
    public var nativeCurrency: Currency {
        switch self {
        case .cardkingdom: return .usd
        case .tcgplayer:   return .usd
        case .cardmarket:  return .eur
        }
    }
}

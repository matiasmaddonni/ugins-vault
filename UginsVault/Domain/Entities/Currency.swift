//
//  Currency.swift
//  UginsVault — Domain layer
//
//  User-configurable display currency. Default USD. The user is Argentinian
//  so ARS is supported alongside EUR.
//

import Foundation

public enum Currency: String, Codable, Sendable, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case ars = "ARS"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .usd: "$"
        case .eur: "€"
        case .ars: "AR$"
        }
    }

    public var localeIdentifier: String {
        switch self {
        case .usd: "en_US"
        case .eur: "de_DE"
        case .ars: "es_AR"
        }
    }
}

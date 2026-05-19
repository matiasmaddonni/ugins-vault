//
//  CurrencyFormatter.swift
//  UginsVault — Presentation: Shared
//
//  Locale-aware currency rendering. Honors the user's chosen `Currency`
//  symbol/code and the active `Locale` for decimal separator / grouping.
//
//  v0.1: prices are stored in USD and shown using the chosen currency's
//  symbol with NO conversion. Real exchange rates land in v0.3 via an ECB
//  rate-fetch step on top of this formatter.
//

import Foundation

public enum CurrencyFormatter {

    /// Formats a USD-denominated `Decimal` amount in the user's chosen
    /// `Currency`. The current implementation does not convert — it just
    /// swaps the displayed currency symbol/code.
    public static func format(
        _ amount: Decimal,
        currency: Currency,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        amount.formatted(
            .currency(code: currency.isoCode)
                .locale(locale)
        )
    }
}

extension Currency {

    /// ISO 4217 currency code that matches our enum cases.
    public var isoCode: String { rawValue }
}

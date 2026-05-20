//
//  CurrencyFormatter.swift
//  UginsVault — Presentation: Shared
//
//  Locale-aware currency rendering. Honors the user's chosen `Currency`
//  symbol/code, the active `Locale` for decimal separator / grouping,
//  and an optional `ExchangeRate` from the FX layer for converting
//  the USD-denominated amount we store into whichever quote currency
//  the view is rendering in.
//
//  Render order:
//    1. Multiply the amount by `rate.rate` when the quote ≠ USD.
//    2. Format with the locale-correct symbol + decimal places.
//

import Foundation

public enum CurrencyFormatter {

    /// Formats a USD-denominated `Decimal` amount. When `rate` is
    /// provided AND `currency != .usd`, the amount is multiplied
    /// before formatting. Pass `rate: nil` to keep the legacy
    /// symbol-swap behaviour (used in places that haven't been wired
    /// into the FX layer yet — they degrade to no-conversion).
    public static func format(
        _ amount: Decimal,
        currency: Currency,
        rate: ExchangeRate? = nil,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let converted: Decimal
        if currency == .usd {
            converted = amount
        } else if let rate, rate.quote == currency, rate.base == .usd {
            converted = amount * rate.rate
        } else {
            converted = amount
        }

        return converted.formatted(
            .currency(code: currency.isoCode)
                .locale(locale)
        )
    }
}

extension Currency {
    /// ISO 4217 currency code that matches our enum cases.
    public var isoCode: String { rawValue }
}

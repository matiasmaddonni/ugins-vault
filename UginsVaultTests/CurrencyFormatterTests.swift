//
//  CurrencyFormatterTests.swift
//  UginsVaultTests — Presentation
//

import Foundation
import Testing
@testable import UginsVault

@Suite("CurrencyFormatter")
@MainActor
struct CurrencyFormatterTests {

    @Test("USD under en_US uses the dollar sign and . separator")
    func usdEnUS() {
        let formatted = CurrencyFormatter.format(
            Decimal(string: "1234.56")!,
            currency: .usd,
            locale: Locale(identifier: "en_US")
        )

        #expect(formatted.contains("$"))
        #expect(formatted.contains("1,234.56"))
    }

    @Test("EUR under en_US uses € and . separator")
    func eurEnUS() {
        let formatted = CurrencyFormatter.format(
            Decimal(string: "1234.56")!,
            currency: .eur,
            locale: Locale(identifier: "en_US")
        )

        #expect(formatted.contains("€"))
    }

    @Test("ARS under es_AR uses , as the decimal separator")
    func arsEsAR() {
        let formatted = CurrencyFormatter.format(
            Decimal(string: "1234.56")!,
            currency: .ars,
            locale: Locale(identifier: "es_AR")
        )

        // Spanish (Argentina) uses comma for decimals.
        #expect(formatted.contains(",56"))
    }

    @Test("Currency.isoCode mirrors the raw value")
    func isoCodeMatchesRawValue() {
        #expect(Currency.usd.isoCode == "USD")
        #expect(Currency.eur.isoCode == "EUR")
        #expect(Currency.ars.isoCode == "ARS")
    }
}

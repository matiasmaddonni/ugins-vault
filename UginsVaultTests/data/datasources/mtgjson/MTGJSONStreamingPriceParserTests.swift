//
//  MTGJSONStreamingPriceParserTests.swift
//  UginsVaultTests
//
//  Exercises the byte-level scanner that powers the full-history parse.
//  These cover the cases we can't validate against the real ~1.2 GB
//  dump: owned filtering, multi-date/source extraction, the window
//  clamp, and — critically — skipping unowned cards whose nested
//  objects + brace-bearing strings must not throw off the depth count.
//

import Foundation
import Testing
@testable import UginsVault

@Suite("MTGJSONStreamingPriceParser")
struct MTGJSONStreamingPriceParserTests {

    private func makeFile(json: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("uv-mtgjson-stream-\(UUID().uuidString).json")
        try json.data(using: .utf8)!.write(to: url)
        return url
    }

    private func cleanup(_ url: URL) { try? FileManager.default.removeItem(at: url) }

    @Test("Owned card → snapshot per (source, date)")
    func parsesOwnedAcrossSources() throws {
        let cardID = UUID()
        let json = #"""
        {
          "meta": { "date": "2026-05-19", "note": "braces {} in meta should not matter" },
          "data": {
            "\#(cardID.uuidString)": {
              "paper": {
                "cardkingdom": { "currency": "USD", "retail": { "normal": { "2026-05-19": 5.99, "2026-05-18": 5.50 } } },
                "tcgplayer":   { "currency": "USD", "retail": { "normal": { "2026-05-19": 6.10 } } }
              }
            }
          }
        }
        """#
        let file = try makeFile(json: json)
        defer { cleanup(file) }

        let result = try MTGJSONStreamingPriceParser.parse(fileURL: file, ownedCardIDs: [cardID])

        #expect(result.count == 3)
        #expect(result.allSatisfy { $0.cardID == cardID })
        #expect(result.contains { $0.source == .cardkingdom && $0.retail == Decimal(5.99) })
        #expect(result.contains { $0.source == .tcgplayer && $0.retail == Decimal(6.10) })
    }

    @Test("Unowned cards between owned ones are skipped — nested objects + brace strings don't break the scan")
    func skipsUnownedWithNesting() throws {
        let owned = UUID()
        let stranger = UUID()
        let json = #"""
        {
          "data": {
            "\#(stranger.uuidString)": {
              "paper": {
                "cardkingdom": { "currency": "USD", "retail": { "normal": { "2026-05-19": 99.0 }, "foil": { "2026-05-19": 120.0 } } },
                "tcgplayer":   { "currency": "USD", "buylist": { "normal": { "2026-05-19": 80.0 } }, "note": "weird }{ string" }
              }
            },
            "\#(owned.uuidString)": {
              "paper": { "cardkingdom": { "currency": "USD", "retail": { "normal": { "2026-05-19": 1.25 } } } }
            }
          }
        }
        """#
        let file = try makeFile(json: json)
        defer { cleanup(file) }

        let result = try MTGJSONStreamingPriceParser.parse(fileURL: file, ownedCardIDs: [owned])

        #expect(result.count == 1)
        #expect(result.first?.cardID == owned)
        #expect(result.first?.retail == Decimal(1.25))
    }

    @Test("windowStart clamps out older dates")
    func windowClamp() throws {
        let cardID = UUID()
        let json = #"""
        {
          "data": {
            "\#(cardID.uuidString)": {
              "paper": { "cardkingdom": { "currency": "USD", "retail": { "normal": { "2026-05-19": 5.0, "2020-01-01": 4.0 } } } }
            }
          }
        }
        """#
        let file = try makeFile(json: json)
        defer { cleanup(file) }

        let cutoff = DateComponents(calendar: .init(identifier: .iso8601), year: 2026, month: 1, day: 1).date
        let result = try MTGJSONStreamingPriceParser.parse(fileURL: file, ownedCardIDs: [cardID], windowStart: cutoff)

        #expect(result.count == 1)
        #expect(result.first?.retail == Decimal(5.0))
    }

    @Test("Foil overrides normal for the same day")
    func foilFolds() throws {
        let cardID = UUID()
        let json = #"""
        { "data": { "\#(cardID.uuidString)": { "paper": { "cardkingdom": { "retail": {
          "normal": { "2026-05-19": 1.00 }, "foil": { "2026-05-19": 5.00 } } } } } } }
        """#
        let file = try makeFile(json: json)
        defer { cleanup(file) }

        let result = try MTGJSONStreamingPriceParser.parse(fileURL: file, ownedCardIDs: [cardID])
        #expect(result.count == 1)
        #expect(result.first?.retail == Decimal(5.0))
    }

    @Test("Minified (no whitespace) payload parses identically")
    func minifiedParses() throws {
        let cardID = UUID()
        let json = "{\"data\":{\"\(cardID.uuidString)\":{\"paper\":{\"cardmarket\":{\"currency\":\"EUR\",\"retail\":{\"normal\":{\"2026-05-19\":3.33}}}}}}}"
        let file = try makeFile(json: json)
        defer { cleanup(file) }

        let result = try MTGJSONStreamingPriceParser.parse(fileURL: file, ownedCardIDs: [cardID])
        #expect(result.count == 1)
        #expect(result.first?.source == .cardmarket)
        #expect(result.first?.currency == .eur)
    }

    @Test("Empty owned set → no work")
    func emptyOwned() throws {
        let json = #"{ "data": { "\#(UUID().uuidString)": { "paper": {} } } }"#
        let file = try makeFile(json: json)
        defer { cleanup(file) }

        #expect(try MTGJSONStreamingPriceParser.parse(fileURL: file, ownedCardIDs: []).isEmpty)
    }
}

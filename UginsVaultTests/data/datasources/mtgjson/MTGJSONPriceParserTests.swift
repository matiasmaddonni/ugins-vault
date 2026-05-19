//
//  MTGJSONPriceParserTests.swift
//  UginsVaultTests
//

import Foundation
import Testing
@testable import UginsVault

@Suite("MTGJSONPriceParser")
struct MTGJSONPriceParserTests {

    /// Writes a JSON payload to a temp file and returns its URL.
    private func makeFile(json: String, name: StaticString = #function) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("uv-mtgjson-test-\(UUID().uuidString).json")
        try json.data(using: .utf8)!.write(to: url)
        return url
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Returns a snapshot per (source, date) for an owned card")
    func parsesOwnedCardAcrossSources() throws {
        let cardID = UUID()
        let json = #"""
        {
          "meta": { "date": "2026-05-19" },
          "data": {
            "\#(cardID.uuidString)": {
              "paper": {
                "cardkingdom": {
                  "currency": "USD",
                  "retail": {
                    "normal": { "2026-05-19": 5.99, "2026-05-18": 5.50 }
                  }
                },
                "tcgplayer": {
                  "currency": "USD",
                  "retail": {
                    "normal": { "2026-05-19": 6.10 }
                  }
                }
              }
            }
          }
        }
        """#

        let file = try makeFile(json: json)
        defer { cleanup(file) }

        let result = try MTGJSONPriceParser.parse(fileURL: file, ownedCardIDs: [cardID])

        #expect(result.count == 3)
        #expect(result.allSatisfy { $0.cardID == cardID })
        #expect(result.contains(where: { $0.source == .cardkingdom && $0.retail == Decimal(5.99) }))
        #expect(result.contains(where: { $0.source == .tcgplayer  && $0.retail == Decimal(6.10) }))
    }

    @Test("Cards not in the owned set are skipped")
    func skipsUnownedCards() throws {
        let ownedID = UUID()
        let strangerID = UUID()
        let json = #"""
        {
          "data": {
            "\#(ownedID.uuidString)":    { "paper": { "cardkingdom": { "retail": { "normal": { "2026-05-19": 1.00 } } } } },
            "\#(strangerID.uuidString)": { "paper": { "cardkingdom": { "retail": { "normal": { "2026-05-19": 9.99 } } } } }
          }
        }
        """#
        let file = try makeFile(json: json)
        defer { cleanup(file) }

        let result = try MTGJSONPriceParser.parse(fileURL: file, ownedCardIDs: [ownedID])

        #expect(result.count == 1)
        #expect(result.first?.cardID == ownedID)
    }

    @Test("Empty ownedCardIDs → no work, no snapshots")
    func emptyOwnedSet() throws {
        let json = #"{ "data": { "00000000-0000-0000-0000-000000000000": { "paper": {} } } }"#
        let file = try makeFile(json: json)
        defer { cleanup(file) }

        let result = try MTGJSONPriceParser.parse(fileURL: file, ownedCardIDs: [])
        #expect(result.isEmpty)
    }

    @Test("Unknown source keys (cardhoarder, mtgo_traders) are dropped")
    func unknownSourcesSkipped() throws {
        let cardID = UUID()
        let json = #"""
        {
          "data": {
            "\#(cardID.uuidString)": {
              "paper": {
                "cardhoarder":  { "retail": { "normal": { "2026-05-19": 1.00 } } },
                "mtgo_traders": { "retail": { "normal": { "2026-05-19": 2.00 } } }
              }
            }
          }
        }
        """#
        let file = try makeFile(json: json)
        defer { cleanup(file) }

        let result = try MTGJSONPriceParser.parse(fileURL: file, ownedCardIDs: [cardID])
        #expect(result.isEmpty)
    }

    @Test("Foil price overrides the normal price for the same day")
    func foilFolds() throws {
        let cardID = UUID()
        let json = #"""
        {
          "data": {
            "\#(cardID.uuidString)": {
              "paper": {
                "cardkingdom": {
                  "retail": {
                    "normal": { "2026-05-19": 1.00 },
                    "foil":   { "2026-05-19": 5.00 }
                  }
                }
              }
            }
          }
        }
        """#
        let file = try makeFile(json: json)
        defer { cleanup(file) }

        let result = try MTGJSONPriceParser.parse(fileURL: file, ownedCardIDs: [cardID])
        #expect(result.count == 1)
        #expect(result.first?.retail == Decimal(5.0))
    }

    @Test("Malformed payload throws .parseFailed")
    func malformedPayload() throws {
        let file = try makeFile(json: "{ this is not json")
        defer { cleanup(file) }

        do {
            _ = try MTGJSONPriceParser.parse(fileURL: file, ownedCardIDs: [UUID()])
            Issue.record("Expected parse to throw")
        } catch let error as MTGJSONError {
            if case .parseFailed = error {
                // ok
            } else {
                Issue.record("Expected .parseFailed, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

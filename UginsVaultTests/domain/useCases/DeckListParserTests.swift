//
//  DeckListParserTests.swift
//  UginsVaultTests
//

import Foundation
import Testing
@testable import UginsVault

@Suite("DeckListParser")
struct DeckListParserTests {

    @Test("Plain `N Name` lines parse with default finish + no set")
    func parsesPlainLines() {
        let out = DeckListParser.parse("""
        4 Lightning Bolt
        1 Brainstorm
        """)
        #expect(out.count == 2)
        #expect(out[0] == ParsedDeckLine(quantity: 4, name: "Lightning Bolt"))
        #expect(out[1] == ParsedDeckLine(quantity: 1, name: "Brainstorm"))
    }

    @Test("Quantity with `x` suffix is accepted")
    func parsesXSuffix() {
        let out = DeckListParser.parse("4x Counterspell\n2X Force of Will")
        #expect(out.map(\.quantity) == [4, 2])
        #expect(out.map(\.name) == ["Counterspell", "Force of Will"])
    }

    @Test("`(SET) NUMBER` trailers attach set + collector number")
    func parsesSetAndCollectorNumber() {
        let out = DeckListParser.parse("1 Sol Ring (CMM) 410")
        #expect(out.count == 1)
        #expect(out[0].name == "Sol Ring")
        #expect(out[0].setCode == "cmm")
        #expect(out[0].collectorNumber == "410")
    }

    @Test("`*F*` suffix flags the line as foil")
    func parsesFoilSuffix() {
        let out = DeckListParser.parse("1 Sol Ring (CMM) 410 *F*")
        #expect(out.count == 1)
        #expect(out[0].isFoil == true)
        #expect(out[0].setCode == "cmm")
    }

    @Test("Section headers + comments + blank lines are skipped")
    func skipsNoiseLines() {
        let out = DeckListParser.parse("""

        // a comment
        Sideboard

        4 Lightning Bolt
        Commander:
        1 Atraxa, Praetors' Voice
        """)
        #expect(out.count == 2)
        #expect(out[0].name == "Lightning Bolt")
        #expect(out[1].name == "Atraxa, Praetors' Voice")
    }

    @Test("A bare `Name` line defaults the quantity to 1 (Moxfield commander row)")
    func bareNameDefaultsQuantityToOne() {
        let out = DeckListParser.parse("Lightning Bolt")
        #expect(out.count == 1)
        #expect(out[0].quantity == 1)
        #expect(out[0].name == "Lightning Bolt")
    }

    @Test("SIDEBOARD: header (uppercase + colon) is treated as a section break")
    func uppercaseSideboardHeader() {
        let out = DeckListParser.parse("""
        4 Lightning Bolt

        SIDEBOARD:
        1 Counterspell
        """)
        #expect(out.count == 2)
        #expect(out[0].name == "Lightning Bolt")
        #expect(out[1].name == "Counterspell")
    }

    @Test("Promo-suffixed collector numbers (`90s`, `241p`, `STX-188`) still parse")
    func parsesAlphanumericCollectorNumbers() {
        let out = DeckListParser.parse("""
        1 Agadeem's Awakening (PZNR) 90s
        1 Castle Locthwain (PELD) 241p
        1 Fracture (PLST) STX-188
        """)
        #expect(out.count == 3)
        #expect(out[0].collectorNumber == "90s")
        #expect(out[0].setCode == "pznr")
        #expect(out[1].collectorNumber == "241p")
        #expect(out[2].collectorNumber == "STX-188")
        #expect(out[2].setCode == "plst")
    }

    @Test("DFC names with ` / ` separator parse intact (importer normalises later)")
    func parsesDoubleFacedNames() {
        let out = DeckListParser.parse("1 Fell the Profane / Fell Mire (MH3) 244")
        #expect(out.count == 1)
        #expect(out[0].name == "Fell the Profane / Fell Mire")
        #expect(out[0].setCode == "mh3")
    }
}

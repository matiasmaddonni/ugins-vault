//
//  AddCardViewModelTests.swift
//  UginsVaultTests — Presentation: Collection
//

import Foundation
import Testing
@testable import UginsVault

@Suite("AddCardViewModel")
@MainActor
struct AddCardViewModelTests {

    static let cardJSON = """
    {
      "object": "card",
      "id": "e25ce640-baf5-442b-8b75-d05dd9fb20dd",
      "oracle_id": "4457ed35-7c10-48c8-9776-456485fdf070",
      "name": "Lightning Bolt",
      "lang": "en",
      "type_line": "Instant",
      "colors": ["R"],
      "color_identity": ["R"],
      "set": "lea",
      "set_name": "Limited Edition Alpha",
      "collector_number": "161",
      "rarity": "common",
      "released_at": "1993-08-05",
      "finishes": ["nonfoil"],
      "image_uris": { "normal": "https://cards.scryfall.io/n/lb.jpg" }
    }
    """

    private func fixture() throws -> ScryfallCard {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ScryfallCard.self, from: Data(Self.cardJSON.utf8))
    }

    @Test("a query under 2 chars clears results without searching")
    func shortQuery() {
        let vm = AddCardViewModel(scryfallClient: MockScryfallClient())
        vm.query = "a"
        vm.onQueryChange()
        #expect(vm.results.isEmpty)
        #expect(vm.status == .idle)
    }

    @Test("search maps Scryfall hits to cards")
    func searchMaps() async throws {
        let vm = AddCardViewModel(scryfallClient: MockScryfallClient(searchResults: [try fixture()]))
        await vm.runSearch("bolt")
        #expect(vm.results.count == 1)
        #expect(vm.results.first?.name == "Lightning Bolt")
        #expect(vm.status == .idle)
    }

    @Test("no hits yields empty status")
    func emptyResults() async throws {
        let vm = AddCardViewModel(scryfallClient: MockScryfallClient(searchResults: []))
        await vm.runSearch("zzzzz")
        #expect(vm.results.isEmpty)
        #expect(vm.status == .empty)
    }

    @Test("a search error yields error status")
    func searchError() async throws {
        let vm = AddCardViewModel(scryfallClient: MockScryfallClient(shouldThrow: true))
        await vm.runSearch("bolt")
        #expect(vm.results.isEmpty)
        guard case .error = vm.status else {
            Issue.record("Expected .error, got \(vm.status)")
            return
        }
    }
}

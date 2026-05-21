//
//  ScryfallClientTests.swift
//  UginsVaultTests — Data / Remote
//

import Foundation
import Testing
@testable import UginsVault

@Suite("ScryfallClient")
struct ScryfallClientTests {

    // MARK: - Fixtures

    private static let cardResponse = """
    {
      "object": "card",
      "id": "e25ce640-baf5-442b-8b75-d05dd9fb20dd",
      "oracle_id": "4457ed35-7c10-48c8-9776-456485fdf070",
      "name": "Lightning Bolt",
      "lang": "en",
      "mana_cost": "{R}",
      "cmc": 1.0,
      "type_line": "Instant",
      "oracle_text": "Lightning Bolt deals 3 damage to any target.",
      "colors": ["R"],
      "color_identity": ["R"],
      "set": "lea",
      "set_name": "Limited Edition Alpha",
      "collector_number": "161",
      "rarity": "common",
      "released_at": "1993-08-05",
      "finishes": ["nonfoil"],
      "image_uris": {
        "small": "https://cards.scryfall.io/small/front/e/2/lb-small.jpg",
        "normal": "https://cards.scryfall.io/normal/front/e/2/lb-normal.jpg"
      },
      "prices": {
        "usd": "20.00",
        "usd_foil": null,
        "eur": "18.00"
      }
    }
    """

    private static let errorResponse = """
    {
      "object": "error",
      "code": "not_found",
      "status": 404,
      "details": "No cards found matching this search.",
      "type": null
    }
    """

    // MARK: - Tests

    @Test("card(id:) decodes a single card and uses the lowercased UUID in the path")
    func cardByIDDecodes() async throws {
        let id = UUID(uuidString: "E25CE640-BAF5-442B-8B75-D05DD9FB20DD")!
        let client = makeClient { request in
            #expect(request.url?.path == "/cards/\(id.uuidString.lowercased())")
            return Self.ok(body: Self.cardResponse)
        }

        let card = try await client.card(id: id)

        #expect(card.name == "Lightning Bolt")
        #expect(card.setCode == "lea")
        #expect(card.colorIdentity == ["R"])
        #expect(card.prices?.usd == "20.00")
    }

    @Test("card(named:fuzzy:) hits /cards/named with the right query key")
    func cardByNameFuzzy() async throws {
        let client = makeClient { request in
            #expect(request.url?.path == "/cards/named")
            #expect(request.url?.query?.contains("fuzzy=Lightning%20Bolt") == true)
            return Self.ok(body: Self.cardResponse)
        }

        let card = try await client.card(named: "Lightning Bolt", fuzzy: true)

        #expect(card.name == "Lightning Bolt")
    }

    @Test("card(named:fuzzy:) uses exact when fuzzy is false")
    func cardByNameExact() async throws {
        let client = makeClient { request in
            #expect(request.url?.path == "/cards/named")
            #expect(request.url?.query?.contains("exact=") == true)
            return Self.ok(body: Self.cardResponse)
        }

        _ = try await client.card(named: "Lightning Bolt", fuzzy: false)
    }

    @Test("Sends User-Agent + Accept headers per Scryfall etiquette")
    func sendsHeaders() async throws {
        let client = makeClient { request in
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(request.value(forHTTPHeaderField: "User-Agent")?.contains("UginsVault") == true)
            return Self.ok(body: Self.cardResponse)
        }

        _ = try await client.card(id: UUID())
    }

    @Test("Non-2xx responses surface as ScryfallError.apiError with the envelope")
    func apiErrorBubbles() async throws {
        let client = makeClient { _ in
            (
                HTTPURLResponse(url: URL(string: "https://api.scryfall.com/cards/nope")!,
                                statusCode: 404, httpVersion: nil, headerFields: nil)!,
                Data(Self.errorResponse.utf8)
            )
        }

        let outcome = await Result { try await client.card(id: UUID()) }
        switch outcome {
        case .success:
            Issue.record("Expected failure, got success")
        case .failure(let error):
            guard case let ScryfallError.apiError(status, envelope) = error else {
                Issue.record("Expected apiError, got \(error)")
                return
            }
            #expect(status == 404)
            #expect(envelope.code == "not_found")
            #expect(envelope.status == 404)
        }
    }

    @Test("Malformed JSON surfaces as ScryfallError.decoding")
    func decodingError() async throws {
        let client = makeClient { _ in
            Self.ok(body: "{\"unexpected\":\"shape\"}")
        }

        let outcome = await Result { try await client.card(id: UUID()) }
        if case .success = outcome {
            Issue.record("Expected decoding failure")
        } else if case let .failure(error) = outcome {
            guard case ScryfallError.decoding = error else {
                Issue.record("Expected .decoding, got \(error)")
                return
            }
        }
    }

    // MARK: - Helpers

    private func makeClient(
        handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> ScryfallClient {
        MockURLProtocol.handler = handler
        let config = ScryfallClient.Configuration(
            baseURL: URL(string: "https://api.scryfall.com")!,
            userAgent: "UginsVault/test (tests@uginsvault.local)",
            minInterval: .zero
        )
        return ScryfallClient(configuration: config, session: .mocked())
    }

    private static func ok(body: String) -> (HTTPURLResponse, Data) {
        (
            HTTPURLResponse(
                url: URL(string: "https://api.scryfall.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!,
            Data(body.utf8)
        )
    }
}

// MARK: - Async Result helper

private extension Result where Failure == Error {

    /// Builds a `Result` from an `async throws` expression so tests can
    /// pattern-match the outcome without relying on `#expect(throws:)`.
    init(_ body: @Sendable () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }
}

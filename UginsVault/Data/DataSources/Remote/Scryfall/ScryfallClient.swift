//
//  ScryfallClient.swift
//  UginsVault — Data layer / Scryfall
//
//  Thin actor-based client over Scryfall's HTTP API. Scryfall asks
//  callers to keep a 50–100 ms gap between requests
//  (https://scryfall.com/docs/api). We hold to ~75 ms via an actor-local
//  throttle, so concurrent callers serialise naturally without lock
//  ceremony.
//

import Foundation

public actor ScryfallClient: ScryfallClientProtocol {

    // MARK: - Configuration

    public struct Configuration: Sendable {

        public let baseURL: URL
        public let userAgent: String
        public let minInterval: Duration

        public init(
            baseURL: URL,
            userAgent: String,
            minInterval: Duration = .milliseconds(75)
        ) {
            self.baseURL = baseURL
            self.userAgent = userAgent
            self.minInterval = minInterval
        }

        public static let `default` = Configuration(
            baseURL: URL(string: "https://api.scryfall.com")!,
            userAgent: "UginsVault/0.2 (matiasmaddonni@gmail.com)"
        )
    }

    // MARK: - Dependencies

    private let configuration: Configuration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let clock: any Clock<Duration>

    private var lastRequestAt: ContinuousClock.Instant?

    // MARK: - Init

    public init(
        configuration: Configuration = .default,
        session: URLSession = .shared,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.configuration = configuration
        self.session = session
        self.decoder = Self.makeDecoder()
        self.clock = clock
    }

    // MARK: - Public endpoints

    public func bulkDataIndex() async throws -> [ScryfallBulkData] {
        let list: ScryfallList<ScryfallBulkData> = try await get("bulk-data")
        return list.data
    }

    public func card(id: UUID) async throws -> ScryfallCard {
        try await get("cards/\(id.uuidString.lowercased())")
    }

    public func card(named: String, fuzzy: Bool) async throws -> ScryfallCard {
        let key = fuzzy ? "fuzzy" : "exact"
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: key, value: named)]
        let query = components.percentEncodedQuery ?? ""
        return try await get("cards/named?\(query)")
    }

    public func searchCards(query: String, page: Int) async throws -> ScryfallList<ScryfallCard> {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page))
        ]
        let queryString = components.percentEncodedQuery ?? ""
        return try await get("cards/search?\(queryString)")
    }

    // MARK: - Generic GET

    /// Issues a throttled GET against the Scryfall API and decodes the
    /// response into `T`. Honours Scryfall's recommended request spacing.
    func get<T: Decodable>(_ path: String) async throws -> T {
        try await throttleIfNeeded()

        guard let url = URL(string: path, relativeTo: configuration.baseURL) else {
            throw ScryfallError.invalidEndpoint(path: path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ScryfallError.transport(underlying: error)
        }

        try Self.validate(response: response, data: data, decoder: decoder)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ScryfallError.decoding(underlying: error)
        }
    }

    // MARK: - Throttle

    private func throttleIfNeeded() async throws {
        let now = ContinuousClock().now
        if let last = lastRequestAt {
            let elapsed = last.duration(to: now)
            if elapsed < configuration.minInterval {
                let remaining = configuration.minInterval - elapsed
                try await clock.sleep(for: remaining)
            }
        }
        lastRequestAt = ContinuousClock().now
    }

    // MARK: - Helpers

    private static func validate(response: URLResponse, data: Data, decoder: JSONDecoder) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard !(200..<300).contains(http.statusCode) else { return }

        if let envelope = try? decoder.decode(ScryfallError.APIErrorEnvelope.self, from: data) {
            throw ScryfallError.apiError(status: http.statusCode, envelope: envelope)
        }
        throw ScryfallError.unexpectedStatus(status: http.statusCode, body: data)
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

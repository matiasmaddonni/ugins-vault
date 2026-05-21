//
//  UginsVaultAPIClient.swift
//  UginsVault — Data layer / Backend
//
//  Actor-based client over the Ugin's Vault read API (Vercel). Every request
//  carries `Authorization: Bearer <Supabase access token>`, fetched from an
//  `AccessTokenProviding` seam so the client never imports the auth SDK.
//

import Foundation

public enum BackendAPIError: Error, LocalizedError {
    case notAuthenticated
    case unauthorized
    case invalidEndpoint(path: String)
    case transport(underlying: Error)
    case unexpectedStatus(status: Int)
    case decoding(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:       return "You're signed out — sign in to sync prices."
        case .unauthorized:           return "Your session expired — sign in again."
        case .invalidEndpoint(let p): return "Bad endpoint: \(p)"
        case .transport(let e):       return e.localizedDescription
        case .unexpectedStatus(let s): return "Backend returned HTTP \(s)"
        case .decoding:               return "Couldn't read the backend response."
        }
    }
}

public actor UginsVaultAPIClient {

    public struct Configuration: Sendable {
        public let baseURL: URL
        public let userAgent: String

        public init(baseURL: URL, userAgent: String) {
            self.baseURL = baseURL
            self.userAgent = userAgent
        }

        public static let `default` = Configuration(
            baseURL: BackendConfig.apiBaseURL,
            userAgent: "UginsVault/0.9 (matiasmaddonni@gmail.com)"
        )
    }

    private let configuration: Configuration
    private let session: URLSession
    private let tokenProvider: AccessTokenProviding
    private let decoder = UginsVaultAPIClient.makeDecoder()
    private let encoder = UginsVaultAPIClient.makeEncoder()

    public init(
        tokenProvider: AccessTokenProviding,
        configuration: Configuration = .default,
        session: URLSession = .shared
    ) {
        self.tokenProvider = tokenProvider
        self.configuration = configuration
        self.session = session
    }

    // MARK: - Endpoints

    /// `GET /v1/prices?window=&source=` — owned cards the backend has data for.
    func prices(window: Int, source: String) async throws -> PricesResponseDTO {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "window", value: String(window)),
            URLQueryItem(name: "source", value: source)
        ]
        let query = components.percentEncodedQuery ?? ""
        return try await get("v1/prices?\(query)")
    }

    // MARK: - Collection (source of truth lives on the backend)

    /// `GET /v1/collection` — the full collection to restore on launch.
    func getCollection() async throws -> CollectionResponseDTO {
        try await get("v1/collection")
    }

    /// `PUT /v1/collection` — full replace. First import / hard reset only.
    @discardableResult
    func putCollection(stacks: [StackDTO], items: [CollectionItemDTO]) async throws -> CollectionReplaceResponseDTO {
        try await send("v1/collection", method: "PUT",
                       body: CollectionReplaceRequestDTO(stacks: stacks, items: items))
    }

    /// `POST /v1/collection/items` — upsert a batch by id.
    @discardableResult
    func upsertItems(_ items: [CollectionItemDTO]) async throws -> ItemsUpsertResponseDTO {
        try await send("v1/collection/items", method: "POST", body: ItemsUpsertRequestDTO(items: items))
    }

    /// `DELETE /v1/collection/items` — remove items by id.
    @discardableResult
    func deleteItems(ids: [UUID]) async throws -> DeleteResponseDTO {
        try await send("v1/collection/items", method: "DELETE", body: IDsRequestDTO(ids: ids))
    }

    /// `POST /v1/collection/stacks` — upsert a batch by id.
    @discardableResult
    func upsertStacks(_ stacks: [StackDTO]) async throws -> StacksUpsertResponseDTO {
        try await send("v1/collection/stacks", method: "POST", body: StacksUpsertRequestDTO(stacks: stacks))
    }

    /// `DELETE /v1/collection/stacks` — remove stacks (and their items) by id.
    @discardableResult
    func deleteStacks(ids: [UUID]) async throws -> DeleteResponseDTO {
        try await send("v1/collection/stacks", method: "DELETE", body: IDsRequestDTO(ids: ids))
    }

    /// `GET /v1/prices/status` — which owned cards are still being priced.
    func pricesStatus() async throws -> PricesStatusDTO {
        try await get("v1/prices/status")
    }

    // MARK: - Plumbing

    private func authorizedRequest(path: String, method: String) async throws -> URLRequest {
        guard let token = await tokenProvider.accessToken() else {
            throw BackendAPIError.notAuthenticated
        }
        guard let url = URL(string: path, relativeTo: configuration.baseURL) else {
            throw BackendAPIError.invalidEndpoint(path: path)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        try await performWithRetry { try await self.authorizedRequest(path: path, method: "GET") }
    }

    private func send<Body: Encodable, T: Decodable>(
        _ path: String,
        method: String,
        body: Body
    ) async throws -> T {
        let payload = try encoder.encode(body)
        return try await performWithRetry {
            var request = try await self.authorizedRequest(path: path, method: method)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = payload
            return request
        }
    }

    /// Performs the built request; on a 401 it rebuilds the request — which
    /// re-fetches the bearer, reloading + refreshing the Supabase session — and
    /// retries exactly once before surfacing `.unauthorized`.
    private func performWithRetry<T: Decodable>(
        _ makeRequest: () async throws -> URLRequest
    ) async throws -> T {
        do {
            let request = try await makeRequest()
            return try await perform(request)
        } catch BackendAPIError.unauthorized {
            let retry = try await makeRequest()
            return try await perform(retry)
        }
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw BackendAPIError.transport(underlying: error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            if http.statusCode == 401 { throw BackendAPIError.unauthorized }
            throw BackendAPIError.unexpectedStatus(status: http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BackendAPIError.decoding(underlying: error)
        }
    }

    // MARK: - Coding

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = Self.parseTimestamp(raw) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath,
                          debugDescription: "Unparseable ISO8601 timestamp: \(raw)")
                )
            }
            return date
        }
        return decoder
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    /// Server timestamps are ISO8601 WITH an offset (e.g. "…+00:00"), sometimes
    /// with fractional seconds. Try both forms.
    private static func parseTimestamp(_ raw: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: raw) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: raw)
    }
}

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
    case invalidEndpoint(path: String)
    case transport(underlying: Error)
    case unexpectedStatus(status: Int)
    case decoding(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:       return "You're signed out — sign in to sync prices."
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
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

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

    /// `PUT /v1/owned` — atomic replace of the caller's owned list.
    @discardableResult
    func putOwned(_ body: OwnedRequestDTO) async throws -> OwnedResponseDTO {
        try await send("v1/owned", method: "PUT", body: body)
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
        let request = try await authorizedRequest(path: path, method: "GET")
        return try await perform(request)
    }

    private func send<Body: Encodable, T: Decodable>(
        _ path: String,
        method: String,
        body: Body
    ) async throws -> T {
        var request = try await authorizedRequest(path: path, method: method)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
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
            throw BackendAPIError.unexpectedStatus(status: http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BackendAPIError.decoding(underlying: error)
        }
    }
}

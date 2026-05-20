//
//  FrankfurterClient.swift
//  UginsVault — Data layer / FX
//
//  Frankfurter.app — free, no-auth ECB rates. Used for USD→EUR.
//  Endpoint: https://api.frankfurter.app/latest?from=USD&to=EUR
//

import Foundation

public actor FrankfurterClient {

    public struct LatestResponse: Decodable, Sendable {
        public let amount: Double
        public let base: String
        public let date: String
        public let rates: [String: Double]
    }

    public struct Configuration: Sendable {
        public let baseURL: URL
        public init(baseURL: URL) { self.baseURL = baseURL }
        public static let `default` = Configuration(
            baseURL: URL(string: "https://api.frankfurter.app/")!
        )
    }

    private let configuration: Configuration
    private let session: URLSession

    public init(
        configuration: Configuration = .default,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    public func fetchRate(from base: String, to quote: String) async throws -> Double {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "from", value: base.uppercased()),
            URLQueryItem(name: "to",   value: quote.uppercased())
        ]
        let query = components.percentEncodedQuery ?? ""
        let url = configuration.baseURL.appendingPathComponent("latest")
            .appending(component: "")   // ensures no trailing slash collapse
        var request = URLRequest(url: URL(string: "\(url.absoluteString)?\(query)")!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw FXError.unexpectedStatus(http.statusCode)
        }
        let payload = try JSONDecoder().decode(LatestResponse.self, from: data)
        guard let rate = payload.rates[quote.uppercased()] else {
            throw FXError.decodeFailed("missing rate for \(quote)")
        }
        return rate
    }
}

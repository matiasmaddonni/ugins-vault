//
//  DolarAPIClient.swift
//  UginsVault — Data layer / FX
//
//  Thin client over `dolarapi.com.ar`. Default endpoint:
//  https://dolarapi.com/v1/dolares/blue
//  → `{ "compra": 1390, "venta": 1430, "fechaActualizacion": "…" }`
//  We use `venta` (sell side) — that's what collectors pay when
//  buying USD-priced cards.
//

import Foundation

public actor DolarAPIClient {

    public struct Quote: Decodable, Sendable {
        public let venta: Double
        public let compra: Double?
        public let fechaActualizacion: String?
    }

    public struct Configuration: Sendable {
        public let baseURL: URL
        public let userAgent: String
        public init(baseURL: URL, userAgent: String) {
            self.baseURL = baseURL
            self.userAgent = userAgent
        }
        public static let `default` = Configuration(
            baseURL: URL(string: "https://dolarapi.com/v1/dolares/")!,
            userAgent: "UginsVault/0.7 (matiasmaddonni@gmail.com)"
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

    /// Fetches the blue-dollar quote. `venta` is the canonical "what
    /// you pay for 1 USD" number — used as the USD→ARS multiplier.
    public func fetchBlue() async throws -> Quote {
        let url = configuration.baseURL.appendingPathComponent("blue")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw FXError.unexpectedStatus(http.statusCode)
        }
        return try JSONDecoder().decode(Quote.self, from: data)
    }
}

public enum FXError: Error, LocalizedError, Equatable {
    case unexpectedStatus(Int)
    case decodeFailed(String)
    case noRoute

    public var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let code): return "FX upstream returned HTTP \(code)"
        case .decodeFailed(let m):        return "FX decode failed: \(m)"
        case .noRoute:                    return "No route to convert these currencies"
        }
    }
}

//
//  MTGJSONClient.swift
//  UginsVault — Data layer / MTGJSON
//
//  Actor-based downloader for MTGJSON's pricing dump. Streams the
//  ~50MB AllPricesToday.json straight to disk via
//  `URLSession.download(for:)`, then hands the resulting file URL to
//  the parser. We never hold the full payload in memory — the parser
//  reads from disk in chunks.
//

import Foundation

public actor MTGJSONClient {

    public struct Configuration: Sendable {
        public let baseURL: URL
        public let userAgent: String

        public init(
            baseURL: URL,
            userAgent: String
        ) {
            self.baseURL = baseURL
            self.userAgent = userAgent
        }

        public static let `default` = Configuration(
            baseURL: URL(string: "https://mtgjson.com/api/v5/")!,
            userAgent: "UginsVault/0.5 (matiasmaddonni@gmail.com)"
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

    /// Downloads `AllPricesToday.json` to a temporary file and returns
    /// the on-disk URL. Caller is responsible for cleaning the file up
    /// once it's done parsing.
    public func downloadAllPricesToday() async throws -> URL {
        let path = "AllPricesToday.json"
        guard let url = URL(string: path, relativeTo: configuration.baseURL) else {
            throw MTGJSONError.invalidEndpoint(path: path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (tempURL, response): (URL, URLResponse)
        do {
            (tempURL, response) = try await session.download(for: request)
        } catch {
            throw MTGJSONError.transport(underlying: error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw MTGJSONError.unexpectedStatus(status: http.statusCode)
        }

        // Move into a stable spot — URLSession deletes the temp file
        // out from under us as soon as this call returns.
        let stable = FileManager.default.temporaryDirectory
            .appendingPathComponent("uv-mtgjson-\(UUID().uuidString).json")
        try? FileManager.default.removeItem(at: stable)
        try FileManager.default.moveItem(at: tempURL, to: stable)
        return stable
    }

    /// Downloads the FULL `AllPrices.json` history dump (~1.2 GB
    /// uncompressed; the server gzip-encodes it in transit, so the wire
    /// transfer is ~140 MB). Streamed to disk via `URLSession.download`
    /// — never held in memory. Caller cleans the file up. Backs the
    /// first-launch price-history bootstrap so the Dashboard sparkline +
    /// movers have real data immediately.
    public func downloadAllPrices() async throws -> URL {
        let path = "AllPrices.json"
        guard let url = URL(string: path, relativeTo: configuration.baseURL) else {
            throw MTGJSONError.invalidEndpoint(path: path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (tempURL, response): (URL, URLResponse)
        do {
            (tempURL, response) = try await session.download(for: request)
        } catch {
            throw MTGJSONError.transport(underlying: error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw MTGJSONError.unexpectedStatus(status: http.statusCode)
        }

        let stable = FileManager.default.temporaryDirectory
            .appendingPathComponent("uv-mtgjson-all-\(UUID().uuidString).json")
        try? FileManager.default.removeItem(at: stable)
        try FileManager.default.moveItem(at: tempURL, to: stable)
        return stable
    }
}

public enum MTGJSONError: Error, LocalizedError, Equatable {
    case invalidEndpoint(path: String)
    case unexpectedStatus(status: Int)
    case transport(underlying: Error)
    case parseFailed(message: String)

    public static func == (lhs: MTGJSONError, rhs: MTGJSONError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidEndpoint(let a), .invalidEndpoint(let b)): return a == b
        case (.unexpectedStatus(let a), .unexpectedStatus(let b)): return a == b
        case (.transport, .transport): return true
        case (.parseFailed(let a), .parseFailed(let b)): return a == b
        default: return false
        }
    }

    public var errorDescription: String? {
        switch self {
        case .invalidEndpoint(let path):       return "Bad endpoint: \(path)"
        case .unexpectedStatus(let status):    return "MTGJSON returned HTTP \(status)"
        case .transport(let error):            return error.localizedDescription
        case .parseFailed(let message):        return "Couldn't parse MTGJSON: \(message)"
        }
    }
}

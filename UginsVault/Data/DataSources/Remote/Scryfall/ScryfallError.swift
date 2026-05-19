//
//  ScryfallError.swift
//  UginsVault — Data layer / Scryfall
//
//  Errors emitted by the Scryfall client. The `apiError` case carries
//  the structured error envelope Scryfall returns on every 4xx / 5xx
//  response (https://scryfall.com/docs/api/errors).
//

import Foundation

public enum ScryfallError: Error, Sendable {

    /// The provided endpoint path could not be turned into a valid `URL`.
    case invalidEndpoint(path: String)

    /// `URLSession` failed before reaching Scryfall (DNS, offline, etc.).
    case transport(underlying: Error)

    /// Scryfall returned a non-2xx status with a parseable error envelope.
    case apiError(status: Int, envelope: APIErrorEnvelope)

    /// Scryfall returned a non-2xx status but the body did not decode as
    /// an error envelope.
    case unexpectedStatus(status: Int, body: Data)

    /// 2xx response but the body did not decode as the expected DTO.
    case decoding(underlying: Error)

    public struct APIErrorEnvelope: Decodable, Sendable {

        public let status: Int
        public let code: String
        public let details: String
        public let warnings: [String]?
        public let type: String?

        enum CodingKeys: String, CodingKey {
            case status, code, details, warnings, type
        }
    }
}

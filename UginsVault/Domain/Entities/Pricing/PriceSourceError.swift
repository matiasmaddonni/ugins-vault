//
//  PriceSourceError.swift
//  UginsVault — Domain layer / Pricing
//
//  Domain-level failures a `PriceCatalogueSource` can raise, so the
//  Presentation layer can react (e.g. an expired session → re-login) without
//  knowing about transport/SDK error types.
//

import Foundation

public enum PriceSourceError: Error, Equatable {
    /// The backend rejected the session (HTTP 401) — the user must sign in again.
    case unauthorized
}

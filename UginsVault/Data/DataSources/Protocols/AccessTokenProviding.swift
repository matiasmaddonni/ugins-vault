//
//  AccessTokenProviding.swift
//  UginsVault — Data layer
//
//  Data-internal seam that hands a fresh bearer token to the backend API
//  client without coupling it to the Supabase SDK. Implemented by
//  `SupabaseAccountRepository`; the API client depends only on this protocol.
//

import Foundation

public protocol AccessTokenProviding: Sendable {

    /// A valid (auto-refreshed) Supabase access token, or `nil` when there is
    /// no active session.
    func accessToken() async -> String?
}

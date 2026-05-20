//
//  BackendConfig.swift
//  UginsVault — Data layer / Backend
//
//  Static configuration for the Ugin's Vault backend + its Supabase project.
//
//  Security note: the Supabase anon (publishable) key below is public by
//  design — it cannot bypass Row-Level Security and is safe to ship inside the
//  client (per the backend API contract). The service-role / secret key is
//  NEVER placed here or anywhere in the app; only the server-side ingest holds
//  it. Per-user access tokens are obtained at runtime from Supabase Auth and
//  persisted by the SDK in the Keychain — never hard-coded.
//

import Foundation

enum BackendConfig {

    /// Supabase project URL (Auth + Postgres + RLS).
    static let supabaseURL = URL(string: "https://jmcbqwqkgpuscsgknaes.supabase.co")!

    /// Publishable / anon key. Public by design — safe in the client.
    static let supabaseAnonKey = "sb_publishable_27qtCn7viSLIOcDyTWJUiQ_u3Fp68pI"

    /// Base URL of the Vercel read API (prices / movers / fx / owned).
    static let apiBaseURL = URL(string: "https://ugins-vault-backend.vercel.app")!
}

//
//  PriceSyncAccessibilityFields.swift
//  UginsVault — Presentation: PriceSync
//
//  Accessibility identifiers used by the first-launch price-sync
//  loading screen + the manual refresh entry in Settings.
//

import Foundation

public enum PriceSyncAccessibilityFields {

    // MARK: - Loading screen

    public static let screen          = "scr_price_sync"
    public static let progressLabel   = "lbl_price_sync_progress"
    public static let countLabel      = "lbl_price_sync_count"
    public static let retryButton     = "btn_price_sync_retry"
    public static let dismissButton   = "btn_price_sync_dismiss"

    // MARK: - Wi-Fi alert

    public static let wifiAlert       = "alert_price_sync_wifi_required"

    // MARK: - Settings entry

    public static let settingsRefresh = "btn_settings_refresh_prices"
    public static let settingsLast    = "lbl_settings_last_synced"
}

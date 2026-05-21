//
//  DashboardAccessibilityFields.swift
//  UginsVault — Presentation: Dashboard
//
//  Accessibility identifiers used across the Dashboard tab. Stays in
//  one place so XCUITest / Appium don't depend on view-internal magic
//  strings.
//

import Foundation

public enum DashboardAccessibilityFields {

    // MARK: - Screen

    public static let screen = "scr_dashboard"
    public static let priceSyncBanner = "lbl_dashboard_price_sync"

    // MARK: - Nav

    public static let rangeToolbar = "btn_dashboard_range_toolbar"

    // MARK: - Hero

    public static let totalValueTile  = "view_dashboard_total_value_tile"
    public static let totalValueLabel = "lbl_dashboard_total_value"
    public static let totalDeltaLabel = "lbl_dashboard_total_delta"
    public static let sparkline       = "view_dashboard_sparkline"
    public static let weekMoversTile  = "view_dashboard_week_movers_tile"

    // MARK: - Movers row

    public static let gainersCard = "view_dashboard_gainers_card"
    public static let losersCard  = "view_dashboard_losers_card"

    public static func moverRow(side: String, at index: Int) -> String {
        "cell_dashboard_\(side)_row_\(index)"
    }

    // MARK: - Sections

    public static let byFormatPanel = "view_dashboard_by_format"
    public static let bySetPanel    = "view_dashboard_by_set"
    public static let wishlistTile  = "view_dashboard_wishlist"
    public static let quickStatsRow = "view_dashboard_quick_stats"

    public static func quickStatCard(_ key: String) -> String {
        "view_dashboard_quick_stat_\(key)"
    }

    public static func setBar(at index: Int) -> String {
        "cell_dashboard_set_bar_\(index)"
    }

    public static func formatSlice(_ id: String) -> String {
        "lbl_dashboard_format_\(id)"
    }
}

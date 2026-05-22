//
//  StackStatisticsAccessibilityFields.swift
//  UginsVault — Presentation: Stacks
//
//  Accessibility identifiers for the per-stack Statistics screen.
//  See `.claude/rules/ui-design.md` for the naming convention.
//

import Foundation

public enum StackStatisticsAccessibilityFields {

    // MARK: - Screen

    public static let screen = "scr_stack_statistics"

    // MARK: - Panels

    public static let summaryPanel  = "view_stack_stats_summary"
    public static let commanderRow  = "lbl_stack_stats_commander"
    public static let colorsPanel   = "view_stack_stats_colors"
    public static let rarityPanel   = "view_stack_stats_rarity"
    public static let curvePanel    = "view_stack_stats_curve"
    public static let topCardsPanel = "view_stack_stats_top_cards"

    // MARK: - Dynamic rows

    public static func colorLegend(_ id: String) -> String {
        "lbl_stack_stats_color_\(id)"
    }

    public static func rarityBar(_ id: String) -> String {
        "lbl_stack_stats_rarity_\(id)"
    }

    public static func curveBar(at index: Int) -> String {
        "lbl_stack_stats_curve_\(index)"
    }

    public static func topCard(at index: Int) -> String {
        "cell_stack_stats_top_\(index)"
    }
}

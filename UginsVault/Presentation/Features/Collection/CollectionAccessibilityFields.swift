//
//  CollectionAccessibilityFields.swift
//  UginsVault — Presentation: Collection
//
//  Accessibility identifiers used across the Collection feature views.
//  See `.claude/rules/ui-design.md` for the naming convention.
//

import Foundation

public enum CollectionAccessibilityFields {

    // MARK: - Screen

    public static let screen = "scr_collection"

    // MARK: - Header

    public static let title              = "lbl_collection_title"
    public static let cardCountLabel     = "lbl_collection_card_count"
    public static let totalValueLabel    = "lbl_collection_total_value"

    // MARK: - Search

    public static let searchField        = "srch_collection_query"

    // MARK: - Toolbar

    public static let addCardToolbar     = "btn_collection_add_card_toolbar"

    // MARK: - Empty state

    public static let emptyStateTitle    = "lbl_collection_empty_title"
    public static let emptyAddCardButton = "btn_collection_empty_add_card"
    public static let emptyImportCSVButton = "btn_collection_empty_import_csv"
}

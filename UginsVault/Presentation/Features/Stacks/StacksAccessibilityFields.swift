//
//  StacksAccessibilityFields.swift
//  UginsVault — Presentation: Stacks
//
//  Accessibility identifiers used across the Stacks tab views.
//  See `.claude/rules/ui-design.md` for the naming convention.
//

import Foundation

public enum StacksAccessibilityFields {

    // MARK: - Screen

    public static let screen = "scr_stacks"

    // MARK: - Header

    public static let title           = "lbl_stacks_title"
    public static let summaryLine     = "lbl_stacks_summary"
    public static let stackCountValue = "lbl_stacks_count_value"
    public static let cardCountValue  = "lbl_stacks_card_count_value"
    public static let totalValueLabel = "lbl_stacks_total_value"

    // MARK: - Toolbar

    public static let addStackToolbar = "btn_stacks_add_stack_toolbar"

    // MARK: - Filter chips

    public static let filterAll       = "btn_stacks_filter_all"

    /// Per-kind filter chip — call site passes the `StackKind`'s rawValue.
    public static func filterChip(for raw: String) -> String {
        accessibilityId("btn_stacks_filter", raw)
    }

    // MARK: - List

    public static let list = "view_stacks_list"

    public static func row(at index: Int) -> String {
        "cell_stacks_row_\(index)"
    }

    public static func rowCover(at index: Int) -> String {
        "view_stacks_row_cover_\(index)"
    }

    public static func rowName(at index: Int) -> String {
        "lbl_stacks_row_name_\(index)"
    }

    public static func rowBadge(at index: Int) -> String {
        "lbl_stacks_row_badge_\(index)"
    }

    public static func rowSubtitle(at index: Int) -> String {
        "lbl_stacks_row_subtitle_\(index)"
    }

    public static func rowCardCount(at index: Int) -> String {
        "lbl_stacks_row_card_count_\(index)"
    }

    public static func rowValue(at index: Int) -> String {
        "lbl_stacks_row_value_\(index)"
    }

    public static func rowDelete(at index: Int) -> String {
        "btn_stacks_row_delete_\(index)"
    }

    // MARK: - Empty state

    public static let emptyStateTitle  = "lbl_stacks_empty_title"
    public static let emptyAddButton   = "btn_stacks_empty_add"

    // MARK: - Create sheet

    public static let createSheet      = "view_stacks_create_sheet"
    public static let createName       = "txt_stacks_create_name"
    public static let createCommander  = "txt_stacks_create_commander"
    public static let createPerson     = "txt_stacks_create_person"
    public static let createSave       = "btn_stacks_create_save"
    public static let createCancel     = "btn_stacks_create_cancel"
}

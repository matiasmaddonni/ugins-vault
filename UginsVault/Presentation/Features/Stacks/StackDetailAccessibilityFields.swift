//
//  StackDetailAccessibilityFields.swift
//  UginsVault — Presentation: Stacks
//
//  Accessibility identifiers used across the Stack detail screen.
//  See `.claude/rules/ui-design.md` for the naming convention.
//

import Foundation

public enum StackDetailAccessibilityFields {

    // MARK: - Screen

    public static let screen = "scr_stack_detail"

    // MARK: - Hero

    public static let heroName        = "lbl_stack_detail_name"
    public static let heroBadge       = "lbl_stack_detail_badge"
    public static let heroSubtitle    = "lbl_stack_detail_subtitle"
    public static let heroCards       = "lbl_stack_detail_cards"
    public static let heroUnique      = "lbl_stack_detail_unique"
    public static let heroValue       = "lbl_stack_detail_value"

    // MARK: - Action bar

    public static let actionBar = "view_stack_detail_action_bar"

    public static func actionButton(id: String) -> String {
        accessibilityId("btn_stack_detail_action", id)
    }

    // MARK: - List / empty

    public static let cardList        = "view_stack_detail_card_list"
    public static let emptyTitle      = "lbl_stack_detail_empty_title"
    public static let emptyAddButton  = "btn_stack_detail_empty_add"

    public static func row(at index: Int) -> String {
        "cell_stack_detail_row_\(index)"
    }

    // MARK: - Nav

    public static let backButton = "btn_stack_detail_back"
}

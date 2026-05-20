//
//  WishlistAccessibilityFields.swift
//  UginsVault — Presentation: Wishlist
//
//  Accessibility identifiers for the Wishlist screen + add sheet.
//

import Foundation

enum WishlistAccessibilityFields {

    // MARK: - Screen
    static let screen          = "scr_wishlist"
    static let list            = "view_wishlist_list"
    static let addToolbar      = "btn_wishlist_add"
    static let emptyState      = "view_wishlist_empty"
    static let emptyAddButton  = "btn_wishlist_empty_add"

    static func row(at index: Int) -> String        { "cell_wishlist_row_\(index)" }
    static func removeButton(at index: Int) -> String { "btn_wishlist_remove_\(index)" }

    // MARK: - Add sheet
    static let addSheet        = "mdl_wishlist_add"
    static let searchField     = "srch_wishlist_add"
    static let addDoneButton   = "btn_wishlist_add_done"

    static func resultRow(at index: Int) -> String       { "cell_wishlist_result_\(index)" }
    static func resultAddButton(at index: Int) -> String { "btn_wishlist_result_add_\(index)" }
}

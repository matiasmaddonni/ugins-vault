//
//  SettingsAccessibilityFields.swift
//  UginsVault — Presentation: Settings
//
//  Accessibility identifiers used across the Settings feature views.
//

import Foundation

public enum SettingsAccessibilityFields {

    // MARK: - Screen

    public static let screen = "scr_settings"

    // MARK: - Profile hero

    public static let profileHero        = "view_settings_profile_hero"
    public static let profileName        = "lbl_settings_profile_name"
    public static let profileSubtitle    = "lbl_settings_profile_subtitle"
    public static let profileAvatar      = "view_settings_profile_avatar"

    public static let editProfileSheet   = "scr_settings_edit_profile"
    public static let editProfileName    = "view_settings_edit_profile_name"
    public static let editProfileSave    = "btn_settings_edit_profile_save"
    public static let editProfileCancel  = "btn_settings_edit_profile_cancel"

    public static func tintChip(_ tint: MonogramTint) -> String {
        "btn_settings_edit_profile_tint_\(tint.rawValue)"
    }

    // MARK: - Display group

    public static let appearancePicker   = "seg_settings_appearance"
    public static let languageRow        = "btn_settings_language"
    public static let currencyRow        = "btn_settings_currency"
    public static let reduceMotionToggle = "btn_settings_reduce_motion"

    public static let languageSheet      = "scr_settings_language_sheet"
    public static let currencySheet      = "scr_settings_currency_sheet"

    public static func languageOption(_ language: Language) -> String {
        "btn_settings_language_option_\(language.rawValue)"
    }

    public static func currencyOption(_ currency: Currency) -> String {
        "btn_settings_currency_option_\(currency.rawValue.lowercased())"
    }

    // MARK: - Collection group

    public static let wishlistRow        = "btn_settings_wishlist"

    // MARK: - Privacy group

    public static let faceIDLockToggle   = "btn_settings_face_id_lock"

    // MARK: - Data group

    public static let catalogueSizeRow   = "lbl_settings_catalogue_size"
    public static let resetCatalogueRow  = "btn_settings_reset_catalogue"
    public static let resetConfirmButton = "btn_settings_reset_confirm"

    // MARK: - About group

    public static let versionRow         = "lbl_settings_version"
    public static let acknowledgementsRow = "btn_settings_acknowledgements"
    public static let acknowledgementsSheet = "scr_settings_acknowledgements"
    public static let mtgFooterLabel     = "lbl_settings_mtg_footer"
}

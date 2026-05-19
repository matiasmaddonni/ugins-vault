//
//  StackKind.swift
//  UginsVault — Domain layer
//
//  Categorises a physical pile of cards. The kind drives the cover
//  visual, the badge accent colour, the default subtitle string, and
//  the action-bar buttons on the Stack detail screen.
//

import Foundation

public enum StackKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case deck
    case binder
    case loan
    case sale
    case showcase
    case inbox

    public var id: String { rawValue }

    /// User-facing label (`Stack.kind.displayLabel`).
    public var displayLabel: String {
        switch self {
        case .deck:     return String(localized: "Deck")
        case .binder:   return String(localized: "Binder")
        case .loan:     return String(localized: "On loan")
        case .sale:     return String(localized: "For sale")
        case .showcase: return String(localized: "Showcase")
        case .inbox:    return String(localized: "Unsorted")
        }
    }

    /// SF Symbol used by `StackCover` (non-deck mode) and the filter chip.
    public var iconName: String {
        switch self {
        case .deck:     return "rectangle.stack.fill"
        case .binder:   return "book.closed.fill"
        case .loan:     return "person.fill"
        case .sale:     return "tag.fill"
        case .showcase: return "sparkles"
        case .inbox:    return "tray.fill"
        }
    }

    /// Default subtitle copy used in `StackRow` when no richer info is
    /// available (e.g. binders/inbox/showcase don't carry extra fields).
    public var defaultSubtitle: String {
        switch self {
        case .deck:     return ""           // overridden by deck format
        case .binder:   return String(localized: "For trade")
        case .loan:     return ""           // overridden by loan since
        case .sale:     return String(localized: "Listed")
        case .showcase: return String(localized: "Display only")
        case .inbox:    return String(localized: "Needs sorting")
        }
    }
}

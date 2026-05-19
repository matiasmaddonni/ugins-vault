//
//  SwiftDataStack.swift
//  UginsVault — Data layer / SwiftData
//
//  Persistence shape for Domain `Stack`. Lives in the Data layer so the
//  Domain entity stays pure. Mapped by `StackMapper`.
//

import Foundation
import SwiftData

@Model
public final class SwiftDataStack {

    @Attribute(.unique) public var id: UUID
    public var name: String
    public var kindRaw: String
    public var sortOrder: Int
    public var createdAt: Date

    // MARK: - Deck-only

    public var formatRaw: String?
    public var colorsRaw: String        // CSV — "R,G"
    public var commander: String?

    /// Scryfall printing id of the deck's commander, when set.
    /// Defaulted to `nil` so SwiftData lightweight migration can
    /// backfill the column on existing rows.
    public var commanderCardID: UUID? = nil

    // MARK: - Loan-only

    public var person: String?
    public var since: Date?

    public init(
        id: UUID,
        name: String,
        kindRaw: String,
        sortOrder: Int = 0,
        createdAt: Date = .init(),
        formatRaw: String? = nil,
        colorsRaw: String = "",
        commander: String? = nil,
        commanderCardID: UUID? = nil,
        person: String? = nil,
        since: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.kindRaw = kindRaw
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.formatRaw = formatRaw
        self.colorsRaw = colorsRaw
        self.commander = commander
        self.commanderCardID = commanderCardID
        self.person = person
        self.since = since
    }
}

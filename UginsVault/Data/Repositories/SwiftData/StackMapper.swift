//
//  StackMapper.swift
//  UginsVault — Data layer / SwiftData
//
//  Bidirectional translation between Domain `Stack` (value) and
//  `SwiftDataStack` (`@Model` reference).
//

import Foundation

extension Stack {

    init(from model: SwiftDataStack) {
        self.init(
            id: model.id,
            name: model.name,
            kind: StackKind(rawValue: model.kindRaw) ?? .inbox,
            sortOrder: model.sortOrder,
            createdAt: model.createdAt,
            format: model.formatRaw.flatMap(Format.init(rawValue:)),
            colors: Stack.parseColors(model.colorsRaw),
            commander: model.commander,
            commanderCardID: model.commanderCardID,
            person: model.person,
            since: model.since
        )
    }

    static func parseColors(_ raw: String) -> Set<ManaColor> {
        guard !raw.isEmpty else { return [] }
        return Set(raw.split(separator: ",").compactMap { ManaColor(rawValue: String($0)) })
    }

    static func encodeColors(_ colors: Set<ManaColor>) -> String {
        colors.map(\.rawValue).sorted().joined(separator: ",")
    }
}

extension SwiftDataStack {

    convenience init(from stack: Stack) {
        self.init(
            id: stack.id,
            name: stack.name,
            kindRaw: stack.kind.rawValue,
            sortOrder: stack.sortOrder,
            createdAt: stack.createdAt,
            formatRaw: stack.format?.rawValue,
            colorsRaw: Stack.encodeColors(stack.colors),
            commander: stack.commander,
            commanderCardID: stack.commanderCardID,
            person: stack.person,
            since: stack.since
        )
    }

    /// Mutating apply used by `save(_:)` for idempotent upserts.
    func apply(_ stack: Stack) {
        name            = stack.name
        kindRaw         = stack.kind.rawValue
        sortOrder       = stack.sortOrder
        createdAt       = stack.createdAt
        formatRaw       = stack.format?.rawValue
        colorsRaw       = Stack.encodeColors(stack.colors)
        commander       = stack.commander
        commanderCardID = stack.commanderCardID
        person          = stack.person
        since           = stack.since
    }
}

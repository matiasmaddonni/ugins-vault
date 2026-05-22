//
//  CommanderPickerSheet.swift
//  UginsVault — Presentation: Stacks
//
//  List sheet for promoting one of the stack's existing cards to its
//  commander. Searchable + shows a thumbnail per row so the user can
//  visually pick. Also exposes "Clear commander" when one is already
//  set. The commander stays as a regular `CollectionItem` row — this
//  sheet only updates `Stack.commanderCardID`.
//

import SwiftUI

public struct CommanderPickerSheet: View {

    @Environment(\.dismiss) private var dismiss

    /// Flattened, pre-sorted row with its lowercased name baked in so search
    /// is a plain substring check — NO per-keystroke dict lookups, name
    /// lowercasing, or re-sorting on the main actor.
    private struct Row: Identifiable {
        let id: UUID            // CollectionItem.id
        let cardID: UUID
        let card: Card?
        let name: String
        let lowerName: String
    }

    private let rows: [Row]
    public let currentCommanderCardID: UUID?

    public let onPick: (UUID) async -> Void
    public let onClear: () async -> Void

    @State private var query: String = ""

    public init(
        items: [CollectionItem],
        cardsByID: [UUID: Card],
        currentCommanderCardID: UUID?,
        onPick: @escaping (UUID) async -> Void,
        onClear: @escaping () async -> Void
    ) {
        // Build + sort the rows ONCE. Doing this lazily inside `body` (or in a
        // VM computed property) re-runs on every keystroke / observable tick
        // and stutters the search field.
        self.rows = items
            .map { item -> Row in
                let card = cardsByID[item.cardID]
                let name = card?.name ?? String(item.cardID.uuidString.prefix(8))
                return Row(
                    id: item.id,
                    cardID: item.cardID,
                    card: card,
                    name: name,
                    lowerName: name.lowercased()
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        self.currentCommanderCardID = currentCommanderCardID
        self.onPick = onPick
        self.onClear = onClear
    }

    public var body: some View {
        NavigationStack {
            cardList
                .background(Color.uv.bg.ignoresSafeArea())
                .navigationTitle("Pick commander")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .searchable(text: $query, prompt: Text("Search cards…"))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .tint(Color.uv.gold)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.uv.bg)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
                .foregroundStyle(Color.uv.muted)
        }
        if currentCommanderCardID != nil {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    Task {
                        await onClear()
                        dismiss()
                    }
                } label: {
                    Text("Clear")
                        .font(.uv.body(15, weight: .semibold))
                        .foregroundStyle(Color.uv.down)
                }
            }
        }
    }

    private var filtered: [Row] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return rows }
        return rows.filter { $0.lowerName.contains(q) }
    }

    private var cardList: some View {
        List {
            ForEach(filtered) { row in
                Button {
                    Task { await onPick(row.cardID) }
                } label: {
                    rowView(row)
                }
                .listRowBackground(Color.uv.bg)
                .listRowSeparatorTint(Color.uv.stroke.opacity(0.4))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.uv.bg)
    }

    private func rowView(_ row: Row) -> some View {
        let isCurrent = (row.cardID == currentCommanderCardID)
        return HStack(spacing: Spacing.md) {
            CollectionItemThumbnail(card: row.card)

            VStack(alignment: .leading, spacing: Spacing.xs - 2) {
                Text(row.name)
                    .font(.uv.body(14, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)
                if let card = row.card {
                    Text("\(card.setCode.uppercased()) · #\(card.collectorNumber)")
                        .font(.uv.mono(11))
                        .foregroundStyle(Color.uv.muted)
                }
            }

            Spacer(minLength: Spacing.sm)

            if isCurrent {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Color.uv.gold)
            }
        }
    }
}

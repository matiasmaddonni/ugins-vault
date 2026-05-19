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

    public let items: [CollectionItem]
    public let cardsByID: [UUID: Card]
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
        self.items = items
        self.cardsByID = cardsByID
        self.currentCommanderCardID = currentCommanderCardID
        self.onPick = onPick
        self.onClear = onClear
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                cardList
            }
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Pick commander")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
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

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.uv.muted)
            TextField("Search cards…", text: $query)
                .font(.uv.body(14))
                .foregroundStyle(Color.uv.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.md - 2)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
        )
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.vertical, Spacing.md)
    }

    private var filtered: [CollectionItem] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return items }
        return items.filter { (cardsByID[$0.cardID]?.name ?? "").lowercased().contains(q) }
    }

    private var cardList: some View {
        List {
            ForEach(Array(filtered.enumerated()), id: \.element.id) { _, item in
                Button {
                    Task { await onPick(item.cardID) }
                } label: {
                    row(for: item)
                }
                .listRowBackground(Color.uv.bg)
                .listRowSeparatorTint(Color.uv.stroke.opacity(0.4))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.uv.bg)
    }

    private func row(for item: CollectionItem) -> some View {
        let card = cardsByID[item.cardID]
        let isCurrent = (item.cardID == currentCommanderCardID)
        return HStack(spacing: Spacing.md) {
            CollectionItemThumbnail(card: card)

            VStack(alignment: .leading, spacing: Spacing.xs - 2) {
                Text(card?.name ?? String(item.cardID.uuidString.prefix(8)))
                    .font(.uv.body(14, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)
                if let card {
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

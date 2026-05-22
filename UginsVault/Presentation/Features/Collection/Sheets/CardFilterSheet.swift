//
//  CardFilterSheet.swift
//  UginsVault — Presentation: Collection
//
//  Multi-select filter for the Collection list. Sets (searchable — a
//  collection can span dozens of editions), colours, and rarities are
//  checkmark rows. Apply / Clear at the top. Empty selections = no constraint.
//

import SwiftUI

public struct CardFilterSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var sets: Set<String>
    @State private var colors: Set<ManaColor>
    @State private var rarities: Set<Rarity>
    @State private var setQuery: String = ""

    private let availableSetCodes: [String]
    private let onApply: (CardFilter) -> Void

    public init(
        initialFilter: CardFilter,
        availableSetCodes: [String],
        onApply: @escaping (CardFilter) -> Void
    ) {
        self._sets = State(initialValue: initialFilter.sets)
        self._colors = State(initialValue: initialFilter.colors)
        self._rarities = State(initialValue: initialFilter.rarities)
        self.availableSetCodes = availableSetCodes
        self.onApply = onApply
    }

    public var body: some View {
        NavigationStack {
            List {
                setsSection
                coloursSection
                raritiesSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        sets.removeAll()
                        colors.removeAll()
                        rarities.removeAll()
                    }
                    .foregroundStyle(Color.uv.muted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onApply(CardFilter(sets: sets, colors: colors, rarities: rarities))
                        dismiss()
                    }
                    .foregroundStyle(Color.uv.gold)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.uv.bg)
    }

    // MARK: - Sets (searchable)

    @ViewBuilder
    private var setsSection: some View {
        if !availableSetCodes.isEmpty {
            Section {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.uv.muted)
                    TextField("Filter sets", text: $setQuery)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(Color.uv.text)
                }
                .listRowBackground(Color.uv.panel)

                ForEach(filteredSets, id: \.self) { code in
                    selectRow(label: code.uppercased(), isOn: sets.contains(code)) {
                        toggleSet(code)
                    }
                }
                if filteredSets.isEmpty {
                    Text(setQuery.isEmpty ? "Type to find a set" : "No sets match")
                        .font(.uv.body(13))
                        .foregroundStyle(Color.uv.muted)
                        .listRowBackground(Color.uv.panel)
                }
            } header: {
                Text(sets.isEmpty ? "Sets" : "Sets — \(sets.count) selected")
            }
        }
    }

    private var filteredSets: [String] {
        let query = setQuery.trimmingCharacters(in: .whitespaces).lowercased()
        let sorted = availableSetCodes.sorted()
        // No query → show only the already-selected sets (the field is how you
        // find more). Avoids dumping 30+ rows.
        if query.isEmpty { return sorted.filter { sets.contains($0) } }
        return sorted.filter { $0.lowercased().contains(query) }
    }

    // MARK: - Colours

    private var coloursSection: some View {
        Section {
            ForEach(ManaColor.allCases, id: \.self) { color in
                selectRow(label: color.displayName, isOn: colors.contains(color)) {
                    toggleColor(color)
                }
            }
        } header: {
            Text("Colours")
        }
    }

    // MARK: - Rarity

    private var raritiesSection: some View {
        Section {
            ForEach(Rarity.allCases.filter { $0 != .unknown }, id: \.self) { rarity in
                selectRow(label: rarity.displayName, isOn: rarities.contains(rarity)) {
                    toggleRarity(rarity)
                }
            }
        } header: {
            Text("Rarity")
        }
    }

    // MARK: - Helpers

    private func selectRow(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.uv.body(15))
                    .foregroundStyle(Color.uv.text)
                Spacer()
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.uv.body(14, weight: .semibold))
                        .foregroundStyle(Color.uv.gold)
                }
            }
        }
        .listRowBackground(Color.uv.panel)
    }

    private func toggleSet(_ value: String) {
        if sets.contains(value) { sets.remove(value) } else { sets.insert(value) }
    }

    private func toggleColor(_ value: ManaColor) {
        if colors.contains(value) { colors.remove(value) } else { colors.insert(value) }
    }

    private func toggleRarity(_ value: Rarity) {
        if rarities.contains(value) { rarities.remove(value) } else { rarities.insert(value) }
    }
}

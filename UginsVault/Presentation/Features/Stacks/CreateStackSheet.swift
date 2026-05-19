//
//  CreateStackSheet.swift
//  UginsVault — Presentation: Stacks
//
//  Bottom sheet for spinning up a new `Stack`. Captures the minimum
//  required fields per kind:
//   • All kinds: name + kind picker
//   • Deck: optional format + colour identity + optional commander
//   • Loan: optional "person" string
//
//  Submits through the parent `StacksListViewModel.createStack(...)`
//  intent. Stays simple — heavy editing (rename, recolour, reassign
//  format) happens later from `StackDetailView`.
//

import SwiftUI

public struct CreateStackSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var kind: StackKind = .deck
    @State private var format: Format = .commander
    @State private var commander: String = ""
    @State private var person: String = ""
    @State private var selectedColors: Set<ManaColor> = []
    @State private var isSaving: Bool = false

    private let onSubmit: (String, StackKind, Format?, Set<ManaColor>, String?, String?) async -> Void

    public init(
        onSubmit: @escaping (String, StackKind, Format?, Set<ManaColor>, String?, String?) async -> Void
    ) {
        self.onSubmit = onSubmit
    }

    public var body: some View {
        NavigationStack {
            Form {
                generalSection
                if kind == .deck {
                    deckSection
                    colorsSection
                }
                if kind == .loan {
                    loanSection
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("New stack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .tint(Color.uv.gold)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.uv.bg)
        .accessibilityIdentifier(StacksAccessibilityFields.createSheet)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
                .foregroundStyle(Color.uv.muted)
                .accessibilityIdentifier(StacksAccessibilityFields.createCancel)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await save() }
            } label: {
                if isSaving {
                    ProgressView().tint(Color.uv.gold)
                } else {
                    Text("Save")
                        .font(.uv.body(15, weight: .semibold))
                        .foregroundStyle(canSave ? Color.uv.gold : Color.uv.muted)
                }
            }
            .disabled(!canSave || isSaving)
            .accessibilityIdentifier(StacksAccessibilityFields.createSave)
        }
    }

    // MARK: - Sections

    private var generalSection: some View {
        Section {
            TextField("Stack name", text: $name)
                .accessibilityIdentifier(StacksAccessibilityFields.createName)

            Picker("Kind", selection: $kind) {
                ForEach(StackKind.allCases) { kind in
                    Label(kind.displayLabel, systemImage: kind.iconName)
                        .tag(kind)
                }
            }
        } header: {
            Text("Stack")
        }
        .listRowBackground(Color.uv.panel)
    }

    private var deckSection: some View {
        Section {
            Picker("Format", selection: $format) {
                ForEach(Format.allCases, id: \.self) { format in
                    Text(format.displayName).tag(format)
                }
            }

            TextField("Commander (optional)", text: $commander)
                .accessibilityIdentifier(StacksAccessibilityFields.createCommander)
        } header: {
            Text("Deck")
        }
        .listRowBackground(Color.uv.panel)
    }

    private var colorsSection: some View {
        Section {
            ForEach(ManaColor.allCases, id: \.self) { color in
                Toggle(isOn: bindingForColor(color)) {
                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(color.tintColor)
                            .frame(width: Layout.manaPipMedium, height: Layout.manaPipMedium)
                        Text(color.displayName)
                    }
                }
                .tint(Color.uv.gold)
            }
        } header: {
            Text("Colors")
        }
        .listRowBackground(Color.uv.panel)
    }

    private var loanSection: some View {
        Section {
            TextField("Lent to (optional)", text: $person)
                .accessibilityIdentifier(StacksAccessibilityFields.createPerson)
        } header: {
            Text("Loan")
        }
        .listRowBackground(Color.uv.panel)
    }

    // MARK: - Bindings + actions

    private func bindingForColor(_ color: ManaColor) -> Binding<Bool> {
        Binding(
            get: { selectedColors.contains(color) },
            set: { isOn in
                if isOn { selectedColors.insert(color) }
                else    { selectedColors.remove(color) }
            }
        )
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }

        await onSubmit(
            name,
            kind,
            kind == .deck ? format : nil,
            kind == .deck ? selectedColors : [],
            kind == .deck && !commander.isEmpty ? commander : nil,
            kind == .loan && !person.isEmpty ? person : nil
        )
        dismiss()
    }
}

//
//  ImportDeckListSheet.swift
//  UginsVault — Presentation: Stacks
//
//  Paste-text sheet for bulk-importing a deck list (Moxfield / Arena / MTGO)
//  into the current `Stack`. Tap "Import" → hand the text to the app-scoped
//  import coordinator and dismiss immediately; progress shows in the floating
//  pill above the tab bar so the app stays usable while it runs.
//

import SwiftUI

public struct ImportDeckListSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    let onImport: (String) -> Void

    public init(
        initialText: String = "",
        onImport: @escaping (String) -> Void
    ) {
        self._text = State(initialValue: initialText)
        self.onImport = onImport
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                instructions
                editor
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Import list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .tint(Color.uv.gold)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.uv.bg)
        .accessibilityIdentifier(StackDetailAccessibilityFields.importSheet)
    }

    // MARK: - Sections

    private var instructions: some View {
        Text("Paste from Moxfield, Arena or MTGO. One card per line: `4 Lightning Bolt` or `1 Sol Ring (CMM) 410`.")
            .font(.uv.body(12))
            .foregroundStyle(Color.uv.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )

            if text.isEmpty {
                Text("4 Lightning Bolt\n4 Counterspell\n1 Sol Ring (CMM) 410")
                    .font(.uv.mono(13))
                    .foregroundStyle(Color.uv.muted2)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.md)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(.uv.mono(13))
                .foregroundStyle(Color.uv.text)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityIdentifier(StackDetailAccessibilityFields.importTextEditor)
        }
        .frame(minHeight: Layout.importEditorMinHeight)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
                .foregroundStyle(Color.uv.muted)
                .accessibilityIdentifier(StackDetailAccessibilityFields.importCancel)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                onImport(text)
                dismiss()
            } label: {
                Text("Import")
                    .font(.uv.body(15, weight: .semibold))
                    .foregroundStyle(canImport ? Color.uv.gold : Color.uv.muted)
            }
            .disabled(!canImport)
            .accessibilityIdentifier(StackDetailAccessibilityFields.importSubmit)
        }
    }

    private var canImport: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

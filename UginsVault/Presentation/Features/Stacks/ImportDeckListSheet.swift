//
//  ImportDeckListSheet.swift
//  UginsVault — Presentation: Stacks
//
//  Big paste-text sheet for bulk-importing a deck list (Moxfield /
//  Arena / MTGO format) into the current `Stack`. Tap "Import" → the
//  view model parses every line, resolves it locally then via Scryfall,
//  and pushes matched cards into the stack as `CollectionItem` rows.
//

import SwiftUI

public struct ImportDeckListSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    @Binding var isImporting: Bool
    let progress: (current: Int, total: Int)
    let onImport: (String) async -> Void

    public init(
        isImporting: Binding<Bool>,
        progress: (current: Int, total: Int),
        onImport: @escaping (String) async -> Void
    ) {
        self._isImporting = isImporting
        self.progress = progress
        self.onImport = onImport
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                instructions

                editor

                if isImporting {
                    progressBar
                }
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
        .interactiveDismissDisabled(isImporting)
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

    private var progressBar: some View {
        VStack(spacing: Spacing.xs) {
            ProgressView(
                value: Double(progress.current),
                total: Double(max(progress.total, 1))
            )
            .tint(Color.uv.gold)

            HStack {
                Text("Resolving \(progress.current) / \(progress.total)")
                    .font(.uv.mono(11))
                    .foregroundStyle(Color.uv.muted)
                Spacer()
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
                .disabled(isImporting)
                .foregroundStyle(Color.uv.muted)
                .accessibilityIdentifier(StackDetailAccessibilityFields.importCancel)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await onImport(text) }
            } label: {
                Text("Import")
                    .font(.uv.body(15, weight: .semibold))
                    .foregroundStyle(canImport ? Color.uv.gold : Color.uv.muted)
            }
            .disabled(!canImport || isImporting)
            .accessibilityIdentifier(StackDetailAccessibilityFields.importSubmit)
        }
    }

    private var canImport: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

//
//  ImportResultToast.swift
//  UginsVault — Presentation: Stacks
//
//  Bottom toast rendered after an `ImportDeckListUseCase` run finishes.
//  Shows imported card count + (when non-empty) a tappable
//  unresolved-names list so the user can diff their paste against
//  what Scryfall could resolve.
//

import SwiftUI

public struct ImportResultToast: View {

    public let result: ImportDeckListUseCase.ImportResult
    public let onDismiss: () -> Void

    @State private var isExpanded: Bool = false

    public init(
        result: ImportDeckListUseCase.ImportResult,
        onDismiss: @escaping () -> Void
    ) {
        self.result = result
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            header
            if isExpanded, !result.unresolved.isEmpty {
                unresolvedList
            }
        }
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
        )
    }

    // MARK: - Header row

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: hasUnresolved ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(hasUnresolved ? Color.uv.warn : Color.uv.up)

            VStack(alignment: .leading, spacing: 0) {
                Text("Imported \(result.importedCards) cards")
                    .font(.uv.body(13, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                if hasUnresolved {
                    Button {
                        isExpanded.toggle()
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Text("\(result.unresolved.count) unresolved")
                                .font(.uv.body(11))
                                .foregroundStyle(Color.uv.muted)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.uv.muted)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button("Dismiss", action: onDismiss)
                .font(.uv.body(12, weight: .semibold))
                .foregroundStyle(Color.uv.gold)
        }
    }

    // MARK: - Unresolved list

    private var unresolvedList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(Array(result.unresolved.enumerated()), id: \.offset) { _, name in
                    Text("• \(name)")
                        .font(.uv.mono(11))
                        .foregroundStyle(Color.uv.text2)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, Spacing.xs)
        }
        .frame(maxHeight: Layout.importToastUnresolvedMaxHeight)
    }

    private var hasUnresolved: Bool { !result.unresolved.isEmpty }
}

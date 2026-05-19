//
//  SheetPicker.swift
//  UginsVault — Presentation: DesignSystem
//
//  Generic bottom-sheet picker. Pass a title, an option list, the current
//  selection, and a setter. Each option is rendered with its display label
//  and a gold check on the selected row.
//

import SwiftUI

public struct SheetPicker<Value: Hashable>: View {

    public struct Option: Identifiable {
        public let id: Value
        public let label: String
        public let detail: String?

        public init(id: Value, label: String, detail: String? = nil) {
            self.id = id
            self.label = label
            self.detail = detail
        }
    }

    @Environment(\.dismiss) private var dismiss

    private let title: String
    private let options: [Option]
    private let selection: Value
    private let onSelect: (Value) -> Void

    public init(
        title: String,
        options: [Option],
        selection: Value,
        onSelect: @escaping (Value) -> Void
    ) {
        self.title = title
        self.options = options
        self.selection = selection
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.uv.display(20, weight: .semibold))
                .foregroundStyle(Color.uv.text)
                .padding(.horizontal, Spacing.xl - 4)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.lg)

            VStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    Button {
                        onSelect(option.id)
                        dismiss()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                                Text(option.label)
                                    .font(.uv.body(16, weight: .medium))
                                    .foregroundStyle(Color.uv.text)

                                if let detail = option.detail {
                                    Text(detail)
                                        .font(.uv.body(12))
                                        .foregroundStyle(Color.uv.muted)
                                }
                            }

                            Spacer()

                            if option.id == selection {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color.uv.gold)
                            }
                        }
                        .padding(.horizontal, Spacing.xl - 4)
                        .padding(.vertical, Spacing.lg)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if option.id != options.last?.id {
                        Rectangle()
                            .fill(Color.uv.stroke.opacity(0.6))
                            .frame(height: Layout.hairline)
                            .padding(.leading, Spacing.xl - 4)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: UVRadius.lg)
                    .fill(Color.uv.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: UVRadius.lg)
                            .strokeBorder(Color.uv.stroke, lineWidth: 1)
                    )
            )
            .padding(.horizontal, Spacing.screenEdge)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.uv.bg)
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.uv.bg)
    }
}

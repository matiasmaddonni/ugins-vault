//
//  StackKindBadge.swift
//  UginsVault — Presentation: Stacks
//
//  Small pill rendered on `StackRow`. Shows the stack's `kind` (deck,
//  binder, loan, sale, showcase, inbox) with a kind-specific tint + icon.
//  When the stack is a deck and carries a Format, the badge swaps in the
//  format's display name + format tint instead.
//

import SwiftUI

public struct StackKindBadge: View {

    public let kind: StackKind
    public let format: Format?

    public init(kind: StackKind, format: Format? = nil) {
        self.kind = kind
        self.format = format
    }

    private var label: String {
        if kind == .deck, let format {
            return format.displayName
        }
        return kind.displayLabel
    }

    private var tint: Color {
        if kind == .deck, let format {
            return format.tint
        }
        return kind.accentColor
    }

    public var body: some View {
        HStack(spacing: Spacing.xs - 1) {
            Image(systemName: kind.iconName)
                .font(.system(size: Layout.stackBadgeIconSize, weight: .semibold))
            Text(label)
                .font(.uv.mono(10, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.8)
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs - 1)
        .background(
            Capsule()
                .fill(tint.opacity(0.14))
                .overlay(
                    Capsule()
                        .strokeBorder(tint.opacity(0.45), lineWidth: Layout.hairline)
                )
        )
    }
}

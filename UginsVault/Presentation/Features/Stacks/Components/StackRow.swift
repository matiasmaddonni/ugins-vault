//
//  StackRow.swift
//  UginsVault — Presentation: Stacks
//
//  Single row in the Stacks tab list. Cover (leading) + name + kind /
//  format badge + sub-line (commander · format / "On loan to X" /
//  "Listed" / etc.) + card count and chevron (trailing).
//
//  Pure presentation: receives precomputed `cardCount` + `displayValue`
//  from the view model so it doesn't reach into repositories itself.
//

import SwiftUI

public struct StackRow: View {

    public let stack: Stack
    public let cardCount: Int
    public let displayValue: String?
    public let index: Int

    public init(
        stack: Stack,
        cardCount: Int,
        displayValue: String? = nil,
        index: Int
    ) {
        self.stack = stack
        self.cardCount = cardCount
        self.displayValue = displayValue
        self.index = index
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            StackCover(stack: stack)
                .accessibilityIdentifier(StacksAccessibilityFields.rowCover(at: index))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                titleRow
                subtitleRow
                if !stack.colors.isEmpty && stack.kind == .deck {
                    ManaPipsView(colors: stack.colors)
                }
            }

            Spacer(minLength: Spacing.sm)

            trailing
        }
        .padding(.vertical, Layout.stackRowVertical)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(StacksAccessibilityFields.row(at: index))
    }

    // MARK: - Title row

    private var titleRow: some View {
        HStack(spacing: Spacing.sm) {
            Text(stack.name)
                .font(.uv.display(16, weight: .semibold))
                .foregroundStyle(Color.uv.text)
                .lineLimit(1)
                .accessibilityIdentifier(StacksAccessibilityFields.rowName(at: index))

            StackKindBadge(kind: stack.kind, format: stack.format)
                .accessibilityIdentifier(StacksAccessibilityFields.rowBadge(at: index))
        }
    }

    // MARK: - Subtitle row

    @ViewBuilder
    private var subtitleRow: some View {
        if let line = subtitleText, !line.isEmpty {
            Text(line)
                .font(.uv.body(12))
                .foregroundStyle(Color.uv.muted)
                .lineLimit(1)
                .accessibilityIdentifier(StacksAccessibilityFields.rowSubtitle(at: index))
        }
    }

    private var subtitleText: String? {
        switch stack.kind {
        case .deck:
            if let commander = stack.commander, !commander.isEmpty {
                return commander
            }
            return stack.format?.displayName
        case .loan:
            guard let person = stack.person, !person.isEmpty else {
                return StackKind.loan.defaultSubtitle
            }
            return String(localized: "On loan to \(person)")
        default:
            return stack.kind.defaultSubtitle
        }
    }

    // MARK: - Trailing block
    //
    // Note: no manual chevron — `NavigationLink` inside the `List` adds
    // its own disclosure indicator. Rendering a second one was a bug.

    private var trailing: some View {
        VStack(alignment: .trailing, spacing: Spacing.xs - 2) {
            Text("\(cardCount)")
                .font(.uv.mono(13, weight: .semibold))
                .foregroundStyle(Color.uv.text)
                .accessibilityIdentifier(StacksAccessibilityFields.rowCardCount(at: index))

            if let displayValue {
                Text(displayValue)
                    .font(.uv.mono(11))
                    .foregroundStyle(Color.uv.gold)
                    .accessibilityIdentifier(StacksAccessibilityFields.rowValue(at: index))
            }
        }
    }
}

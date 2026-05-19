//
//  StackHeroCard.swift
//  UginsVault — Presentation: Stacks
//
//  Top "header tile" rendered on the Stack detail screen. Big cover +
//  stack name + kind/format badge + subtitle + counts strip
//  (cards · unique · value). Pure presentation; counts arrive from the
//  Stack-detail view model.
//

import SwiftUI

public struct StackHeroCard: View {

    public let stack: Stack
    public let cardCount: Int
    public let uniqueCount: Int
    public let formattedValue: String
    public let subtitle: String

    public init(
        stack: Stack,
        cardCount: Int,
        uniqueCount: Int,
        formattedValue: String,
        subtitle: String
    ) {
        self.stack = stack
        self.cardCount = cardCount
        self.uniqueCount = uniqueCount
        self.formattedValue = formattedValue
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: Spacing.md + 2) {
            cover
            titleBlock
            statStrip
            if stack.kind == .deck, !stack.colors.isEmpty {
                ManaPipsView(colors: stack.colors, diameter: Layout.manaPipMedium)
            }
        }
        .padding(.vertical, Spacing.lg)
        .padding(.horizontal, Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.lg)
                .fill(Color.uv.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.lg)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
        )
    }

    // MARK: - Cover

    private var cover: some View {
        StackCover(stack: stack, size: Layout.stackHeroCoverSize)
    }

    // MARK: - Title block

    private var titleBlock: some View {
        VStack(spacing: Spacing.xs) {
            Text(stack.name)
                .font(.uv.display(22, weight: .semibold))
                .foregroundStyle(Color.uv.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            HStack(spacing: Spacing.sm) {
                StackKindBadge(kind: stack.kind, format: stack.format)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.uv.body(12))
                        .foregroundStyle(Color.uv.muted)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Stat strip

    private var statStrip: some View {
        HStack(spacing: 0) {
            stat(label: "Cards",  value: "\(cardCount)")
            verticalDivider
            stat(label: "Unique", value: "\(uniqueCount)")
            verticalDivider
            stat(label: "Value",  value: formattedValue)
        }
    }

    private func stat(label: String, value: String) -> some View {
        VStack(spacing: Spacing.xs - 2) {
            Text(value)
                .font(.uv.mono(15, weight: .semibold))
                .foregroundStyle(Color.uv.text)
            Text(label)
                .font(.uv.mono(10, weight: .semibold))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(Color.uv.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(Color.uv.stroke)
            .frame(width: Layout.statDividerWidth, height: Layout.statDividerHeight)
    }
}

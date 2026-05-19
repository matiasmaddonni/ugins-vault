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
import Kingfisher

public struct StackHeroCard: View {

    public let stack: Stack
    public let cardCount: Int
    public let formattedValue: String
    public let subtitle: String
    public let commanderArtURL: URL?

    public init(
        stack: Stack,
        cardCount: Int,
        formattedValue: String,
        subtitle: String,
        commanderArtURL: URL? = nil
    ) {
        self.stack = stack
        self.cardCount = cardCount
        self.formattedValue = formattedValue
        self.subtitle = subtitle
        self.commanderArtURL = commanderArtURL
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
    //
    // Rule: when an image is available (commander art for deck stacks,
    // can grow to user-uploaded later), render it. Otherwise fall back
    // to a clean tinted panel with the stack's kind glyph — never the
    // coloured deck-fan, which only makes sense on the list row.

    @ViewBuilder
    private var cover: some View {
        if let commanderArtURL {
            KFImage(commanderArtURL)
                .resizable()
                .scaledToFill()
                .frame(width: Layout.stackHeroCoverSize, height: Layout.stackHeroCoverSize)
                .clipShape(RoundedRectangle(cornerRadius: UVRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
        } else {
            basicIconCover
        }
    }

    private var basicIconCover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panelLo)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
            Image(systemName: stack.kind.iconName)
                .font(.system(size: Layout.stackHeroIconSize, weight: .medium))
                .foregroundStyle(stack.kind.accentColor)
        }
        .frame(width: Layout.stackHeroCoverSize, height: Layout.stackHeroCoverSize)
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
            stat(label: "Cards", value: "\(cardCount)")
            verticalDivider
            stat(label: "Value", value: formattedValue)
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

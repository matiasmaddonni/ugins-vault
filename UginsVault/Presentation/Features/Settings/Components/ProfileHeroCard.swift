//
//  ProfileHeroCard.swift
//  UginsVault — Presentation: Settings
//
//  The Settings tab hero. Avatar monogram + name + subtitle + placeholder
//  stat strip. Tapping anywhere opens an Edit Profile sheet.
//

import SwiftUI

public struct ProfileHeroCard: View {

    private let profile: UserProfile
    private let cardCount: Int?
    private let totalValueLabel: String?
    private let deckCount: Int?
    private let onTap: () -> Void

    public init(
        profile: UserProfile,
        cardCount: Int? = nil,
        totalValueLabel: String? = nil,
        deckCount: Int? = nil,
        onTap: @escaping () -> Void
    ) {
        self.profile = profile
        self.cardCount = cardCount
        self.totalValueLabel = totalValueLabel
        self.deckCount = deckCount
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.md + 2) {
                topRow
                statStrip
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack(alignment: .top) {
                    Color.uv.panel
                    LinearGradient(
                        colors: [Color.uv.gold.opacity(0.18), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: Spacing.huge)
                    .blendMode(.plusLighter)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: UVRadius.lg)
                    .strokeBorder(Color.uv.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: UVRadius.lg))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SettingsAccessibilityFields.profileHero)
    }

    // MARK: - Subviews

    private var topRow: some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            avatar

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(profile.name)
                    .font(.uv.display(20, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)
                    .accessibilityIdentifier(SettingsAccessibilityFields.profileName)

                Text("Planeswalker · since \(String(profile.memberSince))")
                    .font(.uv.body(12))
                    .foregroundStyle(Color.uv.muted)
                    .lineLimit(1)
                    .accessibilityIdentifier(SettingsAccessibilityFields.profileSubtitle)
            }

            Spacer(minLength: Spacing.sm)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.uv.muted)
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(tintFill)
                .frame(width: Layout.profileAvatarDiameter, height: Layout.profileAvatarDiameter)

            Text(profile.monogram)
                .font(.uv.mono(20, weight: .semibold))
                .foregroundStyle(Color.uv.gold)
        }
        .overlay(
            Circle().strokeBorder(Color.uv.gold, lineWidth: 1.5)
        )
        .accessibilityHidden(true)
        .accessibilityIdentifier(SettingsAccessibilityFields.profileAvatar)
    }

    private var statStrip: some View {
        HStack(spacing: 0) {
            statCell(label: "Cards", value: cardCount.map(String.init) ?? "—")
            divider
            statCell(label: "Value", value: totalValueLabel ?? "—")
            divider
            statCell(label: "Decks", value: deckCount.map(String.init) ?? "—")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md - 2)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.bg.opacity(0.5))
        )
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: Spacing.xs / 2) {
            Text(value)
                .font(.uv.mono(14, weight: .semibold))
                .foregroundStyle(Color.uv.text)
            Text(label)
                .uvSectionLabel()
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.uv.stroke)
            .frame(width: Layout.statDividerWidth, height: Layout.statDividerHeight)
    }

    private var tintFill: Color {
        switch profile.monogramTint {
        case .gold:     return Color.uv.gold.opacity(0.15)
        case .lavender: return Color.uv.lavender.opacity(0.18)
        case .verdant:  return Color.uv.up.opacity(0.18)
        case .crimson:  return Color.uv.down.opacity(0.18)
        case .mist:     return Color.uv.panelHi
        }
    }
}

//
//  SettingsRow.swift
//  UginsVault — Presentation: DesignSystem
//
//  Generic Settings row. Pick exactly one trailing style:
//
//   - `.value("USD")`           → display text + chevron (push row)
//   - `.control { … }`          → arbitrary SwiftUI control (Toggle, Picker, …)
//   - `.none`                   → no trailing element (push-only or info)
//
//  Always renders an icon, a title, and an optional subtitle on the leading side.
//

import SwiftUI

public struct SettingsRow<Trailing: View>: View {

    private let icon: String
    private let title: LocalizedStringKey
    private let subtitle: String?
    private let isDestructive: Bool
    private let action: (() -> Void)?
    private let trailing: Trailing

    public init(
        icon: String,
        title: LocalizedStringKey,
        subtitle: String? = nil,
        isDestructive: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.action = action
        self.trailing = trailing()
    }

    public var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: Layout.smallIcon, weight: .medium))
                    .foregroundStyle(isDestructive ? Color.uv.down : Color.uv.gold)
                    .frame(width: Layout.settingsRowIconWidth, alignment: .center)

                VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                    Text(title)
                        .font(.uv.body(15, weight: .medium))
                        .foregroundStyle(isDestructive ? Color.uv.down : Color.uv.text)

                    if let subtitle {
                        Text(subtitle)
                            .font(.uv.body(12))
                            .foregroundStyle(Color.uv.muted)
                    }
                }

                Spacer(minLength: Spacing.sm)

                trailing
            }
            .padding(.horizontal, Spacing.rowHorizontal)
            .padding(.vertical, Spacing.rowVertical)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.uv.stroke.opacity(0.6))
                .frame(height: Layout.hairline)
                .padding(.leading, Spacing.rowDividerLeading)
        }
        .disabled(action == nil && !(Trailing.self != EmptyView.self))
    }
}

// MARK: - Convenience initialisers

extension SettingsRow where Trailing == _SettingsRowChevron {

    /// Push row: shows the value as right-aligned mono text + chevron.
    public init(
        icon: String,
        title: LocalizedStringKey,
        subtitle: String? = nil,
        value: String?,
        action: @escaping () -> Void
    ) {
        self.init(
            icon: icon,
            title: title,
            subtitle: subtitle,
            action: action
        ) {
            _SettingsRowChevron(value: value)
        }
    }
}

extension SettingsRow where Trailing == EmptyView {

    /// Read-only / static row. No trailing element, no tap action.
    public init(
        icon: String,
        title: LocalizedStringKey,
        subtitle: String? = nil
    ) {
        self.init(
            icon: icon,
            title: title,
            subtitle: subtitle,
            action: nil
        ) {
            EmptyView()
        }
    }
}

public struct _SettingsRowChevron: View {
    let value: String?

    public var body: some View {
        HStack(spacing: Spacing.sm - 2) {
            if let value {
                Text(value)
                    .font(.uv.mono(13, weight: .medium))
                    .foregroundStyle(Color.uv.text)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.uv.muted)
        }
    }
}

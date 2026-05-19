//
//  UVChip.swift
//  UginsVault — Presentation: Design System
//
//  Generic filter / toggle chip. Gold tint when selected, panel tint when
//  not. Used by the Stacks tab to render the kind filter row
//  (All · Decks · Binders · Loans · Sales · Showcase · Unsorted).
//

import SwiftUI

public struct UVChip: View {

    public let title: String
    public let icon: String?
    public let isSelected: Bool
    public let action: () -> Void

    public init(
        title: String,
        icon: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs + 2) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: Layout.chipIconSize, weight: .semibold))
                }
                Text(title)
                    .font(.uv.body(13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color(hex: 0x1A1410) : Color.uv.text)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs + 3)
            .background(
                Capsule()
                    .fill(isSelected ? Color.uv.gold : Color.uv.panel)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isSelected ? Color.uv.gold : Color.uv.stroke,
                                lineWidth: Layout.hairline
                            )
                    )
            )
        }
        .buttonStyle(.pressable)
    }
}

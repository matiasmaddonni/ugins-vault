//
//  StackActionBar.swift
//  UginsVault — Presentation: Stacks
//
//  Horizontally scrolling bar of kind-aware action buttons rendered
//  underneath `StackHeroCard`. In v0.3 every action is a stub — tapping
//  fires `onAction` with the action id; concrete flows land in later
//  milestones.
//

import SwiftUI

public struct StackActionBar: View {

    public let actions: [StackAction]
    public let onAction: (StackAction) -> Void

    public init(actions: [StackAction], onAction: @escaping (StackAction) -> Void) {
        self.actions = actions
        self.onAction = onAction
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { _, action in
                    Button {
                        onAction(action)
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: action.icon)
                                .font(.system(size: Layout.mediumIcon, weight: .semibold))
                                .foregroundStyle(Color.uv.gold)
                            Text(action.label)
                                .font(.uv.body(11, weight: .medium))
                                .foregroundStyle(Color.uv.text)
                                .lineLimit(1)
                        }
                        .frame(width: Layout.stackActionWidth, height: Layout.stackActionHeight)
                        .glassEffect(in: RoundedRectangle(cornerRadius: UVRadius.md))
                    }
                    .buttonStyle(.pressable)
                    .accessibilityIdentifier(StackDetailAccessibilityFields.actionButton(id: action.id))
                }
            }
        }
        .scrollClipDisabled()
    }
}

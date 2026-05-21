//
//  UndoToast.swift
//  UginsVault — Presentation: DesignSystem
//
//  Bottom-anchored undo banner. Slides in when its `message` is non-nil
//  and slides out otherwise. The caller drives lifecycle — `UndoToast`
//  has no timer of its own.
//

import SwiftUI

public struct UndoToast: View {

    private let message: String
    private let actionTitle: String
    private let onUndo: () -> Void
    private let onDismiss: () -> Void

    public init(
        message: String,
        actionTitle: String = "Undo",
        onUndo: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.message = message
        self.actionTitle = actionTitle
        self.onUndo = onUndo
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.uv.gold)

            Text(message)
                .font(.uv.body(13, weight: .medium))
                .foregroundStyle(Color.uv.text)
                .lineLimit(2)

            Spacer(minLength: Spacing.sm)

            Button(action: onUndo) {
                Text(actionTitle)
                    .font(.uv.body(13, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.uv.muted)
                    .padding(Spacing.xs)
            }
            .accessibilityLabel("Dismiss")
        }
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.md)
        .glassEffect(in: RoundedRectangle(cornerRadius: UVRadius.lg))
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.bottom, Spacing.md)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

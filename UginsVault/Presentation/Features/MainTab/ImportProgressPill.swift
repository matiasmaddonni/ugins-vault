//
//  ImportProgressPill.swift
//  UginsVault — Presentation: MainTab
//
//  Floating Liquid Glass pill above the tab bar, bound to `ImportCoordinator`.
//  Shows a deck import's live progress while the app stays usable; on finish it
//  shows a summary and auto-dismisses, and on failure offers Retry. Tapping the
//  pill jumps to the Stacks tab.
//

import SwiftUI

struct ImportProgressPill: View {

    let coordinator: ImportCoordinator
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            leading

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.uv.body(13, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.uv.mono(11))
                        .foregroundStyle(Color.uv.muted)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            trailing
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .glassEffect()
        .contentShape(Capsule())
        .onTapGesture { onTap() }
        .task(id: coordinator.phase) { await autoDismissIfFinished() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(MainTabAccessibilityFields.importPill)
    }

    // MARK: - Pieces

    @ViewBuilder
    private var leading: some View {
        switch coordinator.phase {
        case .importing:
            ProgressView()
                .controlSize(.small)
                .tint(Color.uv.gold)
        case .finished:
            Image(systemName: "checkmark.circle.fill")
                .font(.uv.body(16))
                .foregroundStyle(Color.uv.gold)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.uv.body(16))
                .foregroundStyle(Color.uv.down)
        case .idle:
            EmptyView()
        }
    }

    @ViewBuilder
    private var trailing: some View {
        switch coordinator.phase {
        case .importing:
            Button { coordinator.cancel() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.uv.body(16))
                    .foregroundStyle(Color.uv.muted)
            }
            .accessibilityIdentifier(MainTabAccessibilityFields.importPillCancel)
        case .failed:
            Button { coordinator.retry() } label: {
                Text("Retry")
                    .font(.uv.body(13, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
            }
        case .finished:
            Button { coordinator.dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.uv.body(13, weight: .semibold))
                    .foregroundStyle(Color.uv.muted)
            }
        case .idle:
            EmptyView()
        }
    }

    // MARK: - Copy

    private var title: String {
        switch coordinator.phase {
        case .importing:
            return coordinator.total > 0
                ? String(localized: "Importing \(coordinator.current)/\(coordinator.total)")
                : String(localized: "Preparing import…")
        case .finished:
            let imported = coordinator.result?.importedLines ?? 0
            return String(localized: "Imported \(imported) cards")
        case .failed:
            return String(localized: "Import failed")
        case .idle:
            return ""
        }
    }

    private var subtitle: String? {
        switch coordinator.phase {
        case .importing:
            return coordinator.stackName.isEmpty ? nil : coordinator.stackName
        case .finished:
            let skipped = coordinator.result?.unresolved.count ?? 0
            return skipped > 0
                ? String(localized: "\(skipped) skipped · \(coordinator.stackName)")
                : coordinator.stackName
        case .failed:
            return coordinator.errorMessage
        case .idle:
            return nil
        }
    }

    private func autoDismissIfFinished() async {
        guard coordinator.phase == .finished else { return }
        try? await Task.sleep(for: .seconds(4))
        if coordinator.phase == .finished { coordinator.dismiss() }
    }
}

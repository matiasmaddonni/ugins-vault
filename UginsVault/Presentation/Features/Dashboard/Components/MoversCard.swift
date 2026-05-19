//
//  MoversCard.swift
//  UginsVault — Presentation: Dashboard
//
//  Reusable card showing the top N gainers OR losers in the
//  MoversRow underneath the hero. Tone (.up / .down) drives the
//  header arrow + percentage colour.
//

import SwiftUI

public enum MoverTone {
    case up, down

    var color: Color { self == .up ? Color.uv.up : Color.uv.down }
    var iconName: String { self == .up ? "arrow.up" : "arrow.down" }
    var sideAccessibilityKey: String { self == .up ? "gainer" : "loser" }
}

public struct MoversCard: View {

    public let title: String
    public let tone: MoverTone
    public let items: [Mover]

    public init(title: String, tone: MoverTone, items: [Mover]) {
        self.title = title
        self.tone = tone
        self.items = items
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, Spacing.sm)

            if items.isEmpty {
                emptyRow
                Spacer(minLength: 0)
            } else {
                ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, mover in
                    row(index: index + 1, mover: mover)
                    if index < min(items.count, 5) - 1 {
                        Spacer(minLength: Spacing.xs)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg - 2)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.lg)
                .fill(Color.uv.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.lg)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(
            tone == .up
                ? DashboardAccessibilityFields.gainersCard
                : DashboardAccessibilityFields.losersCard
        )
    }

    private var header: some View {
        HStack {
            Text(title)
                .uvSectionLabel()
            Spacer()
            Image(systemName: tone.iconName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tone.color)
        }
    }

    private var emptyRow: some View {
        Text("No data yet")
            .font(.uv.body(11))
            .foregroundStyle(Color.uv.muted)
    }

    private func row(index: Int, mover: Mover) -> some View {
        HStack(spacing: Spacing.sm) {
            Text("\(index)")
                .font(.uv.mono(9.5))
                .foregroundStyle(Color.uv.muted2)
                .frame(width: Layout.dashboardMoverIndexWidth, alignment: .trailing)

            VStack(alignment: .leading, spacing: 1) {
                Text(mover.name)
                    .font(.uv.body(12, weight: .medium))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)
                Text(mover.setCode.uppercased())
                    .font(.uv.mono(9.5))
                    .foregroundStyle(Color.uv.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(formatPct(mover.pct))
                .font(.uv.mono(11, weight: .semibold))
                .foregroundStyle(tone.color)
        }
        .accessibilityIdentifier(
            DashboardAccessibilityFields.moverRow(side: tone.sideAccessibilityKey, at: index - 1)
        )
    }

    private func formatPct(_ pct: Double) -> String {
        let prefix = pct >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", pct))%"
    }
}

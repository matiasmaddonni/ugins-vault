//
//  WeekMoversTile.swift
//  UginsVault — Presentation: Dashboard
//
//  Hero tile (right, 1fr). Shows the two strongest gainers and the
//  two strongest losers as a compact list. The bigger gainers/losers
//  cards underneath render the top 5 each.
//

import SwiftUI

public struct WeekMoversTile: View {

    public let gainers: [Mover]
    public let losers: [Mover]

    public init(gainers: [Mover], losers: [Mover]) {
        self.gainers = gainers
        self.losers = losers
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Week movers")
                .uvSectionLabel()
            ForEach(gainers.prefix(2)) { mover in
                row(mover: mover, tone: Color.uv.up)
            }
            Rectangle()
                .fill(Color.uv.stroke.opacity(0.6))
                .frame(height: Layout.hairline)
                .padding(.vertical, 2)
            ForEach(losers.prefix(2)) { mover in
                row(mover: mover, tone: Color.uv.down)
            }
            Spacer(minLength: 0)
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
        .accessibilityIdentifier(DashboardAccessibilityFields.weekMoversTile)
    }

    private func row(mover: Mover, tone: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(mover.name)
                .font(.uv.body(11, weight: .medium))
                .foregroundStyle(Color.uv.text)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(formatPct(mover.pct))
                .font(.uv.mono(10.5, weight: .semibold))
                .foregroundStyle(tone)
        }
    }

    private func formatPct(_ pct: Double) -> String {
        let prefix = pct >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", pct))%"
    }
}

//
//  DashboardView.swift
//  UginsVault — Presentation: Dashboard
//
//  Placeholder. Real charts (sparklines, gainers/losers, value-by-format)
//  land in v0.6 once the collection catalogue + price history exist.
//

import SwiftUI

public struct DashboardView: View {

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.uv.bg.ignoresSafeArea()

                VStack(spacing: 14) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color.uv.gold)

                    Text("Dashboard")
                        .font(.uv.display(22, weight: .semibold))
                        .foregroundStyle(Color.uv.text)

                    Text("Sparklines, gainers, losers and value by format land here in v0.6.")
                        .font(.uv.body(13))
                        .foregroundStyle(Color.uv.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}

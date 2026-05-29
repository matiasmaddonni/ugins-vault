//
//  GlobalLoadingBar.swift
//  UginsVault — Presentation: Design System
//
//  Slim indeterminate progress bar pinned to the top of the root view,
//  driven by `LoadingCoordinator.isLoading`. Decorative only — never
//  blocks input, never intercepts touches.
//
//  Pattern: a 2 pt animated capsule that slides L→R while any tracked
//  work is in flight. Hidden (zero opacity) when the coordinator is
//  idle, so it doesn't take layout space.
//

import SwiftUI

public struct GlobalLoadingBar: View {

    @Bindable public var coordinator: LoadingCoordinator
    @State private var phase: CGFloat = 0

    public init(coordinator: LoadingCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let barWidth = width * 0.35
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.uv.panelLo)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.uv.gold.opacity(0.0),
                                     Color.uv.gold,
                                     Color.uv.gold.opacity(0.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: barWidth)
                    .offset(x: (phase * (width + barWidth)) - barWidth)
            }
        }
        .frame(height: Layout.globalLoadingBarHeight)
        .opacity(coordinator.isLoading ? 1 : 0)
        .animation(.easeInOut(duration: 0.18), value: coordinator.isLoading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { startAnimation() }
        .onChange(of: coordinator.isLoading) { _, loading in
            if loading { startAnimation() }
        }
    }

    private func startAnimation() {
        phase = 0
        withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
            phase = 1
        }
    }
}

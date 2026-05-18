//
//  SplashView.swift
//  UginsVault
//
//  Centered logo + wordmark + thin gold shimmer. Auto-advances after 1.5 s.
//

import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var app
    @State private var didAppear = false

    var body: some View {
        ZStack {
            // Subtle lavender bloom
            RadialGradient(
                colors: [
                    Color.uv.lavender.opacity(0.18),
                    Color.uv.bg
                ],
                center: .init(x: 0.5, y: 0.55),
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                UginMark(size: 120)
                    .opacity(didAppear ? 1 : 0)
                    .scaleEffect(didAppear ? 1 : 0.92)

                VStack(spacing: 8) {
                    Text("Ugin's Vault")
                        .font(.uv.display(32, weight: .bold))
                        .tracking(-0.3)
                        .foregroundStyle(Color.uv.text)

                    Text("Private collection · v1.0")
                        .sectionLabel()
                }
                .opacity(didAppear ? 1 : 0)
            }
            .animation(.easeOut(duration: 0.6), value: didAppear)

            // Gold loading shimmer near the bottom
            VStack {
                Spacer()
                ShimmerBar()
                    .frame(width: 160, height: 2)
                    .padding(.bottom, 88)
                    .opacity(didAppear ? 1 : 0)
            }
        }
        .onAppear {
            didAppear = true
            Task {
                try? await Task.sleep(for: .milliseconds(1500))
                app.advanceFromSplash()
            }
        }
    }
}

// Self-contained shimmer used on splash + later for skeleton loaders.
private struct ShimmerBar: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Color.uv.stroke)
                Capsule()
                    .fill(LinearGradient(
                        colors: [.clear, Color.uv.gold, .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: w * 0.5)
                    .offset(x: phase * w)
            }
            .clipShape(Capsule())
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}

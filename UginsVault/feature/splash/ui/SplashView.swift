//
//  SplashView.swift
//  UginsVault — Presentation: Splash
//
//  Centered brand mark + wordmark + thin gold shimmer. Holds for ~1.5s
//  (configurable via SplashViewModel) then advances.
//

import SwiftUI

public struct SplashView: View {

    @StateObject private var viewModel: SplashViewModel

    public init(viewModel: SplashViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            backgroundBloom

            VStack(spacing: 28) {
                UginMark(size: 120)
                    .opacity(viewModel.didAppear ? 1 : 0)
                    .scaleEffect(viewModel.didAppear ? 1 : 0.92)

                VStack(spacing: 8) {
                    Text("Ugin's Vault")
                        .font(.uv.display(32, weight: .bold))
                        .tracking(-0.3)
                        .foregroundStyle(Color.uv.text)

                    Text("Private collection · v1.0")
                        .uvSectionLabel()
                }
                .opacity(viewModel.didAppear ? 1 : 0)
            }
            .animation(.easeOut(duration: 0.6), value: viewModel.didAppear)

            VStack {
                Spacer()
                ShimmerBar()
                    .frame(width: 160, height: 2)
                    .padding(.bottom, 88)
                    .opacity(viewModel.didAppear ? 1 : 0)
            }
        }
        .onAppear { viewModel.start() }
    }

    // MARK: - Subviews

    private var backgroundBloom: some View {
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
    }
}

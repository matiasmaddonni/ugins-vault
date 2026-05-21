//
//  PriceSyncView.swift
//  UginsVault — Presentation: PriceSync
//
//  Full-screen loading scene shown on first launch (and whenever the
//  user manually re-syncs from Settings). Mirrors the brand mark +
//  shimmer treatment of `SplashView` so the transition reads as one
//  uninterrupted boot.
//

import SwiftUI

public struct PriceSyncView: View {

    @State private var viewModel: PriceSyncViewModel
    private let onFinish: () -> Void

    public init(
        viewModel: PriceSyncViewModel,
        onFinish: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            Color.uv.bg.ignoresSafeArea()

            VStack(spacing: Spacing.lg + 2) {
                UginMark(size: Layout.splashMarkSize)

                VStack(spacing: Spacing.xs + 2) {
                    Text("Refreshing prices")
                        .font(.uv.display(20, weight: .semibold))
                        .foregroundStyle(Color.uv.text)

                    Text(viewModel.statusCopy)
                        .font(.uv.body(13))
                        .foregroundStyle(Color.uv.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                        .accessibilityIdentifier(PriceSyncAccessibilityFields.progressLabel)
                }

                ShimmerBar()
                    .frame(width: Layout.loginRingDiameter, height: Spacing.xs - 1)

                if viewModel.isFailed {
                    VStack(spacing: Spacing.sm) {
                        Button {
                            Task { await viewModel.sync() }
                        } label: {
                            Text("Try again")
                                .font(.uv.body(14, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x1A1410))
                                .padding(.horizontal, Spacing.lg + 2)
                                .padding(.vertical, Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: UVRadius.md).fill(Color.uv.gold)
                                )
                        }
                        .accessibilityIdentifier(PriceSyncAccessibilityFields.retryButton)

                        Button("Continue without prices") {
                            viewModel.skip()
                        }
                        .font(.uv.body(13, weight: .medium))
                        .foregroundStyle(Color.uv.muted)
                        .accessibilityIdentifier(PriceSyncAccessibilityFields.dismissButton)
                    }
                }
            }
        }
        .task {
            await viewModel.sync()
        }
        .onChange(of: viewModel.isFinished) { _, finished in
            if finished {
                Task {
                    try? await Task.sleep(for: .milliseconds(450))
                    onFinish()
                }
            }
        }
        .alert(
            "Wi-Fi required",
            isPresented: Bindable(viewModel).isWiFiAlertPresented
        ) {
            Button("OK") { viewModel.dismissWiFiAlert() }
        } message: {
            Text("Connect to Wi-Fi to download the pricing catalogue. Mobile data is disabled for this sync to keep your data plan safe.")
        }
        .accessibilityIdentifier(PriceSyncAccessibilityFields.screen)
    }
}

//
//  LoginView.swift
//  UginsVault — Presentation: Login
//
//  Minimal Face ID prompt. Big gold-ringed circular button + "Skip (dev)"
//  shortcut for the simulator and non-bio builds.
//

import SwiftUI

public struct LoginView: View {

    @State private var viewModel: LoginViewModel

    public init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 60)

            Spacer()

            faceIDButton

            Spacer()

            footer
                .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.uv.bg.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: viewModel.phase)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 18) {
            UginMark(size: 72)
            VStack(spacing: 6) {
                Text("Ugin's Vault")
                    .font(.uv.display(24, weight: .bold))
                    .tracking(-0.25)
                    .foregroundStyle(Color.uv.text)

                Text("Personal collection")
                    .uvSectionLabel()
            }
        }
    }

    private var faceIDButton: some View {
        Button {
            Task { await viewModel.authenticate() }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.uv.panel)
                    .frame(width: 144, height: 144)
                    .overlay(
                        Circle().strokeBorder(Color.uv.stroke, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 18, y: 10)

                ringOverlay
                glyph
                if viewModel.phase == .scanning { scanLine }
            }
            .frame(width: 144, height: 144)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.phase.isBusy)
        .accessibilityLabel("Unlock with Face ID")
    }

    private var ringOverlay: some View {
        Circle()
            .stroke(
                viewModel.phase == .success ? Color.uv.up : Color.uv.gold,
                style: StrokeStyle(
                    lineWidth: 1.5,
                    dash: viewModel.phase == .scanning ? [8, 12] : []
                )
            )
            .frame(width: 132, height: 132)
            .rotationEffect(.degrees(viewModel.phase == .scanning ? 360 : 0))
            .animation(
                viewModel.phase == .scanning
                    ? .linear(duration: 2.4).repeatForever(autoreverses: false)
                    : .default,
                value: viewModel.phase
            )
    }

    @ViewBuilder
    private var glyph: some View {
        Group {
            if viewModel.phase == .success {
                Image(systemName: "checkmark")
                    .resizable().scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(Color.uv.up)
            } else {
                Image(systemName: "faceid")
                    .resizable().scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundStyle(Color.uv.gold)
            }
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(response: 0.3), value: viewModel.phase)
    }

    private var scanLine: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [.clear, Color.uv.goldHi, .clear],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .frame(height: 2)
            .shadow(color: Color.uv.gold, radius: 8)
            .frame(width: 110)
            .offset(y: viewModel.phase == .scanning ? 50 : -50)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: viewModel.phase
            )
            .mask(Circle().frame(width: 110, height: 110))
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Text(helperText)
                .font(.uv.body(15, weight: .medium))
                .foregroundStyle(Color.uv.text)
                .transition(.opacity)

            Text("Face ID · or use PIN")
                .font(.uv.body(12))
                .foregroundStyle(Color.uv.muted)

            Button {
                viewModel.bypassAuthentication()
            } label: {
                Text("SKIP (DEV)")
                    .font(.uv.mono(11, weight: .medium))
                    .foregroundStyle(Color.uv.muted2)
                    .tracking(2.5)
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Helpers

    private var helperText: String {
        switch viewModel.phase {
        case .idle:                  "Tap to unlock the vault"
        case .scanning:              "Scanning…"
        case .success:               "Unlocked"
        case .failure(let reason):   reason
        }
    }
}

#Preview {
    LoginView(
        viewModel: DependencyContainer.shared.makeLoginViewModel(onAuthenticated: {})
    )
    .preferredColorScheme(.dark)
}

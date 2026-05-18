//
//  LoginView.swift
//  UginsVault
//
//  Minimal Face ID prompt. Big gold-ringed circular button.
//  Skip (dev) shortcut for the simulator + non-bio builds.
//

import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var app

    @State private var phase: AuthPhase = .idle
    @State private var errorMessage: String?

    enum AuthPhase {
        case idle
        case scanning
        case success
        case failure
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top brand block
            VStack(spacing: 18) {
                UginMark(size: 72)
                VStack(spacing: 6) {
                    Text("Ugin's Vault")
                        .font(.uv.display(24, weight: .bold))
                        .tracking(-0.25)
                        .foregroundStyle(Color.uv.text)
                    Text("Personal collection")
                        .sectionLabel()
                }
            }
            .padding(.top, 60)

            Spacer()

            // Face ID button
            faceIDButton

            Spacer()

            // Helper + skip
            VStack(spacing: 14) {
                Text(helperText)
                    .font(.uv.body(15, weight: .medium))
                    .foregroundStyle(Color.uv.text)
                    .transition(.opacity)

                Text("Face ID · or use PIN")
                    .font(.uv.body(12))
                    .foregroundStyle(Color.uv.muted)

                Button {
                    app.didAuthenticate()
                } label: {
                    Text("SKIP (DEV)")
                        .font(.uv.mono(11, weight: .medium))
                        .foregroundStyle(Color.uv.muted2)
                        .tracking(2.5)
                }
                .padding(.top, 12)
            }
            .padding(.bottom, 50)
            .animation(.easeInOut(duration: 0.2), value: phase)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.uv.bg.ignoresSafeArea())
    }

    // MARK: Subviews

    private var faceIDButton: some View {
        Button {
            Task { await runAuth() }
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
                if phase == .scanning { scanLine }
            }
            .frame(width: 144, height: 144)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(phase != .idle && phase != .failure)
        .accessibilityLabel("Unlock with Face ID")
    }

    private var ringOverlay: some View {
        Circle()
            .stroke(
                phase == .success ? Color.uv.up : Color.uv.gold,
                style: StrokeStyle(
                    lineWidth: 1.5,
                    dash: phase == .scanning ? [8, 12] : []
                )
            )
            .frame(width: 132, height: 132)
            .rotationEffect(.degrees(phase == .scanning ? 360 : 0))
            .animation(
                phase == .scanning
                    ? .linear(duration: 2.4).repeatForever(autoreverses: false)
                    : .default,
                value: phase
            )
    }

    @ViewBuilder
    private var glyph: some View {
        Group {
            if phase == .success {
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
        .animation(.spring(response: 0.3), value: phase)
    }

    private var scanLine: some View {
        // Horizontal sweep line clipped to the inner circle
        Rectangle()
            .fill(LinearGradient(
                colors: [.clear, Color.uv.goldHi, .clear],
                startPoint: .leading, endPoint: .trailing
            ))
            .frame(height: 2)
            .shadow(color: Color.uv.gold, radius: 8)
            .frame(width: 110)
            .offset(y: phase == .scanning ? 50 : -50)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: phase
            )
            .mask(Circle().frame(width: 110, height: 110))
    }

    // MARK: - Logic

    private var helperText: String {
        switch phase {
        case .idle: return "Tap to unlock the vault"
        case .scanning: return "Scanning…"
        case .success: return "Unlocked"
        case .failure: return errorMessage ?? "Try again"
        }
    }

    private func runAuth() async {
        phase = .scanning
        let result = await AuthService.authenticate(reason: "Unlock your vault")
        switch result {
        case .success:
            phase = .success
            try? await Task.sleep(for: .milliseconds(350))
            app.didAuthenticate()
        case .userCancelled:
            phase = .idle
        case .fallback:
            // TODO: present PIN flow
            phase = .idle
        case .unavailable:
            // Simulator with no enrolled biometry — go straight through in dev
            errorMessage = "Biometry unavailable"
            phase = .failure
        case .failed(let msg):
            errorMessage = msg
            phase = .failure
        }
    }
}

#Preview {
    LoginView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}

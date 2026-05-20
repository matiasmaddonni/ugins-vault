//
//  AccountLoginView.swift
//  UginsVault — Presentation: AccountLogin
//
//  Backend account sign-in (Supabase email/password). Shown on first launch or
//  whenever no session can be restored. On success the root router advances to
//  the local Face ID gate.
//

import SwiftUI

public struct AccountLoginView: View {

    @State private var viewModel: AccountLoginViewModel
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    public init(viewModel: AccountLoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: Spacing.xl) {
            Spacer()
            header
            form(viewModel: viewModel)
            Spacer()
        }
        .padding(.horizontal, Spacing.screenEdge)
        .padding(.vertical, Spacing.huge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.uv.bg.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: viewModel.phase)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccountLoginAccessibilityFields.screen)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.lg) {
            UginMark(size: Layout.accountLoginMarkSize)
            VStack(spacing: Spacing.xs) {
                Text("Ugin's Vault")
                    .font(.uv.display(24, weight: .bold))
                    .tracking(-0.25)
                    .foregroundStyle(Color.uv.text)
                    .accessibilityIdentifier(AccountLoginAccessibilityFields.title)

                Text("Sign in to your vault")
                    .uvSectionLabel()
                    .accessibilityIdentifier(AccountLoginAccessibilityFields.subtitle)
            }
        }
    }

    // MARK: - Form

    private func form(viewModel: AccountLoginViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            field(
                placeholder: "Email",
                text: $viewModel.email,
                identifier: AccountLoginAccessibilityFields.emailField,
                isSecure: false,
                focus: .email
            )
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .textContentType(.username)
            .autocorrectionDisabled()
            .submitLabel(.next)
            .onSubmit { focusedField = .password }

            field(
                placeholder: "Password",
                text: $viewModel.password,
                identifier: AccountLoginAccessibilityFields.passwordField,
                isSecure: true,
                focus: .password
            )
            .textContentType(.password)
            .submitLabel(.go)
            .onSubmit { Task { await viewModel.submit() } }

            if case .failure(let reason) = viewModel.phase {
                Text(reason)
                    .font(.uv.body(13))
                    .foregroundStyle(Color.uv.down)
                    .accessibilityIdentifier(AccountLoginAccessibilityFields.errorLabel)
            }

            signInButton(viewModel: viewModel)
                .padding(.top, Spacing.sm)
        }
    }

    @ViewBuilder
    private func field(
        placeholder: String,
        text: Binding<String>,
        identifier: String,
        isSecure: Bool,
        focus: Field
    ) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .font(.uv.body(16))
        .foregroundStyle(Color.uv.text)
        .focused($focusedField, equals: focus)
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.rowVertical)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: 1)
                )
        )
        .accessibilityIdentifier(identifier)
    }

    private func signInButton(viewModel: AccountLoginViewModel) -> some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            ZStack {
                if viewModel.phase.isBusy {
                    ProgressView()
                        .tint(Color.uv.bg)
                } else {
                    Text("Sign in")
                        .font(.uv.body(16, weight: .semibold))
                        .foregroundStyle(Color.uv.bg)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.primaryButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: UVRadius.md)
                    .fill(Color.uv.gold.opacity(viewModel.canSubmit ? 1 : 0.4))
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit)
        .accessibilityIdentifier(AccountLoginAccessibilityFields.signInButton)
    }

}

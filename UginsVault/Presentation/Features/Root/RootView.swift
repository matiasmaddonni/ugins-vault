//
//  RootView.swift
//  UginsVault — Presentation: Root
//
//  Phase router. Cross-fades between Splash / Login / Home and applies the
//  app-wide preferences (theme + language) from `SessionRepository`.
//

import SwiftUI

public struct RootView: View {

    @State private var viewModel: RootViewModel
    private let container: DependencyContainer

    public init(
        viewModel: RootViewModel,
        container: DependencyContainer = .shared
    ) {
        _viewModel = State(initialValue: viewModel)
        self.container = container
    }

    public var body: some View {
        ZStack {
            Color.uv.bg.ignoresSafeArea()

            switch viewModel.phase {
            case .splash:
                SplashView(
                    viewModel: container.makeSplashViewModel(
                        onAdvance: { viewModel.transition(to: $0) }
                    )
                )
                .transition(.opacity)

            case .accountLogin:
                AccountLoginView(
                    viewModel: container.makeAccountLoginViewModel(
                        onProceed: {
                            // Just authenticated with email/password — enter the
                            // app directly. Face ID is a cold-launch re-lock
                            // (see AdvanceFromSplashUseCase), not a second gate
                            // right after an explicit sign-in. Stays toggleable
                            // in Settings.
                            viewModel.transition(to: appEntryPhase())
                        }
                    )
                )
                .transition(.opacity)

            case .login:
                LoginView(
                    viewModel: container.makeLoginViewModel(
                        onAuthenticated: {
                            // First launch (no prior sync) routes through
                            // PriceSyncView. Returning users skip to home.
                            viewModel.transition(to: appEntryPhase())
                        }
                    )
                )
                .transition(.opacity)

            case .priceSync:
                PriceSyncView(
                    // First launch bootstraps the FULL price history so the
                    // Dashboard has real movers immediately; Settings'
                    // "Refresh prices" stays on the light daily path.
                    viewModel: container.makePriceSyncViewModel(fullHistory: true),
                    onFinish: { viewModel.transition(to: .home) }
                )
                .transition(.opacity)

            case .home:
                MainTabView(
                    container: container,
                    onRequireSignIn: { viewModel.transition(to: .accountLogin) }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.phase)
        .preferredColorScheme(container.sessionRepository.theme.colorScheme)
        .environment(\.locale, container.sessionRepository.language.locale ?? Locale.autoupdatingCurrent)
    }

    // MARK: - Helpers

    /// First launch (no prior sync) routes through PriceSync; returning users
    /// skip straight to home.
    private func appEntryPhase() -> AppPhase {
        container.priceRepository.lastSyncedAt == nil ? .priceSync : .home
    }
}

#Preview("Dark") {
    RootView(
        viewModel: DependencyContainer.shared.makeRootViewModel(),
        container: .shared
    )
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    RootView(
        viewModel: DependencyContainer.shared.makeRootViewModel(),
        container: .shared
    )
    .preferredColorScheme(.light)
}

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

            case .login:
                LoginView(
                    viewModel: container.makeLoginViewModel(
                        onAuthenticated: {
                            // First launch (no prior sync) routes through
                            // PriceSyncView. Returning users skip to home.
                            let next: AppPhase = container.priceRepository.lastSyncedAt == nil
                                ? .priceSync
                                : .home
                            viewModel.transition(to: next)
                        }
                    )
                )
                .transition(.opacity)

            case .priceSync:
                PriceSyncView(
                    viewModel: container.makePriceSyncViewModel(),
                    onFinish: { viewModel.transition(to: .home) }
                )
                .transition(.opacity)

            case .home:
                MainTabView(container: container)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.phase)
        .preferredColorScheme(container.sessionRepository.theme.colorScheme)
        .environment(\.locale, container.sessionRepository.language.locale ?? Locale.autoupdatingCurrent)
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

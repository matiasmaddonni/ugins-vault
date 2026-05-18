//
//  RootView.swift
//  UginsVault — Presentation: Root
//
//  Phase router. Cross-fades between Splash / Login / Home and pipes phase
//  transitions from children back into `RootViewModel`.
//

import SwiftUI

public struct RootView: View {

    @StateObject private var viewModel: RootViewModel
    private let container: DependencyContainer

    public init(
        viewModel: RootViewModel,
        container: DependencyContainer = .shared
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                        onAuthenticated: { viewModel.transition(to: .home) }
                    )
                )
                .transition(.opacity)

            case .home:
                HomeView(
                    viewModel: container.makeHomeViewModel()
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.phase)
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

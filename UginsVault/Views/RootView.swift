//
//  RootView.swift
//  UginsVault
//
//  Phase router. Cross-fades between Splash / Login / Home.
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ZStack {
            // Stable background under cross-fades
            Color.uv.bg.ignoresSafeArea()

            switch app.phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .login:
                LoginView()
                    .transition(.opacity)
            case .home:
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: app.phase)
    }
}

#Preview("Dark") {
    RootView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    RootView()
        .environment(AppState())
        .preferredColorScheme(.light)
}

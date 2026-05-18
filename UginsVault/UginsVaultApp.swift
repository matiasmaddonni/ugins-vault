//
//  UginsVaultApp.swift
//  UginsVault
//
//  App entry. Owns a single AppState; mounts the RootView phase router.
//

import SwiftUI

@main
struct UginsVaultApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(appState.theme.colorScheme)
        }
    }
}

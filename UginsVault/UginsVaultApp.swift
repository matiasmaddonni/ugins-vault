//
//  UginsVaultApp.swift
//  UginsVault
//
//  App entry. Builds the dependency graph at launch and mounts `RootView`.
//

import SwiftUI

@main
struct UginsVaultApp: App {

    private let container = DependencyContainer.shared

    var body: some Scene {
        WindowGroup {
            RootView(
                viewModel: container.makeRootViewModel(),
                container: container
            )
        }
    }
}

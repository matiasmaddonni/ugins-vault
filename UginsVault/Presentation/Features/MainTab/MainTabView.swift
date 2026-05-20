//
//  MainTabView.swift
//  UginsVault — Presentation: Main
//
//  Root tab container shown once the user is past Splash + Login. Uses the
//  native iOS 26 `Tab` builder syntax so Liquid Glass styling is applied
//  automatically.
//

import SwiftUI

public struct MainTabView: View {

    private enum TabSelection: Hashable {
        case collection
        case stacks
        case dashboard
        case settings
    }

    @State private var selectedTab: TabSelection = .collection
    private let container: DependencyContainer
    private let onRequireSignIn: () -> Void

    public init(
        container: DependencyContainer = .shared,
        onRequireSignIn: @escaping () -> Void = {}
    ) {
        self.container = container
        self.onRequireSignIn = onRequireSignIn
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Collection", systemImage: "rectangle.portrait.fill", value: .collection) {
                CollectionView(viewModel: container.makeCollectionViewModel())
                    .accessibilityIdentifier(MainTabAccessibilityFields.collectionTab)
            }

            Tab("Stacks", systemImage: "square.stack.fill", value: .stacks) {
                StacksView(viewModel: container.makeStacksListViewModel())
                    .accessibilityIdentifier(MainTabAccessibilityFields.stacksTab)
            }

            Tab("Dashboard", systemImage: "chart.bar.fill", value: .dashboard) {
                DashboardView(viewModel: container.makeDashboardViewModel(onRequireSignIn: onRequireSignIn))
                    .accessibilityIdentifier(MainTabAccessibilityFields.dashboardTab)
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                SettingsView(viewModel: container.makeSettingsViewModel(onSignedOut: onRequireSignIn))
                    .accessibilityIdentifier(MainTabAccessibilityFields.settingsTab)
            }
        }
        .tint(Color.uv.gold)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(MainTabAccessibilityFields.tabBar)
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}

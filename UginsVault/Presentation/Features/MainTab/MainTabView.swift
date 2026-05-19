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

    public init(container: DependencyContainer = .shared) {
        self.container = container
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Collection", systemImage: "rectangle.portrait.fill", value: .collection) {
                CollectionView(viewModel: container.makeCollectionViewModel())
            }

            Tab("Stacks", systemImage: "square.stack.fill", value: .stacks) {
                StacksView()
            }

            Tab("Dashboard", systemImage: "chart.bar.fill", value: .dashboard) {
                DashboardView()
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                SettingsView(viewModel: container.makeSettingsViewModel())
            }
        }
        .tint(Color.uv.gold)
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}

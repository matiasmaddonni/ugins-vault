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

    private enum BootstrapPhase { case loading, ready }

    @State private var selectedTab: TabSelection = .collection
    @State private var bootstrap: BootstrapPhase = .loading
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
        Group {
            switch bootstrap {
            case .loading: bootstrapLoading
            case .ready:   tabs
            }
        }
        .task { await runBootstrap() }
    }

    private var tabs: some View {
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

    private var bootstrapLoading: some View {
        ZStack {
            Color.uv.bg.ignoresSafeArea()
            ProgressView()
                .tint(Color.uv.gold)
        }
    }

    /// Restores the collection from the backend (the source of truth) before
    /// the tabs read the local cache. A fresh install (empty cache) blocks on
    /// the restore so cards land in their stacks immediately; a returning user
    /// sees the cached UI right away while the restore refreshes it behind the
    /// scenes. Best-effort: offline / signed-out simply keeps the local cache.
    @MainActor
    private func runBootstrap() async {
        guard bootstrap == .loading else { return }
        let localEmpty = ((try? await container.collectionItemRepository.allItems()) ?? []).isEmpty
        let restore = container.makeRestoreCollectionUseCase()
        if localEmpty {
            try? await restore.execute()
            bootstrap = .ready
        } else {
            bootstrap = .ready
            try? await restore.execute()
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}

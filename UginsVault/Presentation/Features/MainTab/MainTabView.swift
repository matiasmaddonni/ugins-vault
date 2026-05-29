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
        .overlay(alignment: .bottom) { importPill }
        .overlay(alignment: .top) {
            GlobalLoadingBar(coordinator: container.loadingCoordinator)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: container.importCoordinator.phase)
        .task { await runBootstrap() }
    }

    @ViewBuilder
    private var importPill: some View {
        if container.importCoordinator.phase != .idle {
            ImportProgressPill(
                coordinator: container.importCoordinator,
                onTap: { selectedTab = .stacks }
            )
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Layout.importPillBottomInset)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
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

    /// Shows the tabs immediately, then refreshes the local cache from the
    /// backend (the source of truth) in the background. NEVER gate the whole
    /// app on the restore — a fresh install with a large collection would
    /// otherwise freeze on launch while the cache fills. The tabs read whatever
    /// is cached and update reactively as the restore lands. Best-effort:
    /// offline / signed-out simply keeps the local cache.
    @MainActor
    private func runBootstrap() async {
        guard bootstrap == .loading else { return }
        bootstrap = .ready
        // Tabs are on screen — pre-warm the iOS keyboard subsystem so the
        // first `.searchable` tap (Collection / commander picker / …)
        // doesn't sit through the 1–2 s cold-init pause on the main thread.
        KeyboardWarmup.prepare()
        _ = try? await container.loadingCoordinator.track("Restore.execute") {
            try await container.makeRestoreCollectionUseCase().execute()
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}

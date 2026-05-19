//
//  DashboardView.swift
//  UginsVault — Presentation: Dashboard
//
//  Replaces the placeholder Dashboard tab with the real screen.
//  Sections in order: nav header → hero row → movers row → format
//  donut → set bars → wishlist teaser → quick stats.
//

import SwiftUI

public struct DashboardView: View {

    @State private var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            content
                .background(Color.uv.bg.ignoresSafeArea())
                .navigationTitle("Dashboard")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { toolbar }
                .task {
                    viewModel.refreshCurrencyIfNeeded()
                    await viewModel.onAppear()
                }
                .refreshable { await viewModel.refresh() }
        }
        .accessibilityIdentifier(DashboardAccessibilityFields.screen)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                // TODO: range picker (out of scope per brief §20).
            } label: {
                Image(systemName: "globe")
                    .font(.system(size: Layout.mediumIcon - 1, weight: .semibold))
                    .foregroundStyle(Color.uv.muted.opacity(0.6))
            }
            .disabled(true)
            .accessibilityIdentifier(DashboardAccessibilityFields.rangeToolbar)
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .loading where viewModel.snapshot == nil:
            ScrollView { DashboardSkeletonView() }

        case .error(let message) where viewModel.snapshot == nil:
            errorPanel(message: message)

        default:
            if let snapshot = viewModel.snapshot {
                loadedScroll(snapshot: snapshot)
            } else {
                ScrollView { DashboardSkeletonView() }
            }
        }
    }

    // MARK: - Loaded

    private func loadedScroll(snapshot: DashboardSnapshot) -> some View {
        ScrollView {
            VStack(spacing: Layout.dashboardSectionSpacing) {
                heroRow(snapshot: snapshot)
                moversRow(snapshot: snapshot)
                ByFormatPanel(slices: snapshot.byFormat, currency: viewModel.currency)
                BySetPanel(bars: snapshot.bySet, currency: viewModel.currency)
                WishlistTeaser(
                    trackedCount: snapshot.wishlistTrackedCount,
                    readyToBuyCount: snapshot.wishlistReadyToBuyCount
                )
                QuickStatsRow(stats: snapshot.stats, currency: viewModel.currency)
            }
            .padding(.horizontal, Layout.dashboardSidePadding)
            .padding(.vertical, Spacing.md)
        }
    }

    private func heroRow(snapshot: DashboardSnapshot) -> some View {
        GeometryReader { proxy in
            let leftW = proxy.size.width * (1.4 / 2.4)
            HStack(spacing: Spacing.sm) {
                TotalValueTile(
                    totalValueUSD: snapshot.totalValueUSD,
                    weekDeltaUSD: snapshot.weekDeltaUSD,
                    weekDeltaPct: snapshot.weekDeltaPct,
                    monthSparkline: snapshot.monthSparkline,
                    currency: viewModel.currency
                )
                .frame(width: leftW)

                WeekMoversTile(gainers: snapshot.gainers, losers: snapshot.losers)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: Layout.dashboardHeroHeight)
    }

    private func moversRow(snapshot: DashboardSnapshot) -> some View {
        HStack(spacing: Spacing.sm) {
            MoversCard(title: "Gainers", tone: .up, items: snapshot.gainers)
            MoversCard(title: "Losers",  tone: .down, items: snapshot.losers)
        }
        .frame(height: Layout.dashboardMoversCardHeight)
    }

    // MARK: - Error panel

    private func errorPanel(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: Layout.heroIcon, weight: .medium))
                .foregroundStyle(Color.uv.down)
            VStack(spacing: Spacing.xs) {
                Text("Couldn't load dashboard")
                    .font(.uv.display(16, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                Text(message)
                    .font(.uv.body(12))
                    .foregroundStyle(Color.uv.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            Button {
                Task { await viewModel.load() }
            } label: {
                Text("Try again")
                    .font(.uv.body(14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x1A1410))
                    .padding(.horizontal, Spacing.lg + 2)
                    .padding(.vertical, Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: UVRadius.md).fill(Color.uv.gold)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Spacing.xl)
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel(
        repository: MockDashboardRepository(),
        sessionRepository: DependencyContainer.shared.sessionRepository
    ))
    .preferredColorScheme(.dark)
}

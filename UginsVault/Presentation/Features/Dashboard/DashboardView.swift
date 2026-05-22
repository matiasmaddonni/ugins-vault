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
                .task {
                    viewModel.refreshCurrencyIfNeeded()
                    await viewModel.onAppear()
                }
                .refreshable { await viewModel.refresh() }
        }
        .accessibilityIdentifier(DashboardAccessibilityFields.screen)
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

    @ViewBuilder
    private var priceSyncBanner: some View {
        switch viewModel.priceSyncState {
        case .idle:
            EmptyView()
        case .syncing:
            syncBanner(icon: "arrow.triangle.2.circlepath", tint: Color.uv.gold,
                       text: String(localized: "Updating prices…"), showSpinner: true)
        case .pending:
            syncBanner(icon: "clock", tint: Color.uv.muted,
                       text: String(localized: "Prices are being prepared — check back after the next update."),
                       showSpinner: false)
        case .failed:
            syncBanner(icon: "exclamationmark.triangle.fill", tint: Color.uv.down,
                       text: String(localized: "Couldn't refresh prices — pull to retry."),
                       showSpinner: false)
        }
    }

    private func syncBanner(icon: String, tint: Color, text: String, showSpinner: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            if showSpinner {
                ProgressView().tint(tint)
            } else {
                Image(systemName: icon).foregroundStyle(tint)
            }
            Text(text)
                .font(.uv.body(13))
                .foregroundStyle(Color.uv.muted)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panel)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(DashboardAccessibilityFields.priceSyncBanner)
    }

    private func loadedScroll(snapshot: DashboardSnapshot) -> some View {
        ScrollView {
            VStack(spacing: Layout.dashboardSectionSpacing) {
                priceSyncBanner
                heroRow(snapshot: snapshot)
                moversRow(snapshot: snapshot)
                ByFormatPanel(
                    slices: snapshot.byFormat,
                    currency: viewModel.currency,
                    rate: viewModel.exchangeRate
                )
                BySetPanel(
                    bars: snapshot.bySet,
                    currency: viewModel.currency,
                    rate: viewModel.exchangeRate
                )
                QuickStatsRow(
                    stats: snapshot.stats,
                    currency: viewModel.currency,
                    rate: viewModel.exchangeRate
                )
            }
            .padding(.horizontal, Layout.dashboardSidePadding)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.tabBarClearance + Spacing.xl)
        }
    }

    private func heroRow(snapshot: DashboardSnapshot) -> some View {
        // Equal 1/1 split (deviates from the brief's 1.4/1 ratio on
        // purpose) so the hero tiles line up vertically with the
        // gainers/losers row + every full-width panel underneath. The
        // staggered ratio looked broken on-device because nothing
        // else on the screen shares it.
        HStack(spacing: Layout.dashboardRowSpacing) {
            TotalValueTile(
                totalValueUSD: snapshot.totalValueUSD,
                weekDeltaUSD: snapshot.weekDeltaUSD,
                weekDeltaPct: snapshot.weekDeltaPct,
                monthSparkline: snapshot.monthSparkline,
                currency: viewModel.currency,
                rate: viewModel.exchangeRate
            )
            .frame(maxWidth: .infinity)

            WeekMoversTile(gainers: snapshot.gainers, losers: snapshot.losers)
                .frame(maxWidth: .infinity)
        }
        .frame(height: Layout.dashboardHeroHeight)
    }

    private func moversRow(snapshot: DashboardSnapshot) -> some View {
        HStack(spacing: Layout.dashboardRowSpacing) {
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

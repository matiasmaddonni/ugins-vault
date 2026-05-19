//
//  StackDetailView.swift
//  UginsVault — Presentation: Stacks
//
//  Per-stack detail screen. Hero card on top, kind-aware action bar
//  below, then either the stack's `CollectionItem` rows or an empty
//  state with an "Add cards" CTA.
//
//  v0.3 leaves all action-bar buttons + row navigation as stubs; the
//  screen still renders the full visual stack and refreshes via
//  pull-down.
//

import SwiftUI

public struct StackDetailView: View {

    @State private var viewModel: StackDetailViewModel

    public init(viewModel: StackDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        content
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle(viewModel.stack.name)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.onAppear() }
            .accessibilityIdentifier(StackDetailAccessibilityFields.screen)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .error(let message):
            errorPanel(message: message)

        case .loading where viewModel.items.isEmpty && viewModel.cardCount == 0:
            loadingPanel

        case .idle, .loading:
            mainScroll
        }
    }

    // MARK: - Main scroll

    private var mainScroll: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                StackHeroCard(
                    stack: viewModel.stack,
                    cardCount: viewModel.cardCount,
                    uniqueCount: viewModel.uniqueCount,
                    formattedValue: viewModel.formattedTotalValue,
                    subtitle: viewModel.heroSubtitle
                )
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(StackDetailAccessibilityFields.heroName)

                StackActionBar(
                    actions: viewModel.actions,
                    onAction: { _ in
                        // v0.3 — every action is a stub (per scope).
                    }
                )
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(StackDetailAccessibilityFields.actionBar)

                cardListSection
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.vertical, Spacing.md)
        }
        .refreshable { await viewModel.refresh() }
    }

    // MARK: - Card list / empty

    @ViewBuilder
    private var cardListSection: some View {
        if viewModel.isEmpty {
            emptyPanel
        } else {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Cards")
                    .uvSectionLabel()

                VStack(spacing: 0) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        itemRow(item: item, index: index)
                        if index < viewModel.items.count - 1 {
                            Rectangle()
                                .fill(Color.uv.stroke.opacity(0.4))
                                .frame(height: Layout.hairline)
                                .padding(.leading, Spacing.lg)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .fill(Color.uv.panel)
                        .overlay(
                            RoundedRectangle(cornerRadius: UVRadius.md)
                                .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                        )
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(StackDetailAccessibilityFields.cardList)
        }
    }

    private func itemRow(item: CollectionItem, index: Int) -> some View {
        HStack(spacing: Spacing.md) {
            // Compact stand-in for the card row — v0.3 doesn't join
            // `CollectionItem` against `Card.name`. A later milestone
            // surfaces the printing's image + name here.
            VStack(alignment: .leading, spacing: Spacing.xs - 2) {
                Text(item.cardID.uuidString.prefix(8))
                    .font(.uv.mono(12, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                Text("\(item.finish.displayName) · \(item.condition.rawValue) · \(item.language.uppercased())")
                    .font(.uv.body(11))
                    .foregroundStyle(Color.uv.muted)
            }

            Spacer(minLength: Spacing.sm)

            Text("×\(item.quantity)")
                .font(.uv.mono(13, weight: .semibold))
                .foregroundStyle(Color.uv.gold)
        }
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.md)
        .accessibilityIdentifier(StackDetailAccessibilityFields.row(at: index))
    }

    // MARK: - Empty / loading / error panels

    private var emptyPanel: some View {
        VStack(spacing: Spacing.md + 2) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: Layout.heroIcon, weight: .medium))
                .foregroundStyle(Color.uv.muted)

            VStack(spacing: Spacing.xs + 2) {
                Text("No cards in this stack")
                    .font(.uv.display(16, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .accessibilityIdentifier(StackDetailAccessibilityFields.emptyTitle)

                Text("Add cards from your collection to start tracking value here.")
                    .font(.uv.body(12))
                    .foregroundStyle(Color.uv.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Button {
                // TODO: open Add-to-stack sheet (Phase 4 wiring).
            } label: {
                Text("Add cards")
                    .font(.uv.body(14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x1A1410))
                    .padding(.horizontal, Spacing.lg + 2)
                    .padding(.vertical, Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: UVRadius.md).fill(Color.uv.gold)
                    )
            }
            .accessibilityIdentifier(StackDetailAccessibilityFields.emptyAddButton)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge - Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.lg)
                .fill(Color.uv.panel.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.lg)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
        )
    }

    private var loadingPanel: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .tint(Color.uv.gold)
            Text("Loading…")
                .font(.uv.body(13))
                .foregroundStyle(Color.uv.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorPanel(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: Layout.heroIcon, weight: .medium))
                .foregroundStyle(Color.uv.down)

            VStack(spacing: Spacing.xs) {
                Text("Couldn't load this stack")
                    .font(.uv.display(16, weight: .semibold))
                    .foregroundStyle(Color.uv.text)

                Text(message)
                    .font(.uv.body(12))
                    .foregroundStyle(Color.uv.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Text("Retry")
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

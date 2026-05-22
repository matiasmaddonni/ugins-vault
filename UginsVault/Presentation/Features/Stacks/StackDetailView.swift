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
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: StackDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        content
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle(viewModel.stack.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .task { await viewModel.onAppear() }
            .navigationDestination(for: Card.self) { card in
                CardDetailView(
                    viewModel: DependencyContainer.shared.makeCardDetailViewModel(
                        card: card,
                        displayCurrency: viewModel.currency
                    )
                )
            }
            .sheet(isPresented: $viewModel.isPresentingImport) {
                ImportDeckListSheet(
                    initialText: viewModel.serializedCardList,
                    onImport: { source in viewModel.startImport(source: source) }
                )
            }
            .sheet(isPresented: $viewModel.isPresentingCommanderPicker) {
                CommanderPickerSheet(
                    items: viewModel.pickerCandidates,
                    cardsByID: viewModel.cardsByID,
                    currentCommanderCardID: viewModel.stack.commanderCardID,
                    onPick: { id in await viewModel.setCommander(cardID: id) },
                    onClear: { await viewModel.clearCommander() }
                )
            }
            .confirmationDialog(
                "Delete \(viewModel.stack.name)?",
                isPresented: $viewModel.isPresentingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete stack", role: .destructive) {
                    Task {
                        await viewModel.deleteStack()
                        if viewModel.didDelete { dismiss() }
                    }
                }
                Button("Cancel", role: .cancel) { viewModel.dismissDeleteConfirm() }
            } message: {
                Text("Removes \"\(viewModel.stack.name)\" and every card stored in it. This can't be undone.")
            }
            .accessibilityIdentifier(StackDetailAccessibilityFields.screen)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.presentImport()
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: Layout.mediumIcon - 1, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
            }
            .accessibilityLabel("Import list")
            .accessibilityIdentifier(StackDetailAccessibilityFields.importToolbar)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if viewModel.stack.kind == .deck, viewModel.stack.format == .commander {
                    Button {
                        viewModel.presentCommanderPicker()
                    } label: {
                        Label(
                            viewModel.stack.commanderCardID == nil
                                ? "Pick commander"
                                : "Change commander",
                            systemImage: "crown.fill"
                        )
                    }
                    .disabled(viewModel.items.isEmpty)
                }
                Button(role: .destructive) {
                    viewModel.presentDeleteConfirm()
                } label: {
                    Label("Delete stack", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: Layout.mediumIcon - 1, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
            }
            .accessibilityIdentifier(StackDetailAccessibilityFields.deleteToolbar)
        }
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

    @State private var isPresentingShare: Bool = false

    private var mainScroll: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                StackHeroCard(
                    stack: viewModel.stack,
                    cardCount: viewModel.cardCount,
                    formattedValue: viewModel.formattedTotalValue,
                    subtitle: viewModel.heroSubtitle,
                    commanderArtURL: viewModel.commanderArtURL
                )
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(StackDetailAccessibilityFields.heroName)

                StackActionBar(
                    actions: viewModel.actions,
                    onAction: { action in
                        switch action.id {
                        case "edit_list", "add_cards", "sort_all":
                            viewModel.presentImport()
                        case "export":
                            isPresentingShare = true
                        default:
                            // Other actions remain stubs in v0.3.
                            break
                        }
                    }
                )
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(StackDetailAccessibilityFields.actionBar)

                if let validation = viewModel.commanderValidation {
                    commanderValidationBanner(validation)
                }

                cardListSection
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.vertical, Spacing.md)
        }
        .refreshable { await viewModel.refresh() }
        .sheet(isPresented: $isPresentingShare) {
            ShareSheet(text: viewModel.serializedCardList)
        }
    }

    private func commanderValidationBanner(_ message: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.uv.gold)
            Text(message)
                .font(.uv.body(12))
                .foregroundStyle(Color.uv.text)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.gold.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.gold.opacity(0.35), lineWidth: 1)
                )
        )
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

    @ViewBuilder
    private func itemRow(item: CollectionItem, index: Int) -> some View {
        if let card = viewModel.card(for: item) {
            NavigationLink(value: card) {
                itemRowBody(item: item, card: card, index: index)
            }
            .buttonStyle(.plain)
            .contextMenu {
                if viewModel.stack.kind == .deck {
                    Button {
                        Task { await viewModel.setCommander(cardID: card.id) }
                    } label: {
                        Label(
                            viewModel.stack.commanderCardID == card.id ? "Commander" : "Set as commander",
                            systemImage: "crown.fill"
                        )
                    }
                    .disabled(viewModel.stack.commanderCardID == card.id)
                }
            }
        } else {
            itemRowBody(item: item, card: nil, index: index)
        }
    }

    private func itemRowBody(item: CollectionItem, card: Card?, index: Int) -> some View {
        HStack(spacing: Spacing.md) {
            CollectionItemThumbnail(card: card)

            VStack(alignment: .leading, spacing: Spacing.xs - 2) {
                Text(card?.name ?? String(item.cardID.uuidString.prefix(8)))
                    .font(.uv.body(14, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)

                if let card {
                    Text("\(card.setCode.uppercased()) · #\(card.collectorNumber)")
                        .font(.uv.mono(11))
                        .foregroundStyle(Color.uv.muted)
                        .lineLimit(1)
                }

                Text("\(item.finish.displayName) · \(item.condition.rawValue) · \(item.language.uppercased())")
                    .font(.uv.body(11))
                    .foregroundStyle(Color.uv.muted2)
                    .lineLimit(1)
            }

            Spacer(minLength: Spacing.sm)

            Text("×\(item.quantity)")
                .font(.uv.mono(13, weight: .semibold))
                .foregroundStyle(Color.uv.gold)

            Image(systemName: "chevron.right")
                .font(.system(size: Layout.smallIcon - 4, weight: .semibold))
                .foregroundStyle(Color.uv.muted2)
        }
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
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
                viewModel.presentImport()
            } label: {
                Text("Import list")
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

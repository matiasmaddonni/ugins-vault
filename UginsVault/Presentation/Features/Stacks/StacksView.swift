//
//  StacksView.swift
//  UginsVault — Presentation: Stacks
//
//  The Stacks tab. Lists every pile the user owns (decks, binders, loans,
//  sales, showcase, unsorted) with a kind filter, a cross-stack summary
//  line, and a "+" toolbar action for creating a new stack.
//
//  Empty state mirrors the Collection tab's tone: brand mark + copy +
//  call-to-action.
//

import SwiftUI

public struct StacksView: View {

    @State private var viewModel: StacksListViewModel
    @State private var pendingDelete: Stack?

    public init(viewModel: StacksListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            content
                .background(Color.uv.bg.ignoresSafeArea())
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .task { await viewModel.onAppear() }
                .navigationDestination(for: Stack.self) { stack in
                    StackDetailView(
                        viewModel: DependencyContainer.shared.makeStackDetailViewModel(stack: stack)
                    )
                }
                .sheet(isPresented: $viewModel.isPresentingCreate) {
                    CreateStackSheet { name, kind, format, colors, commander, person in
                        await viewModel.createStack(
                            name: name,
                            kind: kind,
                            format: format,
                            colors: colors,
                            commander: commander,
                            person: person
                        )
                    }
                }
                .confirmationDialog(
                    deleteConfirmationTitle,
                    isPresented: deleteDialogBinding,
                    titleVisibility: .visible,
                    presenting: pendingDelete
                ) { stack in
                    Button("Delete stack", role: .destructive) {
                        Task { await viewModel.deleteStack(id: stack.id) }
                        pendingDelete = nil
                    }
                    Button("Cancel", role: .cancel) {
                        pendingDelete = nil
                    }
                } message: { stack in
                    Text("Removes \"\(stack.name)\" and every card stored in it. This can't be undone.")
                }
        }
        .accessibilityIdentifier(StacksAccessibilityFields.screen)
    }

    private var deleteConfirmationTitle: String {
        guard let pendingDelete else { return "" }
        return "Delete \(pendingDelete.name)?"
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { isPresented in
                if !isPresented { pendingDelete = nil }
            }
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.presentCreate()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: Layout.mediumIcon - 1, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
            }
            .accessibilityLabel("Add stack")
            .accessibilityIdentifier(StacksAccessibilityFields.addStackToolbar)
        }
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .error(let message):
            errorPanel(message: message)

        case .loading where viewModel.allStacks.isEmpty:
            loadingPanel

        case .idle, .loading:
            if viewModel.isEmpty {
                emptyState
            } else {
                stackList
            }
        }
    }

    // MARK: - Header (always rendered above the list / empty state)

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Stacks")
                .font(.uv.display(30, weight: .bold))
                .tracking(-0.3)
                .foregroundStyle(Color.uv.text)
                .accessibilityIdentifier(StacksAccessibilityFields.title)

            HStack(spacing: Spacing.sm) {
                Text("\(viewModel.totalStackCount) stacks")
                    .font(.uv.mono(12))
                    .foregroundStyle(Color.uv.muted)
                    .accessibilityIdentifier(StacksAccessibilityFields.stackCountValue)

                separatorDot

                Text("\(viewModel.totalCardCount) cards")
                    .font(.uv.mono(12))
                    .foregroundStyle(Color.uv.muted)
                    .accessibilityIdentifier(StacksAccessibilityFields.cardCountValue)

                separatorDot

                Text(viewModel.formattedTotalValue)
                    .font(.uv.mono(12, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
                    .accessibilityIdentifier(StacksAccessibilityFields.totalValueLabel)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(StacksAccessibilityFields.summaryLine)
        }
    }

    private var separatorDot: some View {
        Circle()
            .fill(Color.uv.muted.opacity(0.5))
            .frame(width: 3, height: 3)
    }

    // MARK: - Filter chips

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.availableFilters) { filter in
                    UVChip(
                        title: filter.chipLabel,
                        icon: filter.iconName,
                        isSelected: viewModel.filter == filter,
                        action: { viewModel.applyFilter(filter) }
                    )
                    .accessibilityIdentifier(chipID(for: filter))
                }
            }
            .padding(.horizontal, Spacing.screenEdge)
        }
        .scrollClipDisabled()
    }

    private func chipID(for filter: StacksListViewModel.Filter) -> String {
        switch filter {
        case .all:
            return StacksAccessibilityFields.filterAll
        case .kind(let kind):
            return StacksAccessibilityFields.filterChip(for: kind.rawValue)
        }
    }

    // MARK: - List

    private var stackList: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                    .padding(.horizontal, Spacing.screenEdge)
                filterStrip
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)

            if viewModel.visibleStacks.isEmpty {
                ScrollView {
                    filteredEmptyPanel
                        .padding(.horizontal, Spacing.screenEdge)
                        .padding(.vertical, Spacing.xl)
                }
                .refreshable { await viewModel.refresh() }
            } else {
                rowList
            }
        }
    }

    private var rowList: some View {
        List {
            ForEach(Array(viewModel.visibleStacks.enumerated()), id: \.element.id) { index, stack in
                NavigationLink(value: stack) {
                    StackRow(
                        stack: stack,
                        cardCount: viewModel.cardCount(for: stack),
                        displayValue: viewModel.displayValue(for: stack),
                        previewCards: viewModel.previewCards(for: stack),
                        index: index
                    )
                }
                .listRowBackground(Color.uv.bg)
                .listRowSeparatorTint(Color.uv.stroke.opacity(0.4))
                .listRowInsets(EdgeInsets(
                    top: Spacing.xs,
                    leading: Spacing.screenEdge,
                    bottom: Spacing.xs,
                    trailing: Spacing.screenEdge
                ))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        pendingDelete = stack
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(Color.uv.down)
                    .accessibilityIdentifier(StacksAccessibilityFields.rowDelete(at: index))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.uv.bg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(StacksAccessibilityFields.list)
        .refreshable { await viewModel.refresh() }
    }

    // MARK: - Empty states

    private var emptyState: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.lg)

            Spacer(minLength: Spacing.xl)

            VStack(spacing: Spacing.md + 2) {
                UginMark(size: Layout.emptyStateMarkSize)
                    .opacity(0.55)

                VStack(spacing: Spacing.xs + 2) {
                    Text("No stacks yet")
                        .font(.uv.display(18, weight: .semibold))
                        .foregroundStyle(Color.uv.text)
                        .accessibilityIdentifier(StacksAccessibilityFields.emptyStateTitle)

                    Text("Build your first deck, binder or loan to start tracking value across piles.")
                        .font(.uv.body(13))
                        .foregroundStyle(Color.uv.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                Button {
                    viewModel.presentCreate()
                } label: {
                    Text("New stack")
                        .font(.uv.body(14, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x1A1410))
                        .padding(.horizontal, Spacing.lg + 2)
                        .padding(.vertical, Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: UVRadius.md).fill(Color.uv.gold)
                        )
                }
                .accessibilityIdentifier(StacksAccessibilityFields.emptyAddButton)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
    }

    private var filteredEmptyPanel: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: Layout.heroIcon, weight: .medium))
                .foregroundStyle(Color.uv.muted)

            VStack(spacing: Spacing.xs) {
                Text("Nothing here yet")
                    .font(.uv.display(16, weight: .semibold))
                    .foregroundStyle(Color.uv.text)

                Text("No stacks match this filter.")
                    .font(.uv.body(12))
                    .foregroundStyle(Color.uv.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.lg)
                .fill(Color.uv.panel.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.lg)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
        )
    }

    // MARK: - Loading / error panels

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
                Text("Couldn't load your stacks")
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

#Preview {
    StacksView(
        viewModel: StacksListViewModel(
            stackRepository: DependencyContainer.shared.stackRepository,
            itemRepository: DependencyContainer.shared.collectionItemRepository,
            sessionRepository: DependencyContainer.shared.sessionRepository
        )
    )
    .preferredColorScheme(.dark)
}

//
//  CollectionView.swift
//  UginsVault — Presentation: Collection
//
//  The Collection tab. Header (title + count + total value), search,
//  card list with sort + filter + pagination.
//

import SwiftUI

public struct CollectionView: View {

    @State private var viewModel: CollectionViewModel
    @State private var isPresentingFilter: Bool = false
    @State private var isPresentingAddCard: Bool = false
    @State private var isPresentingWishlist: Bool = false

    public init(viewModel: CollectionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            content
                .background(Color.uv.bg.ignoresSafeArea())
                .navigationTitle("Collection")
                .navigationBarTitleDisplayMode(.large)
                .navigationSubtitle(collectionSubtitle)
                .toolbar { toolbar }
                .searchable(text: bindingForQuery, prompt: Text("Search collection…"))
                .task { await viewModel.onAppear() }
                .onDisappear { viewModel.stopPriceStatusPolling() }
                .navigationDestination(for: Card.self) { card in
                    CardDetailView(
                        viewModel: DependencyContainer.shared.makeCardDetailViewModel(
                            card: card,
                            displayCurrency: viewModel.currency
                        )
                    )
                }
                .navigationDestination(isPresented: $isPresentingWishlist) {
                    WishlistView(viewModel: DependencyContainer.shared.makeWishlistViewModel())
                }
                .sheet(isPresented: $isPresentingFilter) {
                    CardFilterSheet(
                        initialFilter: viewModel.filter,
                        availableSetCodes: viewModel.availableSetCodes,
                        onApply: { viewModel.applyFilter($0) }
                    )
                }
                .sheet(isPresented: $isPresentingAddCard) {
                    AddCardSheet(
                        viewModel: DependencyContainer.shared.makeAddCardViewModel(),
                        displayCurrency: viewModel.currency
                    )
                }
                .overlay(alignment: .bottom) { undoOverlay }
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.recentlyRemoved?.id)
        }
        .accessibilityIdentifier(CollectionAccessibilityFields.screen)
    }

    @ViewBuilder
    private var undoOverlay: some View {
        if let removed = viewModel.recentlyRemoved {
            UndoToast(
                message: "Removed \(removed.name)",
                onUndo: { Task { await viewModel.undoRemoveCard() } },
                onDismiss: { viewModel.dismissUndo() }
            )
            .accessibilityIdentifier(CollectionAccessibilityFields.undoToast)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            sortMenu
        }

        ToolbarItem(placement: .topBarLeading) {
            Button {
                isPresentingWishlist = true
            } label: {
                Image(systemName: "heart")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
            }
            .accessibilityLabel("Wishlist")
            .accessibilityIdentifier(CollectionAccessibilityFields.wishlistToolbar)
        }

        ToolbarItem(placement: .topBarTrailing) {
            filterButton
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresentingAddCard = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
            }
            .accessibilityLabel("Add card")
            .accessibilityIdentifier(CollectionAccessibilityFields.addCardToolbar)
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: sortBinding) {
                ForEach(CardSortOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.uv.gold)
        }
        .accessibilityLabel("Sort")
    }

    private var filterButton: some View {
        Button {
            isPresentingFilter = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)

                if viewModel.hasActiveFilter {
                    Circle()
                        .fill(Color.uv.gold)
                        .frame(width: 8, height: 8)
                        .offset(x: 4, y: -2)
                }
            }
        }
        .accessibilityLabel("Filters")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .error(let message):
            errorPanel(message: message)

        case .loading where viewModel.cards.isEmpty:
            loadingPanel

        case .idle, .loading, .loadingMore:
            cardList
        }
    }

    // MARK: - States

    private var loadingPanel: some View {
        ScrollView {
            ListSkeleton()
        }
        .scrollDisabled(true)
    }

    private func errorPanel(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: Layout.heroIcon, weight: .medium))
                .foregroundStyle(Color.uv.down)

            VStack(spacing: Spacing.xs) {
                Text("Couldn't load the catalogue")
                    .font(.uv.display(16, weight: .semibold))
                    .foregroundStyle(Color.uv.text)

                Text(message)
                    .font(.uv.body(12))
                    .foregroundStyle(Color.uv.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Button {
                Task { await viewModel.loadOrSeed() }
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

    private var cardList: some View {
        rowList
    }

    private var rowList: some View {
        List {
            if viewModel.hasActiveFilter {
                activeFilterStrip
                    .listRowBackground(Color.uv.bg)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.screenEdge, bottom: Spacing.md, trailing: Spacing.screenEdge))
            }

            if viewModel.cards.isEmpty {
                emptyResults
                    .listRowBackground(Color.uv.bg)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: Spacing.xl, leading: Spacing.screenEdge, bottom: Spacing.xl, trailing: Spacing.screenEdge))
            } else {
                ForEach(viewModel.cards) { card in
                NavigationLink(value: card) {
                    CardRowView(card: card, displayCurrency: viewModel.currency, rate: viewModel.exchangeRate, price: viewModel.price(for: card.id), isFetching: viewModel.isFetchingPrice(card.id))
                }
                .listRowBackground(Color.uv.bg)
                .listRowSeparatorTint(Color.uv.stroke.opacity(0.4))
                .listRowInsets(EdgeInsets(
                    top: Spacing.xs,
                    leading: Spacing.screenEdge,
                    bottom: Spacing.xs,
                    trailing: Spacing.screenEdge
                ))
                .accessibilityIdentifier("cell_collection_card_\(card.setCode)_\(card.collectorNumber)")
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await viewModel.removeCard(id: card.id) }
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                    .tint(Color.uv.down)
                    .accessibilityIdentifier("btn_collection_remove_\(card.setCode)_\(card.collectorNumber)")
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        UIPasteboard.general.string = card.name
                    } label: {
                        Label("Copy name", systemImage: "doc.on.doc")
                    }
                    .tint(Color.uv.gold)
                    .accessibilityIdentifier("btn_collection_copy_\(card.setCode)_\(card.collectorNumber)")
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = card.name
                    } label: {
                        Label("Copy name", systemImage: "doc.on.doc")
                    }
                    Button(role: .destructive) {
                        Task { await viewModel.removeCard(id: card.id) }
                    } label: {
                        Label("Remove from catalogue", systemImage: "trash")
                    }
                }
            }

            if case .loadingMore = viewModel.status {
                loadMoreSpinner
                    .listRowBackground(Color.uv.bg)
                    .listRowSeparator(.hidden)
            } else if viewModel.hasMore {
                Color.clear
                    .frame(height: 1)
                    .listRowBackground(Color.uv.bg)
                    .listRowSeparator(.hidden)
                    .task { await viewModel.loadMoreIfNeeded() }
            }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.uv.bg)
        .refreshable { await viewModel.pullToRefresh() }
    }

    private var loadMoreSpinner: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(Color.uv.gold)
            Spacer()
        }
        .padding(.vertical, Spacing.lg)
    }

    // MARK: - Active filter strip

    @ViewBuilder
    private var activeFilterStrip: some View {
        if viewModel.hasActiveFilter {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)

                Text(filterSummary)
                    .font(.uv.body(12, weight: .medium))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)

                Spacer()

                Button("Clear") {
                    viewModel.clearFilter()
                }
                .font(.uv.body(12, weight: .semibold))
                .foregroundStyle(Color.uv.gold)
            }
            .padding(.horizontal, Spacing.rowHorizontal)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: UVRadius.md)
                    .fill(Color.uv.gold.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: UVRadius.md)
                            .strokeBorder(Color.uv.gold.opacity(0.35), lineWidth: 1)
                    )
            )
        }
    }

    private var filterSummary: String {
        var parts: [String] = []
        if !viewModel.filter.sets.isEmpty {
            parts.append("\(String(localized: "Sets")): \(viewModel.filter.sets.map { $0.uppercased() }.sorted().joined(separator: ", "))")
        }
        if !viewModel.filter.colors.isEmpty {
            parts.append("\(String(localized: "Colours")): \(viewModel.filter.colors.map(\.displayName).sorted().joined(separator: ", "))")
        }
        if !viewModel.filter.rarities.isEmpty {
            parts.append("\(String(localized: "Rarity")): \(viewModel.filter.rarities.map(\.displayName).sorted().joined(separator: ", "))")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Search

    private var collectionSubtitle: String {
        let value = CurrencyFormatter.format(
            viewModel.totalValueUSD, currency: viewModel.currency, rate: viewModel.exchangeRate
        )
        return "\(viewModel.matchingCount) cards · \(value)"
    }

    private var bindingForQuery: Binding<String> {
        Binding(
            get: { viewModel.searchQuery },
            set: { newValue in
                viewModel.searchQuery = newValue
                Task { await viewModel.search() }
            }
        )
    }

    private var sortBinding: Binding<CardSortOption> {
        Binding(
            get: { viewModel.sort },
            set: { viewModel.setSort($0) }
        )
    }

    // MARK: - Empty results

    private var emptyResults: some View {
        VStack(spacing: Spacing.md + 2) {
            UginMark(size: Layout.emptyStateMarkSize)
                .opacity(0.45)

            VStack(spacing: Spacing.xs + 2) {
                Text("No matches")
                    .font(.uv.display(18, weight: .semibold))
                    .foregroundStyle(Color.uv.text)

                Text("Try a different name or clear the filter.")
                    .font(.uv.body(13))
                    .foregroundStyle(Color.uv.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.lg)
                .fill(Color.uv.panel.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.lg)
                        .strokeBorder(Color.uv.stroke, lineWidth: 1)
                )
        )
    }
}

#Preview {
    CollectionView(viewModel: DependencyContainer.shared.makeCollectionViewModel())
        .preferredColorScheme(.dark)
}

//
//  CollectionView.swift
//  UginsVault — Presentation: Collection
//
//  The Collection tab. Header (title + count + total value), search,
//  card list with sort + filter + pagination. On empty catalogue,
//  kicks the seed flow automatically.
//

import SwiftUI

public struct CollectionView: View {

    @State private var viewModel: CollectionViewModel
    @State private var isPresentingFilter: Bool = false

    public init(viewModel: CollectionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            content
                .background(Color.uv.bg.ignoresSafeArea())
                .navigationTitle("")
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
                .sheet(isPresented: $isPresentingFilter) {
                    CardFilterSheet(
                        initialFilter: viewModel.filter,
                        availableSetCodes: viewModel.availableSetCodes,
                        onApply: { viewModel.applyFilter($0) }
                    )
                }
        }
        .accessibilityIdentifier(CollectionAccessibilityFields.screen)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            sortMenu
        }

        ToolbarItem(placement: .topBarTrailing) {
            filterButton
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                // TODO: open Add Card sheet
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
        case .seeding(let savedSoFar):
            seedingPanel(savedSoFar: savedSoFar)

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
        VStack(spacing: Spacing.md) {
            ProgressView()
                .tint(Color.uv.gold)
            Text("Loading…")
                .font(.uv.body(13))
                .foregroundStyle(Color.uv.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func seedingPanel(savedSoFar: Int) -> some View {
        VStack(spacing: Spacing.md + 2) {
            UginMark(size: Layout.emptyStateMarkSize, showsGlow: true)

            VStack(spacing: Spacing.xs) {
                Text("Building your catalogue")
                    .font(.uv.display(18, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                Text("Pulling cards from Scryfall…")
                    .font(.uv.body(13))
                    .foregroundStyle(Color.uv.muted)
            }

            HStack(spacing: Spacing.sm) {
                ProgressView()
                    .tint(Color.uv.gold)
                Text("\(savedSoFar) cards saved")
                    .font(.uv.mono(12))
                    .foregroundStyle(Color.uv.muted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Spacing.xl)
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
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                searchBar(query: bindingForQuery)
                activeFilterStrip
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)

            if viewModel.cards.isEmpty {
                ScrollView {
                    emptyResults
                        .padding(.horizontal, Spacing.screenEdge)
                        .padding(.vertical, Spacing.xl)
                }
                .refreshable { await viewModel.pullToRefresh() }
            } else {
                rowList
            }
        }
    }

    private var rowList: some View {
        List {
            ForEach(viewModel.cards) { card in
                NavigationLink(value: card) {
                    CardRowView(card: card, displayCurrency: viewModel.currency)
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Collection")
                .font(.uv.display(30, weight: .bold))
                .tracking(-0.3)
                .foregroundStyle(Color.uv.text)
                .accessibilityIdentifier(CollectionAccessibilityFields.title)

            HStack(spacing: Spacing.sm) {
                Text("\(viewModel.matchingCount) cards")
                    .font(.uv.mono(12))
                    .foregroundStyle(Color.uv.muted)
                    .accessibilityIdentifier(CollectionAccessibilityFields.cardCountLabel)

                Circle()
                    .fill(Color.uv.muted.opacity(0.5))
                    .frame(width: 3, height: 3)

                Text(CurrencyFormatter.format(viewModel.totalValueUSD, currency: viewModel.currency))
                    .font(.uv.mono(12, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
                    .accessibilityIdentifier(CollectionAccessibilityFields.totalValueLabel)
            }
        }
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
            parts.append("Sets: \(viewModel.filter.sets.map { $0.uppercased() }.sorted().joined(separator: ", "))")
        }
        if !viewModel.filter.colors.isEmpty {
            parts.append("Colours: \(viewModel.filter.colors.map(\.displayName).sorted().joined(separator: ", "))")
        }
        if !viewModel.filter.rarities.isEmpty {
            parts.append("Rarity: \(viewModel.filter.rarities.map { $0.rawValue.capitalized }.sorted().joined(separator: ", "))")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Search

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

    private func searchBar(query: Binding<String>) -> some View {
        HStack(spacing: Spacing.md - 2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.uv.muted)

            TextField("Search collection…", text: query)
                .font(.uv.body(14))
                .foregroundStyle(Color.uv.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier(CollectionAccessibilityFields.searchField)
        }
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.md - 2)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: 1)
                )
        )
    }

    // MARK: - Empty results

    private var emptyResults: some View {
        VStack(spacing: Spacing.md + 2) {
            UginMark(size: Layout.emptyStateMarkSize, showsGlow: false)
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

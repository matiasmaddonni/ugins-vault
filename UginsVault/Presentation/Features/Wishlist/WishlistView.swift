//
//  WishlistView.swift
//  UginsVault — Presentation: Wishlist
//
//  The Wishlist screen. Reachable from the Dashboard teaser + a Settings
//  row (it is intentionally NOT a tab, per the brief). Pushed onto the
//  caller's navigation stack, so it adds a toolbar but no stack of its
//  own. Lists wishlisted cards with swipe-to-remove + a "+" that opens
//  a Scryfall search sheet.
//

import SwiftUI
import Kingfisher

public struct WishlistView: View {

    @State private var viewModel: WishlistViewModel

    public init(viewModel: WishlistViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        content
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Wishlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbar }
            .task { await viewModel.onAppear() }
            .sheet(isPresented: $viewModel.isPresentingAdd) {
                AddToWishlistSheet(viewModel: viewModel)
            }
            .accessibilityIdentifier(WishlistAccessibilityFields.screen)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.presentAdd()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: Layout.mediumIcon - 1, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
            }
            .accessibilityLabel("Add to wishlist")
            .accessibilityIdentifier(WishlistAccessibilityFields.addToolbar)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .error(let message):
            errorPanel(message: message)
        case .loading where viewModel.items.isEmpty:
            loadingPanel
        case .idle, .loading:
            if viewModel.isEmpty { emptyState } else { list }
        }
    }

    private var list: some View {
        List {
            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                WishlistRow(
                    item: item,
                    currency: viewModel.currency,
                    rate: viewModel.exchangeRate,
                    index: index
                )
                .listRowBackground(Color.uv.bg)
                .listRowSeparatorTint(Color.uv.stroke.opacity(0.4))
                .listRowInsets(EdgeInsets(
                    top: Spacing.xs,
                    leading: Spacing.screenEdge,
                    bottom: Spacing.xs,
                    trailing: Spacing.screenEdge
                ))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await viewModel.remove(id: item.id) }
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                    .tint(Color.uv.down)
                    .accessibilityIdentifier(WishlistAccessibilityFields.removeButton(at: index))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.uv.bg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(WishlistAccessibilityFields.list)
        .refreshable { await viewModel.load() }
    }

    // MARK: - Empty / loading / error

    private var emptyState: some View {
        VStack(spacing: Spacing.md + 2) {
            Image(systemName: "heart")
                .font(.system(size: Layout.heroIcon, weight: .medium))
                .foregroundStyle(Color.uv.lavender.opacity(0.6))

            VStack(spacing: Spacing.xs + 2) {
                Text("Your wishlist is empty")
                    .font(.uv.display(18, weight: .semibold))
                    .foregroundStyle(Color.uv.text)

                Text("Search for cards you want and add them to track their price.")
                    .font(.uv.body(13))
                    .foregroundStyle(Color.uv.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Button {
                viewModel.presentAdd()
            } label: {
                Text("Add a card")
                    .font(.uv.body(14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x1A1410))
                    .padding(.horizontal, Spacing.lg + 2)
                    .padding(.vertical, Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: UVRadius.md).fill(Color.uv.gold)
                    )
            }
            .accessibilityIdentifier(WishlistAccessibilityFields.emptyAddButton)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Spacing.xl)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(WishlistAccessibilityFields.emptyState)
    }

    private var loadingPanel: some View {
        ScrollView {
            ListSkeleton(
                thumbWidth: Layout.collectionRowThumbWidth,
                thumbHeight: Layout.collectionRowThumbHeight
            )
        }
        .scrollDisabled(true)
    }

    private func errorPanel(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: Layout.heroIcon, weight: .medium))
                .foregroundStyle(Color.uv.down)
            Text(message)
                .font(.uv.body(12))
                .foregroundStyle(Color.uv.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            Button {
                Task { await viewModel.load() }
            } label: {
                Text("Try again")
                    .font(.uv.body(14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x1A1410))
                    .padding(.horizontal, Spacing.lg + 2)
                    .padding(.vertical, Spacing.md)
                    .background(RoundedRectangle(cornerRadius: UVRadius.md).fill(Color.uv.gold))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Row

private struct WishlistRow: View {

    let item: WishlistItem
    let currency: Currency
    let rate: ExchangeRate?
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            thumbnail

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.name)
                    .font(.uv.body(15, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)

                Text(item.typeLine)
                    .font(.uv.body(12))
                    .foregroundStyle(Color.uv.muted)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    Text("\(item.setCode.uppercased()) · #\(item.collectorNumber)")
                        .font(.uv.mono(11))
                        .foregroundStyle(Color.uv.muted2)

                    if let price = item.usdPrice {
                        Text(CurrencyFormatter.format(price, currency: currency, rate: rate))
                            .font(.uv.mono(11, weight: .semibold))
                            .foregroundStyle(Color.uv.gold)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(WishlistAccessibilityFields.row(at: index))
    }

    private var thumbnail: some View {
        Group {
            if let url = item.thumbnailURL {
                KFImage(url)
                    .placeholder { placeholder }
                    .fade(duration: 0.15)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: Layout.stackDetailRowThumbWidth, height: Layout.stackDetailRowThumbHeight)
        .clipShape(RoundedRectangle(cornerRadius: UVRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: UVRadius.sm)
                .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
        )
    }

    private var placeholder: some View {
        ZStack {
            Color.uv.panelLo
            Image(systemName: "rectangle.portrait")
                .font(.system(size: Layout.smallIcon, weight: .regular))
                .foregroundStyle(Color.uv.muted2)
        }
    }
}

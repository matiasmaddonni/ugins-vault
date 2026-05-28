//
//  AddToWishlistSheet.swift
//  UginsVault — Presentation: Wishlist
//
//  Modal search over Scryfall for adding cards to the wishlist. Debounced
//  query lives on the shared `WishlistViewModel`; tapping a result adds it
//  and flips the row to an "added" checkmark. Stays open so the user can
//  add several cards in one sitting.
//

import SwiftUI

struct AddToWishlistSheet: View {

    @Bindable var viewModel: WishlistViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                searchBar
                results
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.md)
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("Add to wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.uv.body(15, weight: .semibold))
                        .foregroundStyle(Color.uv.gold)
                        .accessibilityIdentifier(WishlistAccessibilityFields.addDoneButton)
                }
            }
            .tint(Color.uv.gold)
            .task {
                try? await Task.sleep(for: .milliseconds(250))
                isSearchFocused = true
            }
        }
        .presentationBackground(Color.uv.bg)
        .accessibilityIdentifier(WishlistAccessibilityFields.addSheet)
    }

    // MARK: - Search field

    private var searchBar: some View {
        HStack(spacing: Spacing.md - 2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.uv.muted)

            TextField("Search Scryfall…", text: $viewModel.searchQuery)
                .font(.uv.body(14))
                .foregroundStyle(Color.uv.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onChange(of: viewModel.searchQuery) { _, _ in viewModel.search() }
                .accessibilityIdentifier(WishlistAccessibilityFields.searchField)

            if viewModel.isSearching {
                ProgressView().tint(Color.uv.gold)
            }
        }
        .padding(.horizontal, Spacing.rowHorizontal)
        .padding(.vertical, Spacing.md - 2)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                )
        )
    }

    // MARK: - Results

    @ViewBuilder
    private var results: some View {
        if viewModel.searchResults.isEmpty {
            if viewModel.isSearching {
                ScrollView {
                    ListSkeleton(
                        thumbWidth: Layout.stackDetailRowThumbWidth,
                        thumbHeight: Layout.stackDetailRowThumbHeight
                    )
                }
                .scrollDisabled(true)
            } else {
                hintPanel
            }
        } else {
            List {
                ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, card in
                    resultRow(card: card, index: index)
                        .listRowBackground(Color.uv.bg)
                        .listRowSeparatorTint(Color.uv.stroke.opacity(0.4))
                        .listRowInsets(EdgeInsets(
                            top: Spacing.xs,
                            leading: 0,
                            bottom: Spacing.xs,
                            trailing: 0
                        ))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.uv.bg)
        }
    }

    private func resultRow(card: Card, index: Int) -> some View {
        let added = viewModel.isInWishlist(card.id)
        return HStack(spacing: Spacing.md) {
            CollectionItemThumbnail(card: card)

            VStack(alignment: .leading, spacing: Spacing.xs - 2) {
                Text(card.name)
                    .font(.uv.body(14, weight: .semibold))
                    .foregroundStyle(Color.uv.text)
                    .lineLimit(1)
                Text("\(card.setCode.uppercased()) · #\(card.collectorNumber)")
                    .font(.uv.mono(11))
                    .foregroundStyle(Color.uv.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: Spacing.sm)

            Button {
                Task { await viewModel.add(card) }
            } label: {
                Image(systemName: added ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: Layout.mediumIcon, weight: .semibold))
                    .foregroundStyle(added ? Color.uv.up : Color.uv.gold)
            }
            .disabled(added)
            .accessibilityIdentifier(WishlistAccessibilityFields.resultAddButton(at: index))
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(WishlistAccessibilityFields.resultRow(at: index))
    }

    private var hintPanel: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Layout.heroIcon, weight: .medium))
                .foregroundStyle(Color.uv.muted2)
            Text(viewModel.searchQuery.isEmpty
                 ? "Search by card name to add to your wishlist."
                 : "No matches.")
                .font(.uv.body(13))
                .foregroundStyle(Color.uv.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Spacing.xxl)
    }
}

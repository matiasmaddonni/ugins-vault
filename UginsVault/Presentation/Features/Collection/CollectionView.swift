//
//  CollectionView.swift
//  UginsVault — Presentation: Collection
//
//  The Collection tab. Header (title + count + value), search, empty state.
//  Tab bar is owned by `MainTabView`. Theme is owned by Settings + RootView.
//

import SwiftUI

public struct CollectionView: View {

    @State private var viewModel: CollectionViewModel

    public init(viewModel: CollectionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    searchBar(query: $viewModel.searchQuery)
                    emptyState
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.uv.bg.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: open Add Card sheet
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.uv.gold)
                    }
                    .accessibilityLabel("Add card")
                }
            }
            .onAppear { viewModel.refreshPreferences() }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Collection")
                .font(.uv.display(30, weight: .bold))
                .tracking(-0.3)
                .foregroundStyle(Color.uv.text)

            HStack(spacing: 8) {
                Text("\(viewModel.cardCount) cards")
                    .font(.uv.mono(12))
                    .foregroundStyle(Color.uv.muted)

                Circle()
                    .fill(Color.uv.muted.opacity(0.5))
                    .frame(width: 3, height: 3)

                Text(CurrencyFormatter.format(viewModel.totalValue, currency: viewModel.currency))
                    .font(.uv.mono(12, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
            }
        }
    }

    // MARK: - Search

    private func searchBar(query: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.uv.muted)

            TextField("Search collection…", text: query)
                .font(.uv.body(14))
                .foregroundStyle(Color.uv.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: UVRadius.md)
                .fill(Color.uv.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: UVRadius.md)
                        .strokeBorder(Color.uv.stroke, lineWidth: 1)
                )
        )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            UginMark(size: 60, showsGlow: false)
                .opacity(0.45)

            VStack(spacing: 6) {
                Text("Your vault is empty")
                    .font(.uv.display(18, weight: .semibold))
                    .foregroundStyle(Color.uv.text)

                Text("Add your first card or import a CSV from ManaBox, Moxfield, or Archidekt.")
                    .font(.uv.body(13))
                    .foregroundStyle(Color.uv.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            HStack(spacing: 8) {
                Button { /* TODO: open Add Card sheet */ } label: {
                    Label("Add card", systemImage: "plus")
                        .font(.uv.body(14, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x1A1410))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: UVRadius.md).fill(Color.uv.gold)
                        )
                }

                Button { /* TODO: import CSV */ } label: {
                    Label("Import CSV", systemImage: "tray.and.arrow.down")
                        .font(.uv.body(14, weight: .semibold))
                        .foregroundStyle(Color.uv.text)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: UVRadius.md)
                                .strokeBorder(Color.uv.stroke, lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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

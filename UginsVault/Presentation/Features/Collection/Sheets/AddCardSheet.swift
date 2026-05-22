//
//  AddCardSheet.swift
//  UginsVault — Presentation: Collection
//
//  Search Scryfall for a card to add. Tapping a result pushes Card Detail,
//  which owns the "Add to stack" flow (+ other printings). Kept thin on
//  purpose — no duplicate add UI here.
//

import SwiftUI

struct AddCardSheet: View {

    @State private var viewModel: AddCardViewModel
    private let displayCurrency: Currency
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AddCardViewModel, displayCurrency: Currency) {
        _viewModel = State(initialValue: viewModel)
        self.displayCurrency = displayCurrency
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            resultsList
                .overlay { stateOverlay }
                .background(Color.uv.bg.ignoresSafeArea())
                .navigationTitle("Add card")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.query, prompt: Text("Search cards…"))
                .onChange(of: viewModel.query) { _, _ in viewModel.onQueryChange() }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Color.uv.muted)
                    }
                }
                .navigationDestination(for: Card.self) { card in
                    CardDetailView(
                        viewModel: DependencyContainer.shared.makeCardDetailViewModel(
                            card: card,
                            displayCurrency: displayCurrency
                        )
                    )
                }
                .tint(Color.uv.gold)
        }
        .presentationDetents([.large])
        .presentationBackground(Color.uv.bg)
        .accessibilityIdentifier(CollectionAccessibilityFields.addCardSheet)
    }

    private var resultsList: some View {
        List {
            ForEach(Array(viewModel.results.enumerated()), id: \.offset) { index, card in
                NavigationLink(value: card) {
                    CardRowView(card: card, displayCurrency: displayCurrency)
                }
                .listRowBackground(Color.uv.bg)
                .listRowSeparatorTint(Color.uv.stroke.opacity(0.4))
                .listRowInsets(EdgeInsets(
                    top: Spacing.xs,
                    leading: Spacing.screenEdge,
                    bottom: Spacing.xs,
                    trailing: Spacing.screenEdge
                ))
                .accessibilityIdentifier(CollectionAccessibilityFields.addCardResult(at: index))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var stateOverlay: some View {
        switch viewModel.status {
        case .searching:
            ProgressView().tint(Color.uv.gold)
        case .empty:
            hint("No matches")
        case .error(let message):
            hint(message)
        case .idle where viewModel.results.isEmpty:
            hint("Search Scryfall to add a card")
        default:
            EmptyView()
        }
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.uv.body(13))
            .foregroundStyle(Color.uv.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, Spacing.xl)
            .multilineTextAlignment(.center)
    }
}

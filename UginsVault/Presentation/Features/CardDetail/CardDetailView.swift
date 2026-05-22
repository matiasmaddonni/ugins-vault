//
//  CardDetailView.swift
//  UginsVault — Presentation: CardDetail
//
//  Single-card screen. Hero image + name + type line + oracle text +
//  prices block + a horizontal strip of every other printing that shares
//  this card's oracle id. Pushed onto the Collection navigation stack
//  on row tap.
//

import SwiftUI
import Kingfisher

public struct CardDetailView: View {

    @State private var viewModel: CardDetailViewModel
    @State private var isPresentingAddToStack: Bool = false

    public init(viewModel: CardDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                hero
                header
                addToStackButton
                oracleBlock
                pricesBlock
                otherPrintingsBlock
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.vertical, Spacing.lg)
        }
        .background(Color.uv.bg.ignoresSafeArea())
        .navigationTitle(viewModel.card.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.refreshCardIfStale()
            await viewModel.loadPricing()
            await viewModel.loadOtherPrintings()
            await viewModel.loadAvailableStacks()
        }
        .sheet(isPresented: $isPresentingAddToStack) {
            addToStackSheet
        }
        .overlay(alignment: .bottom) { addedToastOverlay }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.lastAddedStackName)
    }

    // MARK: - Add to stack

    @ViewBuilder
    private var addToStackButton: some View {
        if !viewModel.availableStacks.isEmpty {
            Button {
                isPresentingAddToStack = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.system(size: Layout.mediumIcon - 2, weight: .semibold))
                    Text("Add to stack")
                        .font(.uv.body(14, weight: .semibold))
                }
                .foregroundStyle(Color(hex: 0x1A1410))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: UVRadius.md).fill(Color.uv.gold)
                )
            }
            .accessibilityIdentifier("btn_card_detail_add_to_stack")
        }
    }

    private var addToStackSheet: some View {
        SheetPicker<UUID>(
            title: "Add to stack",
            options: viewModel.availableStacks.map { stack in
                SheetPicker<UUID>.Option(
                    id: stack.id,
                    label: stack.name,
                    detail: addToStackDetail(for: stack)
                )
            },
            selection: UUID(),
            onSelect: { stackID in
                Task { await viewModel.addCard(to: stackID) }
            }
        )
    }

    private func addToStackDetail(for stack: Stack) -> String {
        if stack.kind == .deck, let format = stack.format {
            return "\(stack.kind.displayLabel) · \(format.displayName)"
        }
        return stack.kind.displayLabel
    }

    @ViewBuilder
    private var addedToastOverlay: some View {
        if let name = viewModel.lastAddedStackName {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.uv.up)
                Text("Added to \(name)")
                    .font(.uv.body(13, weight: .medium))
                    .foregroundStyle(Color.uv.text)
                Spacer()
                Button("Dismiss") {
                    viewModel.dismissAddToStackToast()
                }
                .font(.uv.body(12, weight: .semibold))
                .foregroundStyle(Color.uv.gold)
            }
            .padding(.horizontal, Spacing.rowHorizontal)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: UVRadius.md)
                    .fill(Color.uv.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: UVRadius.md)
                            .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                    )
            )
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.bottom, Spacing.lg)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task {
                try? await Task.sleep(for: .seconds(3))
                viewModel.dismissAddToStackToast()
            }
            .accessibilityIdentifier("view_card_detail_added_toast")
        }
    }

    private var card: Card { viewModel.card }
    private var displayCurrency: Currency { viewModel.displayCurrency }

    // MARK: - Hero

    private var hero: some View {
        Group {
            if let url = card.images.hero {
                KFImage(url)
                    .placeholder { heroPlaceholder }
                    .fade(duration: 0.2)
                    .resizable()
                    .scaledToFit()
            } else {
                heroPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: UVRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: UVRadius.lg)
                .strokeBorder(Color.uv.stroke, lineWidth: 1)
        )
    }

    private var heroPlaceholder: some View {
        ZStack {
            Color.uv.panel
            Image(systemName: "rectangle.portrait")
                .font(.system(size: Layout.heroIcon, weight: .regular))
                .foregroundStyle(Color.uv.muted2)
        }
        .aspectRatio(488 / 680, contentMode: .fit)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(card.name)
                .font(.uv.display(24, weight: .semibold))
                .foregroundStyle(Color.uv.text)

            Text(card.typeLine)
                .font(.uv.body(14, weight: .medium))
                .foregroundStyle(Color.uv.text2)

            HStack(spacing: Spacing.sm) {
                Text(card.setName)
                    .font(.uv.mono(12))
                    .foregroundStyle(Color.uv.muted)

                Circle()
                    .fill(Color.uv.muted.opacity(0.5))
                    .frame(width: 3, height: 3)

                Text("#\(card.collectorNumber)")
                    .font(.uv.mono(12))
                    .foregroundStyle(Color.uv.muted)

                if card.rarity != .unknown {
                    Circle()
                        .fill(Color.uv.muted.opacity(0.5))
                        .frame(width: 3, height: 3)

                    Text(card.rarity.rawValue.uppercased())
                        .font(.uv.mono(11, weight: .semibold))
                        .foregroundStyle(Color.uv.gold)
                }
            }

            if card.isReserved {
                reservedListBadge
                    .padding(.top, Spacing.xs)
            }
        }
    }

    private var reservedListBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("Reserved List")
                .font(.uv.body(11, weight: .semibold))
        }
        .foregroundStyle(Color.uv.gold)
        .padding(.horizontal, Spacing.sm + 2)
        .padding(.vertical, Spacing.xs + 2)
        .background(
            Capsule()
                .fill(Color.uv.gold.opacity(0.12))
                .overlay(
                    Capsule().strokeBorder(Color.uv.gold.opacity(0.5), lineWidth: 1)
                )
        )
    }

    // MARK: - Oracle text

    @ViewBuilder
    private var oracleBlock: some View {
        if let text = card.oracleText, !text.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Rules text")
                    .uvSectionLabel()
                ManaSymbolText(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: UVRadius.md)
                    .fill(Color.uv.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: UVRadius.md)
                            .strokeBorder(Color.uv.stroke, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Prices

    private var pricesBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Prices")
                    .uvSectionLabel()
                Spacer()
                Text(priceSourceLabel)
                    .font(.uv.mono(10))
                    .foregroundStyle(Color.uv.muted)
            }

            VStack(spacing: 0) {
                ForEach(Array(priceRows.enumerated()), id: \.offset) { index, row in
                    HStack {
                        Text(row.label)
                            .font(.uv.body(14, weight: .medium))
                            .foregroundStyle(Color.uv.text)

                        Spacer()

                        Text(row.value)
                            .font(.uv.mono(14, weight: .semibold))
                            .foregroundStyle(Color.uv.gold)
                    }
                    .padding(.horizontal, Spacing.rowHorizontal)
                    .padding(.vertical, Spacing.rowVertical)

                    if index != priceRows.count - 1 {
                        Rectangle()
                            .fill(Color.uv.stroke.opacity(0.6))
                            .frame(height: Layout.hairline)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: UVRadius.md)
                    .fill(Color.uv.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: UVRadius.md)
                            .strokeBorder(Color.uv.stroke, lineWidth: 1)
                    )
            )

            historyBlock
        }
    }

    private struct PriceRow: Hashable {
        let label: String
        let value: String
    }

    private var priceSourceLabel: String {
        let source: PriceSource
        if case .marketplace(let resolvedSource) = viewModel.resolvedPrice?.source {
            source = resolvedSource
        } else {
            source = viewModel.preferredSource
        }
        return "via MTGJSON · \(source.displayName)"
    }

    private var priceRows: [PriceRow] {
        guard let resolved = viewModel.resolvedPrice else {
            let placeholder: String
            switch viewModel.priceState {
            case .noData:            placeholder = String(localized: "No price")
            case .fetching, .priced: placeholder = String(localized: "Fetching…")
            }
            return [PriceRow(label: "Retail", value: placeholder)]
        }
        return [
            PriceRow(
                label: "Retail",
                value: CurrencyFormatter.format(resolved.amount, currency: resolved.currency)
            )
        ]
    }

    // MARK: - 30-day price history sparkline

    @ViewBuilder
    private var historyBlock: some View {
        if viewModel.priceHistory.count >= 2 {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("30-day trend")
                        .uvSectionLabel()
                    Spacer()
                    if let delta = priceDelta {
                        Text(delta.formatted)
                            .font(.uv.mono(11, weight: .semibold))
                            .foregroundStyle(delta.isUp ? Color.uv.up : Color.uv.down)
                    }
                }
                SparklineView(points: viewModel.priceHistory.map(\.retail))
                    .frame(height: Layout.dashboardSparklineHeight)
            }
            .padding(.top, Spacing.sm)
        } else if viewModel.resolvedPrice != nil {
            // Priced, but fewer than 2 daily points yet — the chart needs a few
            // days of tracking to draw. Explain instead of showing nothing.
            HStack(spacing: Spacing.sm) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.uv.muted)
                Text("Price history builds up after a few days of tracking.")
                    .font(.uv.body(12))
                    .foregroundStyle(Color.uv.muted)
            }
            .padding(.top, Spacing.sm)
        }
    }

    private struct Delta {
        let formatted: String
        let isUp: Bool
    }

    private var priceDelta: Delta? {
        guard let first = viewModel.priceHistory.first?.retail,
              let last = viewModel.priceHistory.last?.retail,
              first > 0
        else { return nil }
        let change = last - first
        let isUp = change >= 0
        let pct = (NSDecimalNumber(decimal: change).doubleValue
                 / NSDecimalNumber(decimal: first).doubleValue) * 100
        let prefix = isUp ? "+" : ""
        return Delta(
            formatted: "\(prefix)\(String(format: "%.1f", pct))%",
            isUp: isUp
        )
    }

    // MARK: - Other printings

    @ViewBuilder
    private var otherPrintingsBlock: some View {
        switch viewModel.status {
        case .idle, .loading:
            otherPrintingsHeader(showsSpinner: viewModel.status == .loading)
        case .failed:
            VStack(alignment: .leading, spacing: Spacing.sm) {
                otherPrintingsHeader(showsSpinner: false)
                Text("Couldn't load other printings.")
                    .font(.uv.body(12))
                    .foregroundStyle(Color.uv.muted)
            }
        case .loaded where !viewModel.otherPrintings.isEmpty:
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Other printings")
                    .uvSectionLabel()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(viewModel.otherPrintings) { printing in
                            Button {
                                viewModel.switchTo(printing)
                            } label: {
                                OtherPrintingChip(card: printing)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("btn_card_detail_other_\(printing.setCode)_\(printing.collectorNumber)")
                        }
                    }
                    .padding(.horizontal, Spacing.xs)
                }
            }
        case .loaded:
            EmptyView()
        }
    }

    private func otherPrintingsHeader(showsSpinner: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            Text("Other printings")
                .uvSectionLabel()
            if showsSpinner {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.uv.gold)
            }
        }
    }
}

// MARK: - OtherPrintingChip

private struct OtherPrintingChip: View {

    let card: Card

    var body: some View {
        VStack(spacing: Spacing.xs) {
            thumbnail

            VStack(spacing: 2) {
                Text(card.setCode.uppercased())
                    .font(.uv.mono(11, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
                Text("#\(card.collectorNumber)")
                    .font(.uv.mono(10))
                    .foregroundStyle(Color.uv.muted)
            }
        }
        .frame(width: 72)
    }

    private var thumbnail: some View {
        Group {
            if let url = card.images.thumbnail {
                KFImage(url)
                    .placeholder { placeholder }
                    .fade(duration: 0.15)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .frame(width: 64, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: UVRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: UVRadius.sm)
                .strokeBorder(Color.uv.stroke, lineWidth: 1)
        )
    }

    private var placeholder: some View {
        ZStack {
            Color.uv.panel
            Image(systemName: "rectangle.portrait")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.uv.muted2)
        }
    }
}

//
//  PricingSettingsGroup.swift
//  UginsVault — Presentation: Settings
//
//  Self-contained Settings panel for the v0.5+ pricing prefs:
//  preferred marketplace, Dashboard mover threshold, optional manual
//  USD→ARS override. Marketplace + threshold read/write `SessionStateStore`
//  directly so `SettingsViewModel` doesn't grow another 6 dependencies;
//  the manual ARS override goes through its Get/Set use cases.
//

import SwiftUI

public struct PricingSettingsGroup: View {

    private let sessionRepository: SessionStateStore
    private let exchangeRateRepository: ExchangeRateRepository
    private let getManualARSRate: GetManualARSRateUseCase
    private let setManualARSRate: SetManualARSRateUseCase

    @State private var isPresentingSourcePicker: Bool = false
    @State private var isPresentingThresholdEditor: Bool = false
    @State private var isPresentingARSEditor: Bool = false

    @State private var thresholdInput: String = ""
    @State private var arsInput: String = ""

    @FocusState private var isAmountFocused: Bool

    @State private var isRefreshingRates: Bool = false

    public init(
        sessionRepository: SessionStateStore,
        exchangeRateRepository: ExchangeRateRepository,
        getManualARSRate: GetManualARSRateUseCase,
        setManualARSRate: SetManualARSRateUseCase
    ) {
        self.sessionRepository = sessionRepository
        self.exchangeRateRepository = exchangeRateRepository
        self.getManualARSRate = getManualARSRate
        self.setManualARSRate = setManualARSRate
    }

    public var body: some View {
        @Bindable var session = sessionRepository as! SessionStateStore

        SettingsGroup("Pricing") {
            sourceRow
            divider
            thresholdRow
            divider
            arsRateRow
            divider
            refreshRatesRow
        }
        .sheet(isPresented: $isPresentingSourcePicker) {
            SheetPicker(
                title: String(localized: "Price source"),
                options: PriceSource.allCases.map {
                    SheetPicker<PriceSource>.Option(
                        id: $0,
                        label: $0.displayName,
                        detail: priceSourceDetail(for: $0)
                    )
                },
                selection: sessionRepository.preferredPriceSource,
                onSelect: { sessionRepository.savePreferredPriceSource($0) }
            )
        }
        .sheet(isPresented: $isPresentingThresholdEditor) {
            decimalEditorSheet(
                title: String(localized: "Mover threshold"),
                helper: String(localized: "Minimum 7-day USD delta a card has to hit to appear in the Dashboard gainers / losers."),
                placeholder: "1.00",
                input: $thresholdInput,
                onSave: {
                    if let value = Decimal(string: thresholdInput.replacingOccurrences(of: ",", with: ".")) {
                        sessionRepository.saveDashboardMoverThreshold(max(0, value))
                    }
                    isPresentingThresholdEditor = false
                },
                onClear: nil
            )
        }
        .sheet(isPresented: $isPresentingARSEditor) {
            decimalEditorSheet(
                title: String(localized: "Manual USD → ARS"),
                helper: String(localized: "Pin your own exchange rate (e.g. 1400). Leave blank or tap Clear to use the dolarapi blue feed."),
                placeholder: "1400",
                input: $arsInput,
                onSave: {
                    let normalized = arsInput.replacingOccurrences(of: ",", with: ".")
                    setManualARSRate.execute(Decimal(string: normalized))
                    isPresentingARSEditor = false
                },
                onClear: {
                    setManualARSRate.execute(nil)
                    arsInput = ""
                    isPresentingARSEditor = false
                }
            )
        }
    }

    private var sourceRow: some View {
        SettingsRow(
            icon: "tag",
            title: "Price source",
            value: sessionRepository.preferredPriceSource.displayName
        ) {
            isPresentingSourcePicker = true
        }
    }

    private var thresholdRow: some View {
        SettingsRow(
            icon: "arrow.up.arrow.down",
            title: "Mover threshold",
            value: CurrencyFormatter.format(
                sessionRepository.dashboardMoverThreshold,
                currency: .usd
            )
        ) {
            thresholdInput = formatDecimal(sessionRepository.dashboardMoverThreshold)
            isPresentingThresholdEditor = true
        }
    }

    private var arsRateRow: some View {
        SettingsRow(
            icon: "argentinianpesosign.circle",
            title: "Manual USD → ARS",
            value: getManualARSRate.execute().map(formatDecimal) ?? String(localized: "Auto")
        ) {
            arsInput = getManualARSRate.execute().map(formatDecimal) ?? ""
            isPresentingARSEditor = true
        }
    }

    private var refreshRatesRow: some View {
        SettingsRow(
            icon: "arrow.triangle.2.circlepath",
            title: "Refresh rates",
            subtitle: ratesSubtitle,
            action: { refreshRates() }
        ) {
            if isRefreshingRates {
                ProgressView()
                    .tint(Color.uv.gold)
            } else {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: Layout.smallIcon, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
            }
        }
        .disabled(isRefreshingRates)
    }

    private var ratesSubtitle: String {
        guard let date = exchangeRateRepository.lastRefreshedAt else {
            return String(localized: "Fetch the latest USD → ARS / EUR rates")
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return String(localized: "Updated \(formatter.localizedString(for: date, relativeTo: Date()))")
    }

    private func refreshRates() {
        guard !isRefreshingRates else { return }
        isRefreshingRates = true
        Task { @MainActor in
            _ = try? await exchangeRateRepository.refresh()
            isRefreshingRates = false
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.uv.stroke.opacity(0.4))
            .frame(height: Layout.hairline)
            .padding(.leading, Spacing.rowDividerLeading)
    }

    private func priceSourceDetail(for source: PriceSource) -> String {
        switch source {
        case .cardkingdom: return String(localized: "USD · default source")
        case .tcgplayer:   return String(localized: "USD · US marketplace")
        case .cardmarket:  return String(localized: "EUR · European marketplace")
        }
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.autoupdatingCurrent
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }

    @ViewBuilder
    private func decimalEditorSheet(
        title: String,
        helper: String,
        placeholder: String,
        input: Binding<String>,
        onSave: @escaping () -> Void,
        onClear: (() -> Void)?
    ) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(helper)
                    .font(.uv.body(13))
                    .foregroundStyle(Color.uv.muted)

                TextField(placeholder, text: input)
                    .focused($isAmountFocused)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, Spacing.rowHorizontal)
                    .padding(.vertical, Spacing.rowVertical)
                    .background(
                        RoundedRectangle(cornerRadius: UVRadius.md)
                            .fill(Color.uv.panel)
                            .overlay(
                                RoundedRectangle(cornerRadius: UVRadius.md)
                                    .strokeBorder(Color.uv.stroke, lineWidth: Layout.hairline)
                            )
                    )

                if let onClear {
                    Button("Clear", action: onClear)
                        .foregroundStyle(Color.uv.down)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.screenEdge)
            .padding(.top, Spacing.lg)
            .background(Color.uv.bg.ignoresSafeArea())
            .task {
                // Drop the cursor straight into the amount field so the
                // user edits the number immediately — no second tap.
                try? await Task.sleep(for: .milliseconds(250))
                isAmountFocused = true
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: onSave)
                        .font(.uv.body(15, weight: .semibold))
                        .foregroundStyle(Color.uv.gold)
                }
            }
            .tint(Color.uv.gold)
        }
        .presentationDetents([.medium])
        .presentationBackground(Color.uv.bg)
    }
}

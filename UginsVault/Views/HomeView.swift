//
//  HomeView.swift
//  UginsVault
//
//  Collection placeholder + skeleton tab bar (4 tabs + center gold + FAB).
//  Real grid, filters, search will replace the empty-state body.
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var app
    @State private var selectedTab: Tab = .collection
    @State private var search: String = ""

    enum Tab: Hashable {
        case collection, stacks, dashboard, settings
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.uv.bg.ignoresSafeArea()

            // Scrollable content area
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    searchBar
                    emptyState
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120) // tab bar clearance
            }

            tabBar
        }
        .preferredColorScheme(app.theme.colorScheme)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Spacer()
                Button {
                    app.theme = (app.theme == .dark) ? .light : .dark
                } label: {
                    Image(systemName: app.theme == .dark ? "moon.fill" : "sun.max.fill")
                        .foregroundStyle(Color.uv.text)
                        .padding(8)
                        .background(Circle().fill(Color.uv.panelHi))
                        .overlay(Circle().strokeBorder(Color.uv.stroke, lineWidth: 1))
                }
                .accessibilityLabel("Toggle theme")
            }

            Text("Collection")
                .font(.uv.display(30, weight: .bold))
                .tracking(-0.3)
                .foregroundStyle(Color.uv.text)

            HStack(spacing: 8) {
                Text("0 cards")
                    .font(.uv.mono(12))
                    .foregroundStyle(Color.uv.muted)
                Circle().fill(Color.uv.muted.opacity(0.5)).frame(width: 3, height: 3)
                Text("\(app.currency.symbol)0.00")
                    .font(.uv.mono(12, weight: .semibold))
                    .foregroundStyle(Color.uv.gold)
            }
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.uv.muted)
            TextField("Search collection…", text: $search)
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
                Text("Add your first card or import a CSV from ManaBox, Moxfield or Archidekt.")
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

    // MARK: - Tab bar (skeleton — replaced by real component later)

    private var tabBar: some View {
        ZStack(alignment: .top) {
            // Glass background row
            HStack(spacing: 0) {
                tabItem(.collection, icon: "rectangle.portrait.fill", label: "Collection")
                tabItem(.stacks, icon: "square.stack.fill", label: "Stacks")
                Color.clear.frame(width: 62)
                tabItem(.dashboard, icon: "chart.bar.fill", label: "Dashboard")
                tabItem(.settings, icon: "gearshape.fill", label: "Settings")
            }
            .padding(.horizontal, 6)
            .padding(.top, 10)
            .padding(.bottom, 28)
            .background(
                RoundedRectangle(cornerRadius: UVRadius.xl)
                    .fill(Color.uv.panel.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: UVRadius.xl)
                            .strokeBorder(Color.uv.stroke, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 16, y: -4)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            // Center gold FAB
            Button {
                // TODO: open Add Card sheet
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x1A1410))
                    .frame(width: 58, height: 58)
                    .background(
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.uv.goldHi, Color.uv.goldLo],
                                startPoint: .top, endPoint: .bottom
                            ))
                    )
                    .overlay(Circle().strokeBorder(.white.opacity(0.08), lineWidth: 1))
                    .shadow(color: Color.uv.gold.opacity(0.45), radius: 12, y: 6)
            }
            .accessibilityLabel("Add card")
            .offset(y: -4)
        }
        .frame(maxWidth: .infinity)
    }

    private func tabItem(_ tab: Tab, icon: String, label: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.uv.body(10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? Color.uv.gold : Color.uv.muted)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}

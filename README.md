# Ugin's Vault

A personal iOS app for tracking my Magic: The Gathering collection. Private build — not distributed via the App Store. Built as a learning vehicle for the Apple ecosystem and as a daily-driver tool for managing my own cards, decks, and sale lists.

> **Status:** v0.1 skeleton. Splash → Login → Home wired through Clean Architecture, with a Swift Testing target. Real data layer (SwiftData) and feature work (collection grid, dashboard, wishlist, scanner) come next.

---

## Table of contents

- [What the app does](#what-the-app-does)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Project layout](#project-layout)
- [Build + run](#build--run)
- [Testing](#testing)
- [Roadmap](#roadmap)
- [Decision log](#decision-log)
- [License](#license)

---

## What the app does

| Feature | Status | Notes |
|---|---|---|
| Splash · Login · Home shell | ✅ v0.1 | Phase router with cross-fade, Face ID, theme + currency prefs |
| Collection catalogue (cards, printings, finishes) | ⏳ next | Backed by SwiftData, sourced from Scryfall bulk dump |
| Stacks (deck · binder · loan · sale · showcase · inbox) | ⏳ next | Every card belongs to exactly one stack |
| Wishlist + price alerts | ⏳ later | On-device BGAppRefreshTask + `UNUserNotification`, no server |
| CSV import / export (ManaBox, Moxfield, Archidekt) | ⏳ later | One importer per source |
| Dashboard (sparklines, gainers/losers, value by format) | ⏳ later | Swift Charts |
| Camera-based card scanner | 🔮 v2 | AVFoundation + Vision + Scryfall match |
| CloudKit private-DB sync | 🔮 v2 | When the app outgrows a single device |

Out of scope: onboarding flows, social/sharing features, deck builder, analytics SDKs, crash reporters.

---

## Tech stack

| Layer | Pick | Why |
|---|---|---|
| Language | **Swift 6** | Strict concurrency adopted from day one — pain compounds if deferred |
| UI | **SwiftUI** with **Liquid Glass** | iOS 26 native visual language; UIKit only via `UIViewRepresentable` for the eventual camera scanner |
| Min iOS target | **iOS 26.0** | Personal-only deploy → no reason to compromise; unlocks Liquid Glass, mature `@Observable`, Swift Testing default, latest `CKSyncEngine` |
| State management | **`@Observable` macro** + `@State` (views) + `@Bindable` (two-way bindings) | Modern Apple-canonical pattern; no Combine, no `ObservableObject`, no `@Published` |
| Persistence (catalogue) | **SwiftData** | Native, Codable-friendly, schema migration story improves each release. Keep `CardRepository` behind a Domain protocol so the engine can be swapped if SwiftData hits a wall at our row counts |
| Persistence (session prefs) | **UserDefaults** via `SessionStorageDataSource` | Phase, theme, currency — small key/value |
| Auth | **`LocalAuthentication`** (Face ID + passcode fallback) | Local-only for v1. A `SignInWithApple` adapter slots into the existing `AuthRepository` protocol later |
| Networking | **`URLSession` + `async/await`** | No third-party HTTP client needed. Scryfall lives behind an `actor` with a 75 ms throttle |
| Card data ingestion | **Scryfall bulk JSON** (`oracle-cards.json`) + nightly `/cards/search` delta | Avoids hammering the per-card endpoint. MTGJson as a fallback if Scryfall rate-limits |
| Image cache | **Kingfisher** (SPM) | SwiftUI-first, disk + memory cache, prefetch; capped at ~1 GB with LRU eviction |
| Charts | **Swift Charts** | Native, iOS 16+; covers sparkline / pie / bar / line |
| CSV parsing | **CodableCSV** (SPM) | Handles quoted fields with commas (card names like "Borborygmos, Enraged") that break naïve splitters |
| Background tasks | **`BGAppRefreshTask`** (daily prices) + **`BGProcessingTask`** (monthly bulk refresh) | On-device only; iOS schedules opportunistically |
| Push | **Local `UNUserNotification`** | No APNs / server. Local notifications fired from background price-diff |
| Cloud sync (v2) | **CloudKit private DB** via `CKSyncEngine` | Free for personal use, native conflict resolution, no Firebase / Supabase needed |
| Testing | **Swift Testing** (`@Suite`, `@Test`, `#expect`) | Modern, parameterised, async-native |
| Project generation | **XcodeGen** | `project.yml` is the source of truth; `.xcodeproj` is regenerated reproducibly |
| Dependency manager | **Swift Package Manager** only | No CocoaPods, no Carthage |

---

## Architecture

Pragmatic Clean Architecture in three layers plus a composition root. The full spec is in [`ARCHITECTURE.md`](ARCHITECTURE.md); the short version:

```
Presentation ──► Domain ◄── Data
        ▲          ▲
        └──────────┴── Composition (knows everyone)
```

- **Domain** — pure Swift. Entities, repository protocols (`Observable`-conforming, no platform imports beyond `Foundation` + `Observation`), use cases.
- **Data** — concrete repository implementations (`@Observable`) backed by SwiftData / UserDefaults / `LAContext` / URLSession. DataSources sit one layer below repositories when a swappable infrastructure surface helps testing (e.g. `BiometricsDataSource`).
- **Presentation** — SwiftUI views + `@Observable` view models, organised per feature folder. Theme tokens + design-system primitives live alongside under `Presentation/`.
- **Composition** — `DependencyContainer.shared`. The only file that imports across all three layers. Exposes `make…UseCase()` and `make…ViewModel(…)` factories.

### Why these patterns

- **`@Observable` over `ObservableObject`** — the new canonical macro on iOS 17+. No publisher boilerplate, finer-grained tracking, no Combine import for VM state.
- **`@State` for VMs** — pairs with `@Observable` (the class is value-stable across renders; SwiftUI tracks property access).
- **Use case structs** — keep business logic out of repositories and out of view models. One execute method, easy to mock, easy to test.
- **Repositories own observability** — the protocol conforms to `Observable` so SwiftUI can react when implementations mutate (e.g. when the price refresher updates the in-memory card list).
- **Composition root** — no global service locators, no `@EnvironmentObject` spaghetti; every dependency is resolved at the boundary.

---

## Project layout

```
UginsVault/
├── App/                          # @main entry — builds the DI graph + mounts RootView
├── Composition/                  # DependencyContainer (the only file allowed to import across layers)
├── Domain/
│   ├── Entities/                 # AppPhase, AppTheme, AuthOutcome, Currency, …
│   ├── Repositories/             # Observable protocols (AuthRepository, SessionRepository, …)
│   └── UseCases/                 # AuthenticateUseCase, AdvanceFromSplashUseCase, …
├── Data/
│   ├── Repositories/             # @Observable concretions (LocalAuthRepository, UserDefaultsSessionRepository, …)
│   ├── DataSources/
│   │   ├── Protocols/            # BiometricsDataSource, SessionStorageDataSource, …
│   │   ├── Local/                # LAContext-backed, UserDefaults-backed
│   │   └── Remote/               # Scryfall + MTGJson clients land here
│   └── Seeding/                  # Bulk-JSON importers (Scryfall, future)
├── Presentation/
│   ├── Theme/                    # Colour tokens (Obsidian Vault palette), UVRadius, UVTypography, AppTheme bridge
│   ├── DesignSystem/             # UginMark, ShimmerBar, future shared primitives
│   ├── Shared/                   # Formatters + cross-feature helpers
│   └── Features/
│       ├── Root/                 # Phase router (Splash · Login · Home)
│       ├── Splash/               # Brand mark + auto-advance
│       ├── Login/                # Face ID prompt, dev-skip affordance
│       └── Home/                 # Collection placeholder + tab bar shell
├── Assets.xcassets/
└── Preview Content/

UginsVaultTests/                  # Swift Testing target (mirrors source structure)
project.yml                       # XcodeGen spec — source of truth for the Xcode project
ARCHITECTURE.md                   # Layering rules + per-layer expectations
CLAUDE.md                         # Agent guide for Claude Code
.claude/                          # Project-scoped Claude config (rules, agents, skills, commands)
```

---

## Build + run

### Requirements

- macOS 26.0+
- Xcode 26.0+ with the iOS 26 platform pack installed
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### One-time setup

```bash
git clone git@github.com:matiasmaddonni/ugins-vault.git
cd ugins-vault
xcodegen generate
open UginsVault.xcodeproj
```

### Build from the CLI

```bash
xcodebuild -project UginsVault.xcodeproj \
           -scheme UginsVault \
           -destination 'platform=iOS Simulator,name=iPhone 17' \
           -configuration Debug build
```

Or, inside Claude Code, the project-scoped `/build` command does the same thing.

### Regenerating after editing `project.yml`

```bash
xcodegen generate
```

Commit `project.yml` and the regenerated `UginsVault.xcodeproj/` together so the two stay in sync.

---

## Testing

[Swift Testing](https://developer.apple.com/xcode/swift-testing/) is the only framework used.

```bash
xcodebuild -project UginsVault.xcodeproj \
           -scheme UginsVault \
           -destination 'platform=iOS Simulator,name=iPhone 17' \
           test
```

- Suite per type under test: `@Suite("RootViewModel")`, etc.
- One file per class/struct under test, mirroring the source path.
- Protocol-based mocks in `UginsVaultTests/mocks/` keep test wiring explicit.
- Coverage gate: **≥ 90%** on changed files in Domain + Data; the Presentation target is best-effort.

---

## Roadmap

1. **v0.1 (current)** — Splash · Login · Home shell, DI wiring, Swift Testing target.
2. **v0.2 — Catalogue** — SwiftData schema for `Card` / `Printing` / `Finish`, Scryfall bulk import on first launch, basic collection list with search + filters.
3. **v0.3 — Stacks** — `Stack` entity (deck/binder/loan/sale/showcase/inbox), move-between-stacks UI.
4. **v0.4 — CSV** — ManaBox / Moxfield / Archidekt importers via `CodableCSV`, export for marketplace listings.
5. **v0.5 — Wishlist** — Add cards to wishlist with price targets; nightly background refresh; local notifications on drops.
6. **v0.6 — Dashboard** — Swift Charts (sparklines, gainers/losers, value by format).
7. **v1.0 — Polish** — App icon, animations pass, accessibility audit.
8. **v2.x — Beyond** — AVFoundation card scanner, CloudKit sync (multi-device), Sign in with Apple if the app ever leaves my hands.

---

## Decision log

Choices made during the stack discussion before any of v0.1's code was written. Re-record here when something material changes.

| Decision | Rationale |
|---|---|
| **iOS 26 minimum** | Personal deploy only; access to Liquid Glass + iOS 26 SwiftUI APIs is worth dropping back-compat |
| **Swift 6 strict concurrency from day one** | Cheaper to fix concurrency warnings on a small codebase now than on a sprawling one in 6 months |
| **SwiftUI only** | UIKit only for the eventual camera scanner via `UIViewRepresentable`. No hybrid navigation |
| **SwiftData over GRDB/Core Data** | Despite GRDB's better predicate story at 50k-row scale, SwiftData is the native long-term bet. Repository protocols isolate it — we can swap the engine without touching Domain or Presentation |
| **`@Observable` macro + `@State` for VMs** | Canonical on iOS 17+, no Combine boilerplate, finer-grained tracking |
| **Repository protocols are `Observable`** | SwiftUI reacts when implementations mutate (e.g. price refresher). Pulls `Observation` into Domain — acceptable trade-off; the alternative is plumbing publishers manually |
| **Composition root in `DependencyContainer.shared`** | Single place where layers meet. No service locators in feature code, no `@EnvironmentObject` for repositories |
| **DataSources optional below repositories** | Used when a repository talks to a platform surface that benefits from being mockable (LAContext, UserDefaults, URLSession). Skipped when SwiftData / Keychain access is direct enough |
| **No third-party HTTP client** | `URLSession` + `async/await` is enough. Scryfall throttle handled by an `actor` wrapper |
| **Bulk JSON over per-card API** | First-launch download of Scryfall `oracle-cards.json`, daily delta via `/cards/search?date=…` |
| **Kingfisher for image caching** | SwiftUI-native API, disk + memory cache, eviction, prefetch. ~25k card images × 100 KB = 2.5 GB worst case → cap at 1 GB LRU |
| **Swift Charts for dashboards** | Native, declarative, plays with SwiftUI. DGCharts only if we hit a chart type Swift Charts cannot do |
| **CodableCSV for imports** | Quoted fields + commas in card names break naïve parsers |
| **On-device push only** | No APNs, no Firebase. `BGAppRefreshTask` → diff prices → fire `UNUserNotification` |
| **CloudKit private DB for future sync** | Free for personal use, native to the platform, encrypted, conflict resolution built in |
| **Swift Testing, not XCTest** | New framework is the future; nicer ergonomics for parameterised + async tests |
| **XcodeGen** | `project.yml` is the source of truth — no manual `.pbxproj` edits, reproducible regen |
| **SPM only** | No CocoaPods, no Carthage |
| **Single Xcode target now** | Extract SPM packages later when Scryfall / image / CSV layers stabilise |
| **Folder layout: capitalised, Apple-style** | `App/`, `Composition/`, `Domain/`, `Data/`, `Presentation/` — see [`ARCHITECTURE.md`](ARCHITECTURE.md) |

---

## License

Personal project. All rights reserved. Not licensed for redistribution.

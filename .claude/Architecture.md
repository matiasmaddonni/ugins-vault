# Architecture — Concurrency & Isolation

Living rules + the refactor plan for the next architectural pass on UginsVault.
The goal: shrink `@MainActor` to where it is *structurally required* (SwiftUI
observability), push heavy work off main, keep the codebase easy to reason
about.

---

## Core principles

### 1. Default isolation is **nonisolated**

> "Hacé lo más que puedas non-isolated."

Free functions, value types, pure orchestration, mappers, parsers, networking
glue → all `nonisolated` / `Sendable`. No `@MainActor`, no `actor`, just code
that runs wherever the caller is.

`@MainActor` only when you genuinely need SwiftUI observability (state read
synchronously from a view body, mutations that trigger view re-render).

`actor` only when you have **shared mutable state** that requires
serialization. Not as a default tool for "running off main" — for that, just
let `await` schedule the call on the cooperative pool.

### 2. DB rule — actor **only** for shared mutable state

> "Para la DB solo usá actors para shared mutable state, para el resto no. Y
> cuando uses actors en la base de datos que cree un actor para esos casos de
> SharedMutableState."

SwiftData's `ModelContext` *is* shared mutable state (not thread-safe). It
deserves one dedicated actor that owns it. **Everything else** in the data
layer — mappers, DTOs, query builders, pure-fetch helpers — stays
`nonisolated`. Don't wrap every repo in an actor "just in case."

Concretely:
- One `@ModelActor`-backed coordinator per writeable context (e.g.
  `CatalogueWriter`, `CollectionWriter`). Owns its `ModelContext`.
- Read/write APIs of that actor return / accept **plain `Sendable` value
  types** (our domain entities already are — `Card`, `CollectionItem`,
  `Stack`, etc. are `Codable`/`Hashable` value types, not raw `@Model`
  objects). No `@Model` references leak out.
- Repository protocols that wrap these are themselves `nonisolated` +
  `Sendable`. Implementations choose actor vs. non-actor per their state.

### 3. Observable state lives in **state stores**, not in repositories

A repository that holds `@Observable` properties forces `@MainActor` on
itself + the entire chain of code that touches it. Today this is the root
cause of the "everything `@MainActor`" sprawl.

Target pattern — split each observable repo into two:

```
Today                                Target
─────────────────────────────────    ────────────────────────────────────────
@MainActor @Observable               ┌─ FooStateStore                 ─┐
protocol FooRepository {             │   @MainActor @Observable        │
  var x: X { get }   // sync read    │   class                          │
  func setX(_:) async                │   var x: X    ← views/VMs read │
}                                    └────────────────────┬─────────────┘
                                                          │ writes
                                     ┌────────────────────▼─────────────┐
                                     │ FooPersistence                   │
                                     │   actor / Sendable               │
                                     │   func load() / save(_:) async   │
                                     └──────────────────────────────────┘
```

- `FooStateStore` is `@MainActor @Observable`, owns the *in-memory* state
  views and VMs read.
- `FooPersistence` is `nonisolated`/`actor`, owns I/O (UserDefaults, Keychain,
  SwiftData, network). Has **no observable state**.
- A coordinator (or the store itself) wires writes through persistence and
  updates the store.

VMs continue to read `sessionStore.theme` exactly like they read
`sessionRepository.theme` today — but the store is the only `@MainActor`
piece in the chain.

### 4. Cross-VM shared state = one shared store via DI

When two VMs need to react to the same change (Settings flips currency,
Dashboard re-totals), they read the **same shared `FooStateStore`
instance** held by `DependencyContainer.shared`. No `NotificationCenter`, no
`AsyncStream` plumbing for the common case — SwiftUI observation handles
re-render automatically.

### 5. Use cases are **nonisolated** orchestration

A use case that only `await`s repo/persistence methods has no business being
`@MainActor`. It runs wherever called. If it needs to read sync state from
a store, take the value once at the call site instead.

### 6. Views, ViewModels, DI factories = `@MainActor` (correct)

SwiftUI requires main-thread updates. `@Observable` view models stay
`@MainActor`. Factory methods that construct `@MainActor` VMs stay
`@MainActor`. Don't fight this — it is not the problem.

---

## Refactor plan ("P-Big")

Move observable state out of repositories. Net target: ~60 % drop in
`@MainActor` count, plus a clean place to add background actors for heavy
work (P4 in the earlier audit).

### Per-protocol decisions

| Today | Becomes |
|---|---|
| `SessionRepository` | `SessionStateStore` + `SessionPersistence` (actor over `UserDefaults`) |
| `AccountRepository` | `AccountStateStore` + `AccountService` (actor over Supabase SDK) |
| `AuthRepository` | fold state into `AccountStateStore`; thin `LocalAuthentication` wrapper |
| `UserProfileRepository` | `ProfileStateStore` + `ProfilePersistence` (UserDefaults + `AvatarStorage` actor) |
| `ExchangeRateRepository` | `FXStateStore` + `FXFetcher` (actor) |
| `CardRepository` | `CardCatalogueService` only — drop `cards` (VMs own slices) + `isWriting` (→ `WriteCoordinator`) |
| `CollectionItemRepository` | service-only — drop `isWriting` |
| `StackRepository`, `PriceRepository`, `WishlistRepository` | service-only |
| `DashboardRepository` | service-only (snapshot already on VM) |

For SwiftData specifically — per Rule 2 — one `@ModelActor` coordinator owns
each writeable context (`CatalogueWriter`, `CollectionWriter`). The services
above sit on top of those actors; everything else in the data layer stays
`nonisolated`.

### Phases (each ends with build + tests green, committed)

| # | Name | Scope | Effort |
|---|---|---|---|
| **P-A** | **Data repos**: strip `Observable`/sync props from `Card`/`CollectionItem`/`Stack`/`Price`/`Wishlist` repositories. VMs already own loaded slices. Add `WriteCoordinator` for `isWriting`. | ~10 prod + tests | 1 day |
| **P-B** | **Session split** — `SessionStateStore` + `SessionPersistence`. Migrate every read of `sessionRepository.foo`. | wide | 1 day |
| **P-C** | **Account / Auth / Profile** split. Supabase calls move into `AccountService` actor. | 4–6 + tests | 0.5 day |
| **P-D** | **FX** split. | 3 files | 0.5 day |
| **P-E** | **Dashboard** — drop `@MainActor` / `Observable` (snapshot is on VM). | 2 files | 0.5 day |
| **P-F** | **Use-case sweep** — every UC that only awaits drops `@MainActor`. | ~24 files | 0.5 day |
| **P-G** | **Cleanup** — final `grep`, update this file, tighten test fixtures. | scattered | 1 day |

**Total: ~5 days** of mostly mechanical-but-careful work.

### Optional follow-on — P-DB (after P-A)

Introduce `@ModelActor` coordinators (`CatalogueWriter`, `CollectionWriter`)
that own writeable `ModelContext`s and serve heavy reads/writes. SwiftData
mainContext stays for tiny VM-bound queries. Per Rule 2, this is the **only**
new actor in the data layer.

---

## Risks + guardrails

| Risk | Mitigation |
|---|---|
| Views reading `DependencyContainer.shared.repo.x` directly | Per-phase grep: `grep -rn "DependencyContainer.shared\." UginsVault/Presentation`, migrate each. |
| Mocks break when protocol shape changes | Update mocks in the same commit as the protocol change. |
| `isWriting` consumers (Splash, Settings) lose indicator | `WriteCoordinator` (one `@MainActor @Observable` counting in-flight tasks) used by both. |
| SwiftData background context invalidates `@Model` objects | Actors return plain `Sendable` value types — domain entities already qualify, no bridging. |
| Re-render bugs from store identity drift | Stores are `final class` DI-shared singletons; never copy. |

## Acceptance criteria per phase

- Build green; 274+ tests green (or updated in the same commit).
- `@MainActor` count drops monotonically.
- On-device smoke: launch, Collection scroll, Stack open + Stats, Settings
  toggle, Sign out — no regressions.
- No view reads a repository directly — everything via a VM or state store.

## End-state estimate

- VMs (~14) + Views (~3) + DI (~1) + Scheduler bridge (~1) + StateStores
  (~6 new) + occasional `Task { @MainActor in … }` bridges (~2)
- **≈ 27 production files** legitimately `@MainActor`. Down from ~69.
  ~60 % reduction.
- New actors: ~1–2 SwiftData write coordinators + a handful of
  persistence/service actors (Account, FX, Avatar). Nothing else. Per
  Rule 2.

---

## What landed (P-A → P-F-rest)

Done over 4 commits in one session:

| Commit | Phase | Files | Hits |
|---|---|---|---|
| Start | — | 114 | 146 |
| `91a6a06` | **P-A** strip Observable+@MainActor from 5 data-repo protocols (Card/CollectionItem/Stack/Price/Wishlist); collapse `isWriting` / `cards` / `stacks` / `items` sync props. **P-F partial** deisolate 7 use cases (Add/HardReset/Import/LatestPrice/ResetCatalogue/Restore/Wishlist) + add explicit `Sendable`. | 102 | 133 |
| `5c5e952` | **P-B** delete `SessionRepository` protocol + `UserDefaultsSessionRepository` concrete + `MockSessionRepository`; new `SessionStateStore` (concrete `@MainActor @Observable`). | 102 | 135 |
| `b077c8c` | **P-C-mini + P-D** same collapse for `UserProfileRepository` → `UserProfileStore` and `ExchangeRateRepository` → `ExchangeRateStore`. | 101 | 136 |
| `a337db7` | **P-F-rest** delete 13 trivial Get/Set session/profile use cases (incl. `ManualARSRateUseCases`); VMs read/write the stores directly. Drop 14 DI factories + 14 SettingsViewModel init params. | **82** | **116** |

Net: **−32 files (−28 %), −30 hits (−21 %)**, 260 tests green throughout, no on-device regressions caught yet.

### Lessons learned, codified

1. **Inline trivial Get/Set use cases against a state store** — the
   architecture rule from CLAUDE.md says "views never access DataSources
   directly — always through Use Cases." That stands. But a one-line
   wrapper over a `@MainActor @Observable` *state store* is not a use
   case in the Clean-Architecture sense; it's a typing tax that drags
   `@MainActor` across the whole graph. Keep use cases for **business
   operations** (clear catalogue, sign in, import deck list). Reads /
   writes of pure preferences go straight to the store from the VM.

2. **Don't actor-ify just to leave the main thread** — for backings
   like `UserDefaults` (synchronous, microseconds) the actor split adds
   ceremony without perf. Per Rule 2: actor *only* for shared mutable
   state that genuinely needs serialization (the SwiftData
   `ModelContext` is the canonical example — see P-DB).

3. **Keep protocols where the I/O is real, drop them where they were
   just observability tax** — `AccountRepository` (Supabase) and
   `AuthRepository` (LocalAuthentication) stay, because mocking those
   gateways is the only sane way to test auth flows. `SessionRepository`
   / `UserProfileRepository` / `ExchangeRateRepository` /
   `CardRepository` / etc. existed mostly to expose Observable state —
   collapsed.

### Skipped

- **P-C full (AccountStateStore + AccountService)**: real I/O seam,
  heavy mock usage across 5+ tests — collapsing would be high churn for
  marginal `@MainActor` reduction. Left as-is.
- **P-E (DashboardRepository)**: user requested leave-as-is.
- **P-DB (`@ModelActor`)**: deferred until on-device perf calls for it.
  Triggers if SwiftData writes start hitching despite the P-A
  batched-save fixes.

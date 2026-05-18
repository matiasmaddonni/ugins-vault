# UginsVault · Architecture

A pragmatic Clean Architecture for a small SwiftUI iOS app. The goal isn't
ceremony — it's that **swapping the data source, retargeting the UI, or
unit-testing a use case shouldn't require touching files in any other
layer**.

---

## Layer overview

```
UginsVault/
├── App/                    ← entry point + RootView (composition wiring)
├── Composition/            ← DependencyContainer (the only place layers meet)
├── Domain/                 ← pure business logic — no UIKit/SwiftUI
│   ├── Entities/
│   ├── Repositories/       ← protocols only
│   └── UseCases/
├── Data/                   ← concrete repository implementations
│   ├── Repositories/       ← in-memory (later: SwiftData / CloudKit)
│   └── Seeding/
└── Presentation/           ← SwiftUI views + view models
    ├── Theme/              ← colour tokens + environment plumbing
    ├── DesignSystem/       ← reusable visual primitives
    ├── Shared/             ← Formatters, etc.
    └── Features/<Feature>/ ← one folder per screen group
```

### Dependency rules (strict)

```
Presentation ──► Domain ◄── Data
        ▲          ▲
        └──────────┴── Composition (knows everyone)
```

- **Domain** imports nothing from Data or Presentation.
- **Data** imports Domain (to implement its protocols) — never Presentation.
- **Presentation** imports Domain (to consume entities, protocols, use
  cases) — never Data.
- **Composition** is the only file allowed to import all three; it wires
  concrete Data implementations into the Domain protocols and exposes
  ready-to-use ViewModels to Presentation.

---

## Per-layer rules

### Domain

- **Entities** are plain Swift value types (`struct` / `enum`). Codable is
  fine; framework-specific imports (UIKit, SwiftUI, SwiftData) are not.
- **Repositories** are `protocol` declarations only. They conform to
  `Observable` so SwiftUI can react when implementations mutate.
- **UseCases** are small structs that take repositories via initializer
  and expose a single `execute` (or a few cohesive methods). They contain
  the rules — clamping, validation, aggregation — and stay synchronous
  unless the operation is genuinely asynchronous.

### Data

- One file per concrete repository.
- Implementations are marked `@Observable` so reads of their published
  state register dependencies in the SwiftUI observation graph.
- `Seeding/` contains demo/seed scripts that populate fresh repositories
  on first launch.

### Composition

- `DependencyContainer` is the **composition root** — the single place
  where concrete Data wires into Domain protocols.
- Two factories: `.live()` for the running app and `.preview()` for
  SwiftUI previews.
- Exposes ViewModel factories (`makeHomeViewModel()`, …) so Views never
  see repositories or use cases directly.

### Presentation

- **Theme** is a `struct` value type passed via `@Environment(\.uginsVaultTheme)`.
  Aurora (light) and Lagoon (dark) are derived from `colorScheme`.
- **DesignSystem** holds reusable visual primitives — one type per file,
  no business logic. Components read the theme from the environment.
- **Features** are organised by screen group, each containing:
  - `XViewModel.swift` — `@Observable` class taking dependencies via init.
  - `XView.swift` — SwiftUI view that initialises its VM through `@State`
    in `init(viewModel:)`.
  - `Components/` — sub-views used only by that feature.
- `Shared/Formatters.swift` holds display-only string formatters.

---

## ViewModel pattern

Every feature view follows the same shape:

```swift
struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        let vm = viewModel
        // ... use vm.someProperty
    }
}
```

The parent (usually `RootView`) constructs the VM via the container:

```swift
HomeView(viewModel: container.makeHomeViewModel())
```

When a VM needs two-way bindings (e.g. `Slider`, `Toggle`, `TextField`):

```swift
var body: some View {
    @Bindable var vm = viewModel
    Slider(value: $vm.goalMl, in: vm.minGoal...vm.maxGoal)
}
```

---

## Adding a new feature

1. **Domain** — add any new entity / repository protocol / use case.
2. **Data** — extend an existing repo or add a new in-memory implementation.
3. **Composition** — register the use case + a `makeXViewModel()` factory.
4. **Presentation/Features/X/** — create `XViewModel.swift` and
   `XView.swift`. Put feature-only sub-views in `Components/`.
5. **App/RootView.swift** — add the new tab or navigation entry.

If the feature has no business logic, you can skip the use case and have
the VM call the repository directly — but prefer use cases for anything
non-trivial so it stays unit-testable.

---

## Swapping the data source

The whole point of the layering is that switching from in-memory storage
to SwiftData (or anything else) only touches **Data** + **Composition**:

1. Add `SwiftDataWaterEntryRepository: WaterEntryRepository` in
   `Data/Repositories/`.
2. Change `DependencyContainer.live()` to instantiate it instead of
   `InMemoryWaterEntryRepository`.

Domain, Presentation, and every feature folder stay untouched.

---

## Testing strategy

- **Domain** is the easiest layer to test — entities, use cases and
  repository protocols can be covered with vanilla `XCTest` and a mock
  repository (a tiny `class MockWaterEntryRepository: WaterEntryRepository`).
- **ViewModels** can be tested by injecting mock use cases or repositories
  and asserting on their derived properties.
- **Views** stay snapshot-tested or visually verified — no business logic
  lives there, so they're cheap to keep working.

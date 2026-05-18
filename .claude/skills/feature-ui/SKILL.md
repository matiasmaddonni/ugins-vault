---
name: feature-ui
description: >
  Generates and develops the UI/Presentation layer of a feature for iOS 26 with SwiftUI.
  Applies Liquid Glass, uses the project's design tokens (Spacing, Layout, Typography, Asset Catalog colors),
  consults Figma when designs are available, and follows the project's view conventions.
  Consults official Apple documentation in real-time via apple-docs MCP.
  Use when you need to create or modify views, UI components, or work with Figma designs.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
argument-hint: "<FeatureName>"
---

# Feature UI — The UginsVault Project (iOS 26)

Create or modify the presentation layer (Views + ViewModel) of a feature, applying iOS 26, Liquid Glass, and the project's design system.

> **Fundamental rule.** This app targets **iOS 26 exclusively**. Always use the latest iOS 26 / WWDC 2025 APIs. Never use legacy or deprecated APIs when an iOS 26 replacement exists. Liquid Glass is the primary visual language.

## Source of truth (read these first)

This skill is the *workflow*. The *rules* live elsewhere — read them before generating code:

- [`.claude/rules/ui-design.md`](../../rules/ui-design.md) — Liquid Glass, design tokens, accessibility extraction, **dimensions extraction**, `Color(.token)` form
- [`.claude/rules/swift-conventions.md`](../../rules/swift-conventions.md) — naming, MARK, async/await, state management
- [`.claude/rules/apple-docs-ios26.md`](../../rules/apple-docs-ios26.md) — iOS 26 / WWDC 2025 filtering rules for the `apple-docs` MCP
- [`.claude/project-config.md`](../../project-config.md) — scheme, simulator, destination

## Step 0 — Apple docs queries (mandatory)

Apply the filtering rules from `.claude/rules/apple-docs-ios26.md`. At minimum run these initial queries when starting:

1. `search_wwdc_videos("Liquid Glass 2025")` → `get_wwdc_video_details`
2. `search_wwdc_videos("What's new in SwiftUI 2025")` → `get_wwdc_video_details`
3. The 5-step per-component flow from the rule for each key component you'll touch
4. `get_documentation_updates` filtered by SwiftUI to spot recent deprecations

## Step 1 — Figma (if designs exist)

Ask the user if there's a Figma design. If yes:

1. `mcp__claude_ai_Figma__get_design_context` for the design context
2. `mcp__claude_ai_Figma__get_metadata` for component metadata
3. Map Figma elements → native SwiftUI + design-system components
4. Faithfully respect layout, hierarchy, spacing, colors, and typography

## Step 2 — File structure

For a feature `<Feature>`, create in `UginsVault/feature/<featureLower>/`:

```
UginsVault/feature/<featureLower>/
├── ui/
│   ├── <Feature>View.swift                      # Main container
│   ├── <Feature>HeaderView.swift                # Header/hero (if applicable)
│   ├── <Feature>ContentView.swift               # Main content (if applicable)
│   ├── <Feature>ItemView.swift                  # List cells (if applicable)
│   └── <Feature>AccessibilityFields.swift       # Accessibility identifier constants (MANDATORY)
└── viewmodel/
    └── <Feature>ViewModel.swift                 # @MainActor ViewModel
```

Key rules:
- **No monolithic views.** A view's body must not exceed ~80 lines. Extract subviews.
- **Always create `<Feature>AccessibilityFields.swift` with the first view** — never inline identifier strings. See `.claude/rules/ui-design.md`, "Accessibility Identifier Extraction".

## Step 3 — Implementation

Apply the rules from `.claude/rules/ui-design.md`:
- **Liquid Glass first** — `GlassEffectContainer`, `.glassEffect()`, `.buttonStyle(.glassProminent)` / `.glass`, materials
- **Native components first** — `NavigationSplitView`, `List`, `Toggle`, etc.
- **Design tokens are mandatory** — `Spacing.*` / `Layout.*` for all dimensions; if missing, *add to `Spacing.swift` first*. No numeric literals in views except `0`.
- **Colors** — `Color(.tokenName)` (preferred) or existing `Color.<token>` extensions. `Color("name")` only for genuinely dynamic names.
- **Typography** — extensions from `UginsVault/ui/components/Typography.swift`
- **Accessibility** — every interactive view has an identifier from `<Feature>AccessibilityFields.swift`

### Available reusable components (check before creating new ones)

| Component        | File                                              | Usage                                           |
|------------------|---------------------------------------------------|-------------------------------------------------|
| `PrimaryButton`  | `UginsVault/ui/components/PrimaryButton.swift`        | Pill button, optional icon, en/dis/completed    |
| `TextInputField` | `UginsVault/ui/components/TextInputField.swift`       | Text input with validation                      |
| `TextAreaField`  | `UginsVault/ui/components/TextInputField.swift`       | Multiline textarea                              |
| `SearchField`    | `UginsVault/ui/components/TextInputField.swift`       | Search field with icon and clear                |

### NavigationSplitView pattern (screens with sidebar)

```swift
NavigationSplitView(columnVisibility: .constant(.all)) {
    SidebarView(viewModel: viewModel)
        .navigationSplitViewColumnWidth(Layout.sidebarWidth)
} detail: {
    DetailView(viewModel: viewModel)
        .backgroundExtensionEffect()
}
.navigationSplitViewStyle(.balanced)
```

### Previews

```swift
#if DEBUG
#Preview("Feature Name") {
    FeatureView(viewModel: PreviewViewModel())
}
#endif
```

## Step 4 — ViewModel

State-management pattern (`@Observable` vs `ObservableObject`) is decided in `.claude/rules/swift-conventions.md`. Follow that file — do not improvise.

Skeleton (substitute the macro/protocol per the rule):

```swift
import Foundation

// MARK: - <Feature>ViewModel

@MainActor
final class <Feature>ViewModel /* : ObservableObject or @Observable per swift-conventions */ {

    // MARK: - State
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies
    private let useCase: <Feature>UseCase

    // MARK: - Init
    init(useCase: <Feature>UseCase) {
        self.useCase = useCase
    }

    // MARK: - Public Methods
    // TODO
}
```

## Step 5 — Final checklist

Run before reporting done.

### iOS 26 filtering
- [ ] The 4 mandatory initial queries from `apple-docs-ios26.md` were run
- [ ] `get_platform_compatibility` was run for every API used
- [ ] No blocklisted APIs in the generated code (`NavigationView`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `ObservableObject` *if the rule deprecates it*, `.blur()` for glass, `.buttonStyle(.bordered)`, manual `Spacer()` in toolbars, `UIViewRepresentable` for web)
- [ ] Liquid Glass applied where appropriate; toolbars without manual styles
- [ ] WWDC 2025 sessions consulted for the main components

### Project design system — verified by greps
Run inside the feature folder. Any output from the first two = a violation:

```bash
FEATURE="<feature-folder>"

# 1. No literal accessibility identifier strings in views
grep -rn '\.accessibilityIdentifier("' "UginsVault/feature/$FEATURE/" \
  | grep -v "AccessibilityFields.swift"

# 2. No hardcoded numeric dimensions
grep -rnE '\.(frame|padding|offset|cornerRadius|shadow)\([^)]*\b[1-9][0-9]*\b' \
  "UginsVault/feature/$FEATURE/" | grep -vE '(Spacing|Layout)\.'

# 3. No legacy Color("...") for static names
grep -rnE 'Color\("[A-Za-z][A-Za-z0-9_]*"\)' "UginsVault/feature/$FEATURE/"
```

The first two are hard violations (fix before finishing). The third is acceptable only when the asset name is genuinely dynamic.

### Quality
- [ ] Body of each view ≤ ~80 lines (otherwise split into subviews)
- [ ] All fonts use Typography extensions
- [ ] Native SwiftUI components first (no unnecessary custom ones)
- [ ] `// MARK: -` to organize sections
- [ ] `#Preview` included
- [ ] If Figma was used: implementation matches the design

### Compile
- [ ] `/build` passes (project-config.md is the source for the command)

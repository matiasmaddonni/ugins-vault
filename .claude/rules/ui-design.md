# UI — Liquid Glass + Design System

## iOS 26 and Liquid Glass
- This app targets iOS 26 exclusively
- Liquid Glass is the primary visual language
- Use: `GlassEffectContainer`, `.glassEffect()`, `.buttonStyle(.glass())`, materials
- Toolbars apply Liquid Glass automatically — DO NOT add manual styles to toolbars

## Figma first
- If there's a Figma design, consult it BEFORE implementing
- Use Figma MCP: `get_design_context`, `get_metadata`, `get_screenshot`

## Native components first
- ALWAYS prioritize native SwiftUI components:
  - `NavigationSplitView`, `NavigationStack`
  - `List`, `Form`, `Grid`
  - `Toggle`, `Picker`, `Slider`
  - `Sheet`, `Alert`, `ConfirmationDialog`
- Create custom components only if no native equivalent exists

## Design Tokens (MANDATORY — never hardcode values)
- **Spacing**: `Spacing.xs`, `.sm`, `.md`, `.lg`, `.xl` (from `UginsVault/ui/components/Spacing.swift`)
- **Layout**: `Layout.*` for fixed dimensions (same file)
- **Typography**: fonts from extensions in `UginsVault/ui/components/Typography.swift`
- **Colors**: only from the Asset Catalog
- **Components**: `PrimaryButton`, `TextInputField`, `TextAreaField`, `SearchField`

## Dimensions Extraction (MANDATORY)

**Numeric literals for sizes are forbidden in feature views.** Anything that represents a width, height, padding, spacing, offset, corner radius, icon size, or any other dimensional value MUST come from the design-tokens file `UginsVault/ui/components/Spacing.swift`:

- General spacing/radius/shadow → `Spacing` struct (`Spacing.lg`, `Spacing.radiusCard`, `Spacing.Shadow.card`, etc.)
- Fixed component dimensions (sidebar width, button height, list item height, etc.) → `Layout` struct (`Layout.sidebarWidth`, `Layout.primaryButtonHeight`, etc.)

### Rules
- A view file MUST NOT contain a numeric literal in any of these modifiers/contexts: `.frame(width:height:)`, `.padding(...)`, `.offset(...)`, `.cornerRadius(...)`, `.spacing:` parameter of stacks/grids, `EdgeInsets(...)`, `.shadow(radius:x:y:)`, `.lineLimit` based on pixel sizing, fixed `width`/`height`/`maxWidth`/`maxHeight`/`minWidth`/`minHeight`. Exception: literal `0` is allowed.
- If a needed dimension does NOT exist yet in `Spacing` or `Layout`, **add it there first** with a descriptive name, then reference the constant from the view. Never inline the number "just for now".
- Naming: scalar in `Spacing` (semantic if reusable, e.g. `screenEdge`); component-specific dimension in `Layout` (e.g. `Layout.<componentName><Dimension>`).
- The same rule applies to ViewModels and any presentation-layer helper that emits a CGFloat used for layout — extract the constant.

```swift
// CORRECT
.frame(width: Layout.sidebarWidth)
.padding(.horizontal, Spacing.screenEdge)
VStack(spacing: Spacing.md) { ... }
.cornerRadius(Spacing.radiusCard)

// WRONG — literal numbers in a view
.frame(width: 320)
.padding(.horizontal, 16)
VStack(spacing: 12) { ... }
.cornerRadius(32)
```

## Asset Catalog Colors

**Always prefer the type-safe `Color(.tokenName)` form over the string-based `Color("tokenName")`.** Xcode synthesizes `ColorResource` symbols for every asset-catalog color, so the dot form is checked at compile time and renames safely. Use the string form ONLY when the color name is genuinely dynamic (built from a runtime variable) or when the asset comes from a source where the synthesized symbol isn't available.

```swift
// CORRECT — type-safe, preferred
Color(.bgPrimary)
Color(.textSecondary)
.foregroundStyle(Color(.brandPrimary))

// LEGACY — only when the name is dynamic
Color(name)                     // name: String resolved at runtime
Color("bgPrimary")              // avoid for static names — switch to Color(.bgPrimary)
```

Existing `Color.<token>` extensions (e.g. `Color.brandPrimary`, `Color.successPrimary`) are also fine and should be kept where they already exist.

### Available tokens
- Background: `bgPrimary`, `bgSecondary`, `bgTertiary`, `bgQuaternary`
- Text: `textPrimary`, `textSecondary`, `textOnLightPrimary`, `textOnDarkPrimary`
- Brand: `brandPrimary`, `brandEmphasis`, `brandSubtle`
- Status: `successPrimary/Emphasis/Subtle`, `infoPrimary/Emphasis/Subtle`, `warningPrimary/Emphasis/Subtle`, `destructivePrimary/Emphasis/Subtle`
- Fill: `fillPrimary`, `fillSecondary`
- Custom color → `TempColors.swift` and notify the dev to coordinate with UX

## View Structure
- A view's body MUST NOT exceed ~80 lines
- Fragment: header, body, footer, sections → separate files
- Views in `UginsVault/feature/<feature>/ui/`
- ViewModels in `UginsVault/feature/<feature>/viewmodel/`

## Accessibility
- Every interactive view MUST have an `accessibilityIdentifier`
- Prefix pattern: `btn_`, `lbl_`, `txt_`, `icn_`, `view_`, `scr_`, `cell_`, `seg_`, `mdl_`, `prg_`, `srch_`, `img_`, `map_`
- **Container + children rule (MANDATORY)**: When a container view (VStack, HStack, ZStack, Group, ScrollView, etc.) has `.accessibilityIdentifier()`, it MUST also have `.accessibilityElement(children: .contain)` **before** the identifier. Without this, SwiftUI collapses the accessibility tree and children lose their identifiers in XCUITest/Appium.
  ```swift
  // CORRECT
  .accessibilityElement(children: .contain)
  .accessibilityIdentifier(LoginAccessibilityFields.emailInput)

  // WRONG — children will be hidden
  .accessibilityIdentifier(LoginAccessibilityFields.emailInput)
  ```
- **Interactive elements**: Apply `.accessibilityIdentifier()` directly to the interactive control (TextField, SecureField, TextEditor, Button), NOT to a wrapper/container
- **ForEach + indexed identifier (MANDATORY)**: Any element rendered inside a `ForEach` (or any other repeating construct) MUST receive a unique, parameterized identifier. This applies to the row's outermost container AND every interactive child / labelled sub-element inside it. Without this, XCUITest/Appium cannot distinguish rows. Use a `static func ...(at index: Int) -> String` (or `(id:)`, `(suffix:)`) in `*AccessibilityFields.swift` and pass the index from the `ForEach` body down through the row view.
  ```swift
  // CORRECT — both the row wrapper and inner labels are indexed
  ForEach(Array(items.enumerated()), id: \.offset) { index, item in
      RowView(item: item, index: index)
          .accessibilityIdentifier(MyAccessibilityFields.rowButton(at: index))
  }
  // inside RowView:
  Text(item.name)
      .accessibilityIdentifier(MyAccessibilityFields.rowName(at: index))

  // WRONG — every row collapses to the same id
  ForEach(items) { item in
      RowView(item: item)
  }
  // inside RowView:
  Text(item.name)
      .accessibilityIdentifier(MyAccessibilityFields.rowName) // static let, duplicated across rows
  ```

## Accessibility Identifier Extraction (MANDATORY)

Every feature with views under `UginsVault/feature/<feature>/ui/` MUST extract its accessibility identifier strings into a single per-feature constants file. **Views NEVER contain literal identifier strings.**

### File
- Location: `UginsVault/feature/<feature>/ui/<Feature>AccessibilityFields.swift`
- One file per feature. Naming: `<FeatureCapitalized>AccessibilityFields` (e.g. `LoginAccessibilityFields`, `JoblistAccessibilityFields`, `TemplateDetailsAccessibilityFields`, `DataPointReadingSheetsAccessibilityFields`).
- Top-level `enum` (uninstantiable namespace), no cases. Use nested `enum`s to group identifiers by sub-component when the feature has many sub-views.

### Members
- `static let` for fixed identifiers: `static let signInButton = "btn_login_sign_in"`
- `static func` for dynamic identifiers — anything built from a parameter (index, label, enum value, prefix, conditional). Wrap the formatting **inside** the function so the call site stays a simple constant lookup.

### Example skeleton
```swift
import Foundation

/// Accessibility identifiers used across the Login feature views.
enum LoginAccessibilityFields {

    // MARK: - Static
    static let signInButton = "btn_login_sign_in"
    static let emailInput   = "view_login_email_input"

    // MARK: - Dynamic
    static func fieldLabel(_ label: String) -> String {
        "lbl_login_\(label.lowercased())"
    }
}
```

### Call site
```swift
// CORRECT — constant reference
.accessibilityIdentifier(LoginAccessibilityFields.signInButton)
.accessibilityIdentifier(LoginAccessibilityFields.fieldLabel(label))

// WRONG — literal strings or inline formatting
.accessibilityIdentifier("btn_login_sign_in")
.accessibilityIdentifier("lbl_login_\(label.lowercased())")
.accessibilityIdentifier(accessibilityId("btn", label))   // wrap inside the enum's static func instead
```

### Rules
- Feature view files (`UginsVault/feature/<feature>/ui/*.swift` and `UginsVault/feature/<feature>/protocol/*.swift`) MUST NOT contain any literal accessibility identifier string. Zero exceptions.
- The only place `accessibilityId(_:_:)` from `Spacing.swift` is allowed inside features is **inside the `*AccessibilityFields.swift` file itself** (or in shared components under `UginsVault/ui/components/` that build IDs from caller-supplied titles/placeholders).
- Helpers that take an `accessibilityId: String` / `identifier: String` parameter (e.g. `AttachmentOptionCard`, `ReasonDialog`'s `idPrefix`, `iconButton`) must receive the value from a constant or static func of the feature's `*AccessibilityFields`, never from an inline literal.
- New features MUST create the `*AccessibilityFields.swift` file together with the first view — do not defer.

# Swift Code Conventions

## Naming
- `camelCase` for properties and methods
- `PascalCase` for types (struct, class, enum, protocol)
- Descriptive names, no unnecessary abbreviations

## File Organization
- Use `// MARK: -` to separate logical sections
- Suggested order: properties, init, public methods, private methods, extensions

## Documentation
- DocC comments (`///`) on all public APIs
- Include `- Parameter`, `- Returns`, `- Throws` where applicable

## Concurrency
- Prefer `async/await` over callbacks and Combine
- Use Combine only when a continuous reactive stream is needed
- ViewModels: always `@MainActor`

## ViewModel state — `ObservableObject` is the project default

The codebase mixes patterns; **the canonical default for new ViewModels is `ObservableObject` + `@Published`** to stay consistent with the majority of existing code. The iOS 26 `@Observable` macro is allowed *only* in features that already use it, or with explicit team coordination.

```swift
@MainActor
final class FooViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
}
```

Do NOT mix `@Observable` and `ObservableObject` within the same feature. If a feature already uses one, follow that one.

## General
- Prefer `struct` over `class` when possible
- Use `guard` for early returns
- Avoid force unwrapping (`!`) — use `guard let` or `if let`
- Avoid force casting (`as!`) — use `as?` with error handling

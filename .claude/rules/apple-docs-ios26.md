# Apple-docs MCP — iOS 26 / WWDC 2025 filtering

This app targets **iOS 26 exclusively**. Every query to the `apple-docs` MCP must be filtered through these rules to avoid drifting into legacy APIs.

## Rule 1 — Always include "iOS 26" or "WWDC 2025" in searches

```
✅ search_apple_docs("GlassEffectContainer SwiftUI iOS 26")
✅ search_apple_docs("TabView SwiftUI iOS 26")
✅ search_wwdc_videos("Liquid Glass 2025")
❌ search_apple_docs("TabView SwiftUI")            ← may return iOS 15-17 docs
❌ search_apple_docs("navigation SwiftUI")          ← may return NavigationView (deprecated)
```

## Rule 2 — Validate the minimum version of every result

After each search, run `get_platform_compatibility`:
- `iOS 26+` or `iOS 18+` → ✅ use it
- `Deprecated` → ❌ reject, search the replacement with `find_similar_apis`
- Only `iOS 13-17` and an iOS 26 alternative exists → ❌ reject
- No iOS 26 alternative exists → ✅ use the existing API (it wasn't replaced)

## Rule 3 — MCP source priority

1. **WWDC 2025 sessions** (`search_wwdc_videos` filtered by year 2025)
2. **Documentation updates** (`get_documentation_updates`)
3. **Sample code** (`get_sample_code` filtered by iOS 26)
4. **General docs** (`search_apple_docs`) — only as fallback

## Rule 4 — Liquid Glass first, always

For every visual decision, search for a Liquid Glass equivalent first:

| Need                      | Search                              | Result                       |
|---------------------------|-------------------------------------|------------------------------|
| Floating card             | `glassEffect card iOS 26`           | `GlassEffectContainer`       |
| Prominent button          | `buttonStyle glass iOS 26`          | `.buttonStyle(.glassProminent)` |
| Toolbar                   | (don't search — automatic in iOS 26)| no manual styles             |
| Blur / translucency       | `glassEffect iOS 26`                | `.glassEffect()` (NEVER `.blur()`) |
| Blurred background        | `backgroundExtensionEffect iOS 26`  | `.backgroundExtensionEffect()` |

## Rule 5 — Legacy API blocklist (NEVER use, even if the MCP returns them)

| Legacy API                                              | iOS 26 replacement                    |
|---------------------------------------------------------|---------------------------------------|
| `NavigationView`                                        | `NavigationStack` / `NavigationSplitView` |
| `UIViewRepresentable` for web                           | native `WebView` / `WebPage`          |
| `.blur()` + `.opacity()` for glass                      | `.glassEffect()`                      |
| `.buttonStyle(.bordered)` / `.borderedProminent`        | `.buttonStyle(.glass)` / `.glassProminent` |
| `Spacer()` inside toolbar items                         | `ToolbarSpacer()`                     |
| `UIWebView` / `WKWebView` wrappers                      | native SwiftUI `WebView`              |
| `.background(Color.clear)` + blur                       | materials (`.ultraThinMaterial`, …)   |
| `UIHostingController` for simple views                  | direct SwiftUI view                   |

State management — pre-Observable patterns are also legacy. See `.claude/rules/swift-conventions.md` for which one is canonical for *new code*.

If the MCP returns a snippet using any of the above, ignore that result and re-search for the iOS 26 replacement.

## Rule 6 — Cross-validate with WWDC 2025

When the MCP returns docs for an API:
1. `get_apple_doc_content(API)`
2. `search_wwdc_videos("API 2025")`
3. If a 2025 session exists → `get_wwdc_video_details` and use the updated pattern
4. If not → use the docs as-is

## Mandatory query flow per component/API

```
1. search_apple_docs("<component> SwiftUI iOS 26")
2. get_platform_compatibility(<found API>)
   - deprecated?  → find_similar_apis  → restart with replacement
   - blocklisted? → restart with replacement
3. search_wwdc_videos("<component> 2025")
   - found?       → get_wwdc_video_details and extract pattern
4. get_apple_doc_content(<validated API>)
5. Liquid Glass equivalent? Yes → use glass. No → use the iOS 26 standard API.
```

## Mandatory initial queries when starting a feature

1. `search_wwdc_videos("Liquid Glass 2025")` → `get_wwdc_video_details`
2. `search_wwdc_videos("What's new in SwiftUI 2025")` → `get_wwdc_video_details`
3. The 5-step flow above for each key component
4. `get_documentation_updates` filtered by SwiftUI to see recent deprecations

## Available `apple-docs` MCP tools (with iOS 26 filter)

| Tool                           | Filter                                          |
|--------------------------------|-------------------------------------------------|
| `search_apple_docs`            | always add "iOS 26" or "SwiftUI 2025"           |
| `get_apple_doc_content`        | verify minimum version                          |
| `search_framework_symbols`     | filter results by iOS 26+ availability          |
| `get_platform_compatibility`   | **mandatory** after each search                 |
| `get_related_apis`             | prefer most recent relationships                |
| `find_similar_apis`            | use when a deprecated API is found              |
| `get_documentation_updates`    | filter by iOS 26 / WWDC 2025                    |
| `get_sample_code`              | prefer iOS 26+ samples                          |
| `search_wwdc_videos`           | always filter by 2025 first                     |
| `get_wwdc_video_details`       | prioritize WWDC 2025 sessions                   |
| `get_technology_overviews`     | verify iOS 26 coverage                          |

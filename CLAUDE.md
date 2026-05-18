# CLAUDE.md — UginsVault

Quick reference guide for the Claude agent when working on this project.

## Project

iOS 26 mobile app built with **Swift + SwiftUI** following **Clean Architecture**. Focus on scalability, testability, and maintainability. UI with **Liquid Glass** as the primary visual language.

## Stack

- **Swift / SwiftUI** — Declarative UI with Liquid Glass (iOS 26)
- **Combine** — Reactive state
- **Swift Concurrency** — async/await
- **Swift Data** — Local persistence

## Architecture

Clean Architecture in 3 layers. Detailed rules in `.claude/rules/architecture.md`.

```
Presentation (Views + ViewModels)
        ↓
Domain (Use Cases — pure Swift, no external dependencies)
        ↓
Data (Repositories + Data Sources: Remote / Local)
```

- **ViewModels**: `@Published`, `@MainActor`, in `UginsVault/feature/<feature>/viewmodel/`
- **Views**: SwiftUI, in `UginsVault/feature/<feature>/ui/`
- **Use Cases**: Business logic, no frameworks, in `UginsVault/domain/useCases/`
- **Repository Protocols**: in `UginsVault/domain/repositoryProtocol/`
- **Repositories**: Implementations in `UginsVault/data/repositories/`
- **Data Sources**: Protocols in `UginsVault/data/datasources/protocols/`, implementations in `remote/` and `local/`
- **DI**: Singleton container with factory methods in `UginsVault/di/DependencyContainer.swift`

## Xcode Project

Authoritative source: [.claude/project-config.md](.claude/project-config.md). When scheme, target, simulator, or destination changes, update **only** that file — every skill and agent references it.

## Key Commands

| Action | How |
|---|---|
| Build | `/build` (canonical command in `.claude/project-config.md`) |
| Tests + coverage | `/test` (enforces ≥90% coverage on changed files) |
| Open project | `open UginsVault.xcodeproj` |

## Available Skills

Skills defined in `.claude/skills/`. Use them as appropriate:

| Skill | When to use |
|---|---|
| `/build` | After significant changes, automatically compile to verify there are no errors |
| `/test` | Before committing, or when you need to verify tests pass. Accepts argument: `/test TestName` |
| `/review` | To validate that code follows Clean Architecture, conventions, and UI rules |
| `/feature-ui <Name>` | To create or develop the UI/Presentation layer of a feature (Views + ViewModel, Liquid Glass, Figma, design tokens) |
| `/foundation <Name>` | To create or develop the Domain + Data layers of a feature (UseCase, Repository, DataSource, DI, Tests) |
| `/pr-check` | Before creating a PR, runs the complete checklist (build + tests + review) |

## Specialized Agents

Agents defined in `.claude/agents/`. Claude can invoke them as subagents with isolated context:

| Agent | When to use |
|---|---|
| `code-reviewer` | For code review: architecture, performance, coverage, design system |
| `ui-builder` | For implementing SwiftUI screens with Liquid Glass and design tokens |
| `test-writer` | For generating or completing unit tests maintaining coverage ≥ 90% |

## Workflow

### Creating a new feature (full flow)

1. **`/foundation <Name>`** — First: create UseCase, Repository, DataSource, DI, and tests for the Domain + Data layers
2. **`/feature-ui <Name>`** — Then: create Views and ViewModel using design tokens, Liquid Glass, and consulting Figma if there's a design
3. **`/build`** — Verify it compiles without errors
4. **`/test`** — Verify tests pass with coverage ≥ 90%
5. **`/review`** — Validate architecture, conventions, and UI rules

### Modifying existing code

1. Make the necessary changes
2. **`/build`** — Automatically compile (without asking permission) after significant changes
3. **`/test`** — Before committing, verify tests and coverage

### Before creating a PR

1. **`/pr-check`** — Runs the complete checklist (build + tests + review + branch status)

## Detailed Rules

Rules are automatically loaded based on the context of the file being edited. They are in `.claude/rules/`:

| Rule | Applies to | Content |
|---|---|---|
| `architecture.md` | `UginsVault/**/*.swift` | Clean Architecture, layer separation, DI |
| `swift-conventions.md` | `**/*.swift` | Naming, MARK, DocC, async/await, guard |
| `ui-design.md` | `UginsVault/feature/*/ui/**`, `UginsVault/ui/**` | Liquid Glass, design tokens, colors, accessibility |
| `testing.md` | `UginsVaultTests/**/*.swift` | Swift Testing, mocks, coverage ≥ 90%, per-layer strategy |
| `git-workflow.md` | Always | Branches, commits, pre-commit, pre-PR |

## Automatic Hooks

Configured in `.claude/settings.json`:

- **File protection**: Before each Edit/Write, a hook verifies that critical files are not touched (`project.pbxproj`, `Podfile.lock`, `Package.resolved`, `.env`, secrets)
- **Notifications**: macOS alert when Claude is waiting for user input

## Requirements

- Xcode 26.0+
- iOS 26+
- macOS 26.0+

## Notes for Claude

- Respect layer separation: never import UI frameworks in Domain
- Prefer `async/await` over callbacks or Combine unless the context requires it
- Every new feature must include unit tests in all 3 layers (use `/foundation` for Domain+Data, `/feature-ui` for Presentation)
- Repositories must always be defined as a protocol first
- **Build after major changes**: use `/build` automatically (without asking permission) after each significant change
- **Pre-commit check**: use `/test` before each commit to verify that coverage remains ≥ 90% in affected classes. If coverage dropped, add missing tests before committing
- **Pre-PR check**: use `/pr-check` before creating a Pull Request
- **Subagents**: for intensive review, UI, or testing tasks, consider using specialized agents to keep the main context clean

---

## App context — Ugin's Vault

> Merged from the iOS skeleton brief. **Domain-only** context. Engineering decisions (iOS target, state layering, UI language) keep the rules defined above — skeleton's conflicting choices on those topics are intentionally not carried over.

### What this app is

A **personal iOS app** for managing a Magic: The Gathering collection. The user is a collector-seller who plays paper Magic, tracks values, and lists cards on Cardmarket-style marketplaces. The app is **private — not App Store distributed**. Single user, no accounts, no cloud.

### Domain vocabulary

- **Stack**: any physical pile of cards. Kinds: `deck`, `binder`, `loan`, `sale`, `showcase`, `inbox`. Each card has a `container` field referring to a stack id.
- **Wishlist**: not a tab — reachable from Dashboard and Settings.
- **Currency**: configurable per user. Default USD. Other supported: EUR, ARS. User is Argentinian.

### Auth

- **Face ID** via `LocalAuthentication`. Passcode fallback. "Skip (dev)" link kept for simulator builds.

### External integrations

- **Scryfall API** for card data (free, no key) — `URLSession + Codable`.

### Screens — current scope

#### 1. Splash
- Centered brand mark + "Ugin's Vault" wordmark + thin loading shimmer
- Auto-advance to Login after 1.5 s
- Matches active color scheme (dark/light)

#### 2. Login
- Brand mark (small) + "Ugin's Vault" title
- Big Face ID button
- "Use PIN" fallback link (placeholder)
- "Skip (dev)" link for non-bio builds + simulator
- On success → home

#### 3. Home (Collection placeholder)
- Top: large title "Collection"
- Sub-line: card count · total value
- Search bar (non-functional in skeleton)
- Empty state copy + "Add card" affordance
- Bottom: skeleton tab bar with 4 tabs (Collection · Stacks · Dashboard · Settings) + center "+" FAB

The rest of the app (Card Detail, Add Card, Dashboard, Stacks, Settings) is **out of the current scope**. Follow `Ugins Vault.html` (when present) for design fidelity when adding them.

### Out of scope (don't add without asking)

- Onboarding flow (single-user app)
- Social / sharing features
- Camera scanner (will come later)
- Deck builder
- Analytics SDKs, crash reporters


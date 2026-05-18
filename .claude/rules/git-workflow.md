# Git Workflow

## Branches
- Base branch for PRs: `develop`
- Naming convention: `feature/uv-<number>-<description-with-dashes>`
- Example: `feature/uv-2-Add-About-View`

## Branch Flow (one-way promotion)

```
feature/* → develop → qa
```

- Feature branches are merged into `develop` via PR.
- `develop` is merged into `qa` via PR to promote a stable snapshot for QA validation.
- **Never** open a PR from `qa` into `develop`. `qa` is a downstream target, not a source.
- Hotfixes discovered on `qa` must be fixed on a new `feature/*` branch off `develop`, then promoted forward again.

## Pre-commit
- Run `/test` to verify tests pass and coverage ≥ 90%
- If coverage dropped, add missing tests BEFORE committing

## Pre-PR
- Run `/pr-check` for the complete checklist:
  - Build without errors
  - Tests passing with coverage ≥ 90%
  - Architecture review
  - Branch status (up-to-date with develop)

## Commits
- Descriptive messages in English
- Format: type + concise description
- Example: `feat: add schematic zoom and pan component`

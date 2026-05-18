---
name: review
description: >
  Reviews project code against Clean Architecture rules, Swift/SwiftUI conventions,
  and the rules defined in CLAUDE.md. Use for code review of changes, validating architecture,
  or verifying that code follows project conventions.
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Bash, Agent
argument-hint: "[file-or-feature]"
---

# Review — The UginsVault Project

Thin wrapper that delegates to the `code-reviewer` agent with isolated context. The agent already loads the project rules and runs the deterministic guard greps — do **not** restate them here.

## Scope

- If `$ARGUMENTS` is a file or feature, review only that.
- Otherwise, review the diff against `develop`:

```bash
git diff --name-only develop...HEAD
```

## Action

Invoke the `code-reviewer` agent (`subagent_type=code-reviewer`) with this brief:

> Review the diff between `develop` and `HEAD` (or the scoped target from `$ARGUMENTS`). Apply every rule in `.claude/rules/` and every guard grep listed in `.claude/agents/code-reviewer.md`. Report findings in the agent's standard `Critical / Warning / Suggestion` format with file:line. Be concise.

When the agent returns:
1. Show the agent's findings to the user verbatim — do not paraphrase.
2. If `$ARGUMENTS` was provided, scope the agent's report to that subset.
3. End with a single-sentence summary: counts of Critical / Warning / Suggestion.

## Notes

- All review rules and guard greps live in [`.claude/agents/code-reviewer.md`](../../agents/code-reviewer.md) and the files under [`.claude/rules/`](../../rules/). This skill is operational only — it does not duplicate them.
- For the full pre-PR pipeline (build + test + review + branch checks), run `/pr-check` instead.

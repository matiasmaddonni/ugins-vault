---
name: pr-check
description: >
  Runs the complete pre-PR checklist (build, tests, accessibility/dimensions/color guards,
  code review, marker file) by delegating to the `pr-checker` agent. The agent runs on Opus
  in a clean isolated context with maximum reasoning effort.
disable-model-invocation: false
allowed-tools: Agent
---

# PR Check — The UginsVault Project

This skill runs the full pre-PR checklist via a dedicated subagent so the work happens in a clean context, on Opus, with maximum reasoning effort. The main conversation is not used to execute the checklist.

## What to do

Invoke the `pr-checker` agent with the Agent tool. Do NOT execute any of the checklist steps inline — the agent owns every step (branch status, build, tests + coverage, accessibility/dimensions/color guards, code review, marker file, final report).

Use exactly these parameters:

- `subagent_type`: `pr-checker`
- `model`: `opus`
- `description`: `Pre-PR checklist`
- `prompt`: see template below

### Prompt template

```
ultrathink

Run the complete pre-PR checklist for The UginsVault Project end-to-end, following every step
in your agent definition (Steps 1–9). Apply maximum reasoning effort at every decision
point — especially the regression-vs-pre-existing-bug evaluation in Step 7 and the
marker-file gate in Step 8.

Constraints:
- You run in a clean isolated context. Gather everything you need from the repo; do
  not assume state from any prior conversation.
- Do not skip steps. Do not soften blocking conditions.
- Do not create the marker file unless Steps 2, 3, 4, 5, and 7 all pass.
- Return the final summary in the exact format from Step 9 of your agent definition,
  followed by a clear YES / NO verdict.
```

## After the agent returns

- Relay the agent's final summary to the user verbatim (or a tight paraphrase if it is very long).
- If the verdict is **YES**: tell the user that `gh pr create` is now enabled for 30 minutes and offer to create the PR.
- If the verdict is **NO**: list exactly what must be fixed and tell them to re-run `/pr-check` afterwards.

## Notes

- The marker file (`/tmp/uginsvault-pr-ready-<branch-with-dashes>`) is created by the agent, not by this skill. The PreToolUse hook for `gh pr create` reads it from `/tmp` so it works regardless of which context wrote it.
- If the user explicitly asks for a faster/cheaper run (e.g. "just do the checklist on sonnet"), override `model` accordingly when invoking the agent — but the default is always opus + ultrathink.

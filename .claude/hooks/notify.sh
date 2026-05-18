#!/bin/bash
# Notification hook: only fires a macOS notification when Claude is actually
# waiting for user input (permission prompts, idle prompts), not on every event.

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
TYPE=$(echo "$INPUT" | jq -r '.type // empty' 2>/dev/null)
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"' 2>/dev/null)
MSG=$(echo "$INPUT" | jq -r '.message // ""' 2>/dev/null)

# Heuristic: only notify when Claude is waiting for the user.
# Claude Code emits notifications with messages mentioning "permission",
# "waiting", or "idle" when it actually needs attention.
case "$MSG" in
  *permission*|*Permission*|*waiting*|*Waiting*|*idle*|*Idle*) ;;
  *) exit 0 ;;
esac

osascript -e "display notification \"$MSG\" with title \"$TITLE\"" 2>/dev/null || true

exit 0

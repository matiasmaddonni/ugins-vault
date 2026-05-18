#!/bin/bash
# Hook: Blocks `gh pr create` unless /pr-check has been run successfully
# Runs as PreToolUse on Bash commands

# C-2 fix: Guard against missing jq
if ! command -v jq &>/dev/null; then
  echo "Warning: jq not installed, pre-pr-check hook cannot run." >&2
  exit 0
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only intercept commands that actually invoke gh pr create (not mentions in strings)
# Match: starts with "gh pr create" or after a command separator (&& ; |)
if ! echo "$COMMAND" | grep -qE '(^|&&|;|\|)\s*gh\s+pr\s+create'; then
  exit 0
fi

# C-1 fix: Resolve repo root dynamically for any CWD
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  exit 0
fi

# Check for the marker file (branch-specific)
BRANCH=$(git branch --show-current 2>/dev/null)
if [ -z "$BRANCH" ]; then
  echo "Cannot determine current branch (detached HEAD?)." >&2
  exit 2
fi
MARKER="/tmp/uginsvault-pr-ready-$(echo "$BRANCH" | tr '/' '-')"

if [ -f "$MARKER" ]; then
  # C-3 fix: Cross-platform marker age check (macOS + Linux)
  NOW=$(date +%s)
  if stat -f %m "$MARKER" &>/dev/null; then
    MARKER_TIME=$(stat -f %m "$MARKER")
  elif stat -c %Y "$MARKER" &>/dev/null; then
    MARKER_TIME=$(stat -c %Y "$MARKER")
  else
    MARKER_TIME=0
  fi
  MARKER_AGE=$(( NOW - MARKER_TIME ))
  if [ "$MARKER_AGE" -lt 1800 ]; then
    exit 0
  fi
  rm -f "$MARKER"
fi

echo "PR creation blocked: /pr-check has not been run on this branch." >&2
echo "Run /pr-check first to verify build, tests, and code review." >&2
echo "Critical issues must be resolved before creating a PR." >&2
exit 2

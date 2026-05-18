#!/bin/bash
# PostToolUse hook: auto-fix Swift files with swiftlint after Edit/Write.
# Skips silently if swiftlint is not installed or the file is not Swift.

set -e

# Guard: jq required for parsing the hook payload
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# Guard: swiftlint optional. Skip silently if missing.
if ! command -v swiftlint >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null)

[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

# Only Swift files
case "$FILE" in
  *.swift) ;;
  *) exit 0 ;;
esac

# Run swiftlint --fix on the single file. Quiet to avoid spamming the transcript.
# Use a 10s timeout in case the lint config does something heavy.
( timeout 10 swiftlint lint --fix --quiet --path "$FILE" >/dev/null 2>&1 ) || true

exit 0

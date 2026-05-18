---
name: test
description: >
  Runs the iOS project tests and verifies coverage. Use when you need to run tests,
  verify that tests pass, or check that coverage is >= 90% in affected classes.
  Also used before committing changes.
disable-model-invocation: false
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "[specific-test-name]"
---

# Test — The UginsVault Project

Run tests and verify coverage. Project identifiers come from `.claude/project-config.md` — do not inline them here.

## Step 1 — Run tests

### All tests (`$ARGUMENTS` empty)

```bash
rm -rf /tmp/uginsvault-test-results /tmp/uginsvault-test-results.xcresult
xcodebuild test \
  -project UginsVault.xcodeproj \
  -scheme "UginsVault" \
  -destination 'platform=iOS Simulator,name=iPad Air 11-inch (M4)' \
  -only-testing:UginsVaultTests \
  -enableCodeCoverage YES \
  -resultBundlePath /tmp/uginsvault-test-results \
  2>&1 | tail -80
```

### Specific suite (e.g. `/test LoginViewModelTests`)

```bash
xcodebuild test \
  -project UginsVault.xcodeproj \
  -scheme "UginsVault" \
  -destination 'platform=iOS Simulator,name=iPad Air 11-inch (M4)' \
  -only-testing:UginsVaultTests/$ARGUMENTS \
  -enableCodeCoverage YES \
  -resultBundlePath /tmp/uginsvault-test-results \
  2>&1 | tail -80
```

## Step 2 — Analyze pass/fail

- Report pass/fail counts.
- If there are failed tests: list each with file, line, error message; read the test to propose a fix.

## Step 3 — Coverage check (≥ 90% on changed classes)

This step actually verifies coverage — it does NOT just trust the build output.

1. **Resolve the `.xcresult` path.** xcodebuild appends `.xcresult` to the bundle path:

```bash
RESULT="/tmp/uginsvault-test-results.xcresult"
[ ! -d "$RESULT" ] && RESULT="/tmp/uginsvault-test-results"   # fallback for older toolchains
```

2. **Get coverage JSON for every Swift file:**

```bash
xcrun xccov view --report --json "$RESULT" > /tmp/uginsvault-coverage.json
```

3. **Identify changed files in the diff against `develop`:**

```bash
git diff --name-only --diff-filter=AM develop...HEAD -- 'UginsVault/**/*.swift' > /tmp/uginsvault-changed.txt
```

4. **Compute per-file line coverage and flag any changed file under 90%:**

```bash
python3 - <<'PY'
import json, os, sys
with open('/tmp/uginsvault-coverage.json') as f:
    report = json.load(f)
with open('/tmp/uginsvault-changed.txt') as f:
    changed = {os.path.basename(line.strip()) for line in f if line.strip()}

violations = []
for target in report.get('targets', []):
    for file_entry in target.get('files', []):
        name = os.path.basename(file_entry.get('name', ''))
        if name not in changed:
            continue
        cov = file_entry.get('lineCoverage', 0.0)
        if cov < 0.90:
            violations.append((name, cov))

if violations:
    print("Coverage below 90% on changed files:")
    for name, cov in sorted(violations):
        print(f"  - {name}: {cov*100:.1f}%")
    sys.exit(1)
else:
    print("Coverage >= 90% on all changed files.")
PY
```

5. **If the python script exits non-zero**: report the under-covered files, identify the uncovered paths (`xcrun xccov view --report --files-for-target UginsVaultTests "$RESULT" | grep <FileName>`), and suggest the missing tests. Do NOT silently continue.

> If the test run skipped coverage (`-enableCodeCoverage NO` or scheme had it disabled), `xccov` will return empty — re-run Step 1.

## Step 4 — Report

Output a small table:

| Tests   | Coverage check | Notes |
|---------|----------------|-------|
| X / Y   | PASS / FAIL    | …     |

## Notes

- Test target: `UginsVaultTests`. Mocks live in `UginsVaultTests/data/` or alongside their tests.
- Framework: Swift Testing (`@Test`, `@Suite`, `#expect`) — see `.claude/rules/testing.md`.
- Project identifiers in `.claude/project-config.md`.
- Pre-commit (CLAUDE.md): always run `/test` and ensure Step 3 passes.

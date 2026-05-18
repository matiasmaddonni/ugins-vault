# Project Config — The UginsVault Project

**Single source of truth for project-level identifiers.** When any of these change, update this file ONLY — every skill, agent, and rule should reference it instead of restating the values.

## Identifiers

| Field             | Value                                              |
|-------------------|----------------------------------------------------|
| Project file      | `UginsVault.xcodeproj`                                |
| Scheme            | `UginsVault`                                      |
| App target        | `UginsVault`                                      |
| Test target       | `UginsVaultTests`                                     |
| Simulator         | `iPhone 17 Pro`                            |
| Destination       | `platform=iOS Simulator,name=iPhone 17 Pro`|
| Result bundle     | `/tmp/uginsvault-test-results`                        |
| Min coverage      | 90% on classes touched by the diff                 |
| Base branch (PRs) | `develop`                                          |
| Branch convention | `feature/uv-<number>-<description-with-dashes>`   |

## Canonical commands

**Build:**
```bash
xcodebuild build \
  -project UginsVault.xcodeproj \
  -scheme "UginsVault" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -quiet
```

**All tests (with coverage enabled and result bundle):**
```bash
rm -rf /tmp/uginsvault-test-results
xcodebuild test \
  -project UginsVault.xcodeproj \
  -scheme "UginsVault" \
  -destination 'platform=iOS Simulator,name=iPad Air 11-inch (M4)' \
  -only-testing:UginsVaultTests \
  -enableCodeCoverage YES \
  -resultBundlePath /tmp/uginsvault-test-results \
  2>&1 | tail -80
```

**Single test (replace `<TestSuite>`):**
```bash
xcodebuild test \
  -project UginsVault.xcodeproj \
  -scheme "UginsVault" \
  -destination 'platform=iOS Simulator,name=iPad Air 11-inch (M4)' \
  -only-testing:UginsVaultTests/<TestSuite> \
  2>&1 | tail -80
```

**Coverage report (after a test run with `-resultBundlePath`):**
```bash
xcrun xccov view --report --json /tmp/uginsvault-test-results.xcresult
```

## Notes

- Xcode 26.0+, iOS 26+, macOS 26.0+
- If the scheme is not found: `xcodebuild -list -project UginsVault.xcodeproj`
- If the simulator is not available: `xcrun simctl list devices available 'iPad Air 11-inch'`

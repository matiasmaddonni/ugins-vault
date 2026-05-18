---
description: Regenerate UginsVault.xcodeproj from project.yml via XcodeGen, then verify the project still builds.
---

1. Run `xcodegen generate`.
2. Run `xcodebuild -project UginsVault.xcodeproj -scheme UginsVault -destination 'generic/platform=iOS Simulator' -configuration Debug build`.
3. Report: regenerated project path + build status. If build fails, paste first error.

Do not commit. User stages and commits manually.

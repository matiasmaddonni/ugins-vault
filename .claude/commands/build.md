---
description: Build UginsVault for the iOS Simulator (Debug). Reports build status and surfaces the first error if it fails.
---

Run the following and report the result:

```bash
xcodebuild -project UginsVault.xcodeproj -scheme UginsVault -destination 'generic/platform=iOS Simulator' -configuration Debug build
```

If the build succeeds, reply with `BUILD SUCCEEDED` plus elapsed time.
If the build fails, paste the first compiler error block (file:line + message) and stop — do not attempt a fix unless the user asks.

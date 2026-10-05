# Development verification

Checked on October 5, 2026, on Apple Silicon macOS with Jac **0.37.23**.

- The web, server, mobile, CLI, and two helper scripts passed Jac's full type checks.
- `jac run` from the repository root served the web interface and colocated planning API.
- The API/CLI integration test passed both in the working directory and in a clean source copy under `/tmp/studyline-fresh-check`, without copied dependencies or build artifacts. The clean copy was installed with `jac install --npm` and started using the default `jac run` command.
- Validation rejected blank titles, invalid dates, invalid priorities, out-of-range time estimates, and oversized notes without creating tasks.
- CLI creation, Today filtering, API edits visible in the CLI, completion, repeat completion, reopening, deletion, and missing IDs passed.
- Browser checks covered web task creation, course filters, search, and selecting a deadline in the week strip.
- A web-created task was completed through the mobile browser screen and confirmed as completed by the CLI. A mobile-created task appeared on the web.
- Those two tasks and their completion states survived a server restart. Only the temporary test tasks were removed afterward.
- The actual mobUI screen built with `jac build mobile --platform web`, ran through `scripts/mobile_preview.jac`, and was verified at phone size. The browser captured no runtime errors in either interface.
- `jac setup mobile` created the Expo scaffold; `scripts/configure_mobile.jac` successfully set its app name, app IDs, and backend URL.

Screenshots of the sample week are in `docs/web.jpg` and `docs/mobile.jpg`. Sample data is optional and does not ship as a prepopulated database; a different checkout starts empty.

## Verification limit

The mobile UI was exercised through **React Native Web**, not on a physical device or simulator. No iOS simulator runtime was available. Android APK / iOS app builds and native-device interactions remain unverified. Follow the README's native prerequisites and configuration steps before testing on a device. The repository contains genuine Jac mobUI source and an Expo setup workflow, rather than a responsive web page presented as a native mobile app.

No GitHub repository was created or published during development; the source is ready to push to the student's repository.

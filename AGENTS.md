# AGENTS.md

## Start here

Before modifying files:

1. Read `docs/project-rules.md`.
2. Read the current Issue in `issues/`.
3. Read only the documents listed under that Issue's `Required Documents`.
4. Inspect the existing implementation and tests.
5. Confirm that the requested change is within the Issue's `Allowed Changes`.

Implement one Issue at a time.

## Source of truth

Use this priority order:

1. Current Issue
2. `docs/project-rules.md`
3. Documents listed in the Issue
4. Existing code and tests

If these conflict, do not invent a new specification. Report the conflict and its impact.

## Architecture constraints

* Views must not access repositories or SwiftData directly.
* ViewModels must call UseCases.
* Domain must not import SwiftData, CoreLocation, CoreMotion, PhotoKit, MapKit, UIKit, or AVFoundation.
* Platform services must not write directly to SwiftData.
* Processing components must remain independent from UI, SwiftData, and Apple platform APIs.
* Use initializer injection.
* Do not create custom singletons or service locators.

## Product constraints

Do not add unless explicitly required by the current Issue:

* Continuous high-accuracy GPS
* Server communication
* Login
* iCloud synchronization
* Analytics or advertising SDKs
* AI image analysis
* Settings screen
* Tab bar
* iPad or landscape support
* Third-party production dependencies

Do not delete assets from Apple Photos.

## Coding constraints

* Use Swift Concurrency.
* Do not add `fatalError()`, `try!`, `as!`, unnecessary force unwraps, or `print()`.
* Do not log coordinates, routes, media identifiers, or media filenames.
* Do not leave required functionality as TODO.
* Do not modify unrelated files.
* Do not reformat unrelated code.
* Do not edit signing settings unless the Issue explicitly requires it.

## Verification

Before reporting completion, run the commands required by the Issue.

When available, use:

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
```

Do not claim that a command succeeded unless it was actually executed successfully.

## Completion report

Report:

* Summary
* Changed files and reasons
* Tests added
* Build result
* Test result
* SwiftLint result
* SwiftFormat result
* Manual verification
* Deviations
* Unresolved issues

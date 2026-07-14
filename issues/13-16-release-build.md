# [Release] Release Buildを確認する

## Summary

Release configurationをclean buildし、Source由来Warningを解消してiOS 17 deployment向けApp bundleを生成する。

## Required Documents

- [x] `docs/architecture.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-16-release-build.md`
- `DriveLog/DriveLog/Shared/Errors/PermissionKind.swift`
- `DriveLog/DriveLog/Domain/Repositories/RawEventRepository.swift`
- `DriveLog/DriveLog/Platform/Location/LocationProviding.swift`
- `DriveLog/DriveLog/Platform/Motion/MotionProviding.swift`
- `DriveLog/DriveLog/Platform/Visit/VisitProviding.swift`
- `DriveLog/DriveLog/Platform/Photos/PhotoLibraryProvider.swift`
- `DriveLog/DriveLog/Features/DayDetail/MediaGridSection.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLogTests/TestSupport/FakeLocationProvider.swift`
- `DriveLog/DriveLogTests/TestSupport/FakeMotionProvider.swift`
- `DriveLog/DriveLogTests/TestSupport/FakeVisitProvider.swift`
- `DriveLog/DriveLogTests/Application/RawEventStorageCoordinatorTests.swift`
- `DriveLog/DriveLogTests/Application/StartMonitoringUseCaseTests.swift`

### Forbidden Changes

- Signing、Team、Bundle Identifier、Deployment Target、Build Configurationの変更

## Requirements

1. Release clean buildをSimulator向け署名なしで実行する。
2. Default MainActorにより誤って隔離されたSendable domain/platform契約をnonisolatedにする。
3. async thumbnail closureをSendableとして明示する。
4. Source由来Warningを0にする。
5. 全Test、Lint、Format、Diff Checkを成功させる。

## Acceptance Criteria

- [x] Release clean buildが成功する。
- [x] Source由来Warningがない。
- [x] 全Testと静的検査が成功する。
- [x] Signing等の禁止設定に変更がない。

## Decision / Deviations

- AppIntents framework未使用によるmetadata extraction skippedはXcode環境WarningとしてSource Warningと分離する。
- OS providerの操作はMainActorに維持し、event streamだけをnonisolated契約とした。Domain event/valueのEquatableはnonisolatedとした。
- Test Doubleは未同期可変状態を避けるためMainActor classへ統一し、関連SuiteもMainActorで実行する。
- Release clean build、Debug build、全Test（失敗0）、SwiftLint、SwiftFormat、Diff Checkが成功した。

## Files Expected to Change

- Allowed Changes記載の14ファイルのみ。

## Completion Report Format

- Summary
- Changed files and reasons
- Tests added
- Build result
- Test result
- SwiftLint result
- SwiftFormat result
- Manual verification
- Deviations
- Unresolved issues

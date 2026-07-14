# [Audit] Production Lifecycle依存を配線する

## Summary

実装済みのLocation/Motion/Visit収集、Raw保存、日別処理、BGTaskをProduction Appのlaunch/foreground/background lifecycleへ接続する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/interfaces.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/audit-1-production-lifecycle-wiring.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLogTests/Application/AppContainerTests.swift`

### Forbidden Changes

- Provider、Repository、Processing algorithm、Schema、Signing、Capabilityの変更

## Requirements

1. AppContainerでProduction provider、raw repository/storage、processor/coordinatorを同一ModelContainerから構築する。
2. BGTask launch handlerをBackgroundTaskCoordinatorへ接続する。
3. App launchでregister、permission refresh、monitoring、pending processingを開始する。
4. Foregroundで権限とmonitoringをrefreshする。
5. Backgroundで外部電源必須BGTaskをscheduleする。
6. UI TestのIn-Memory containerでも依存構築可能にする。
7. UI TestではProductionの位置・モーション・Visit監視を起動しない。

## Acceptance Criteria

- [x] Production dependency graphをAppContainerから生成できる。
- [x] Scene lifecycleが3 lifecycle methodを呼ぶ。
- [x] App起動、Build、全Test、Lint、Format、Diff Checkが成功する。
- [x] 新規Source Warningと仕様外変更がない。

## Decision / Deviations

- SwiftUI `scenePhase`をApp lifecycle境界に使用し、ViewからRepositoryへ直接アクセスしない。
- BGTask実行は既存BackgroundTaskCoordinatorへ委譲する。
- UI Testではlifecycleを生成せず、OS Providerによる監視と権限UIを隔離する。

## Files Expected to Change

- Allowed Changes記載の4ファイルのみ。

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

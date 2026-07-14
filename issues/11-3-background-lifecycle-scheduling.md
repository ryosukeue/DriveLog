# [Application] Background移行時予約を接続する

## Summary

AppLifecycleCoordinatorへBackgroundTaskSchedulingを注入し、launch時登録とbackground移行時予約を接続する。

## Background

Schedulerと実行Handlerは実装済みだが、Application lifecycleから呼ばれていない。OS予約失敗時もForeground fallbackを維持する必要がある。

## Goal

launchで1回登録し、background移行ごとに処理Taskを予約するLifecycle動作を実装する。

## Non-Goals

- DriveLogAppのscenePhase接続とproduction DI
- 外部電源条件の最終設定
- handler処理内容の変更

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 11-1 BackgroundTaskScheduling
- AppLifecycleCoordinator

## Scope

### Allowed Changes

- `issues/11-3-background-lifecycle-scheduling.md`
- `DriveLog/DriveLog/Application/AppLifecycleCoordinator.swift`
- `DriveLog/DriveLogTests/Application/AppLifecycleCoordinatorTests.swift`
- `DriveLog/DriveLog/Application/BackgroundTasks/BackgroundTaskCoordinator.swift`

### Forbidden Changes

- AppContainer、DriveLogApp、scenePhase変更
- Platform Scheduler、BackgroundTaskCoordinator変更
- Monitoring停止、Repository、Schema、UI変更
- Project設定、外部Package、Signing変更

## Requirements

1. BackgroundTaskSchedulingをInitializer Injectionする。
2. handleLaunchでregisterProcessingTaskを1回試行する。
3. handleBackgroundでscheduleProcessingTaskを1回試行する。
4. 登録・予約失敗をLifecycle外へthrowしない。
5. 登録失敗でも権限更新、監視開始、Foreground pending処理を継続する。
6. 予約失敗でもSLC等の監視を停止しない。
7. handleForegroundでは重複登録・予約しない。
8. 本Issueでは予約条件をfalseで接続し、11-4で外部電源必須へ切り替える。

## Privacy Requirements

- ログ、個人情報、外部通信を追加しない。

## Acceptance Criteria

- [x] launch登録とbackground予約が各1回行われる。
- [x] foreground fallbackが維持される。
- [x] Scheduler失敗が他Lifecycle処理を妨げない。
- [x] Unit Testが成功する。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- launch/foreground/background呼出回数と条件。
- 登録・予約失敗時のfallback継続。

## Decision / Deviations

- 登録・予約はbest effortとし、失敗を無視して必須のForeground fallbackを継続する。
- 11-2 helperのDefault MainActor推論WarningをTarget再Buildで検出したため、lock-backed stateを明示的に`nonisolated`化する修正を同梱する。
- 2026-07-14にUnit Test 370件、UI Test 10件が成功した。新規Warningは解消済みである。

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

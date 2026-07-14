# [Application] BGTask実行Handlerを実装する

## Summary

OSから渡されたBackgroundProcessingTaskを受け、pending日を上限付きで処理し、expiration時に安全に中断するApplication Coordinatorを実装する。

## Background

Platformの登録・予約基盤は実装済みである。OSタスクのlifecycleをDayProcessingCoordinatorへ橋渡しするApplication境界が必要である。

## Goal

Background taskごとにpending日処理を1 batch実行し、成功またはexpirationをOS抽象へ正確に通知する。

## Non-Goals

- App launch/background lifecycleへの登録・予約接続
- 外部電源条件の選択
- 実機BGTask実行確認

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 11-1 BackgroundTaskScheduling
- DayProcessingCoordinating

## Scope

### Allowed Changes

- `issues/11-2-background-task-handler.md`
- `DriveLog/DriveLog/Application/BackgroundTasks/BackgroundTaskCoordinator.swift`

### Forbidden Changes

- AppLifecycleCoordinator、AppContainer、DriveLogApp変更
- Platform Scheduler、DayProcessingCoordinator変更
- Repository、Schema、UI変更
- Project設定、外部Package、Signing変更

## Requirements

1. `BackgroundTaskCoordinating: Sendable`を定義する。
2. handlerは同期Callbackから安全にasync batchを開始する。
3. `DayProcessingCoordinating.processPendingDays(limit:)`を指定上限で1回呼ぶ。
4. 既定上限は3日とする。
5. expiration handlerを処理開始前に設定する。
6. expiration時に`cancelCurrentProcessing()`を呼ぶ。
7. 通常完了は`setTaskCompleted(success: true)`を1回呼ぶ。
8. expiration後の完了は`success: false`を1回呼ぶ。
9. task completionはどの経路でも重複通知しない。
10. OS Frameworkをimportしない。

## Privacy Requirements

- ログ、座標、経路、メディア識別子、外部通信を追加しない。

## Interface Contract

```swift
protocol BackgroundTaskCoordinating: Sendable {
    func handle(task: any BackgroundProcessingTask)
}
```

## Implementation Constraints

- Swift Concurrencyとlock-backed expiration stateを使用する。
- `fatalError()`、force cast、force unwrapを追加しない。
- 未完成TODO、新規Warningを追加しない。

## Acceptance Criteria

- [x] pending日を既定上限3件で処理する。
- [x] 通常完了とexpiration完了が正しく通知される。
- [x] expirationで処理Coordinatorをcancelする。
- [x] completionが重複しない。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- 詳細なhandler Unit Testは実装計画11-6で追加する。

## Decision / Deviations

- 日数上限は設計で定数未指定のため、Foreground fallbackの1日より多く、OS実行時間を占有しすぎない保守的な3日を採用する。
- expirationはlock-backed stateへ記録してからasync cancellationを開始し、batch復帰時のcompletionを必ずfailureにする。
- 2026-07-14にUnit Test 369件、UI Test 10件が成功した。handler詳細Testは計画どおり11-6で追加する。

## Files Expected to Change

- Allowed Changes記載の2ファイルのみ。

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

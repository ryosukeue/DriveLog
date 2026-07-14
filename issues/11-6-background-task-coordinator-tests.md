# [Test] BGTask Coordinator Unit Testを追加する

## Summary

BackgroundTaskCoordinatorの上限処理、通常完了、expiration cancellation、競合安全性をOS非依存Fakeで検証する。

## Background

11-2〜11-5でhandlerとexpiration stateを実装した。OS実行時刻に依存しないApplication契約をUnit Testで固定する。

## Goal

Background task lifecycleの主要分岐とexactly-once completionを決定的に検証する。

## Non-Goals

- BGTaskScheduler実機起動
- Repository、Processing pipeline integration
- Lifecycle scheduling再テスト

## Required Documents

- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 11-5 expiration safety

## Scope

### Allowed Changes

- `issues/11-6-background-task-coordinator-tests.md`
- `DriveLog/DriveLogTests/Application/BackgroundTaskCoordinatorTests.swift`

### Forbidden Changes

- Production code、Project設定、外部Package変更

## Requirements

1. 既定pending limit 3を検証する。
2. custom limit伝播を検証する。
3. 通常完了がsuccess trueを1回通知することを検証する。
4. expirationがcancelCurrentProcessingを1回呼ぶことを検証する。
5. expiration後の完了がsuccess falseを1回通知することを検証する。
6. 完了後expirationがcancelしないことを検証する。
7. 固定sleepを使用せず、yieldと明示Gateで同期する。
8. Swift Testingを使用する。

## Acceptance Criteria

- [x] 全4 lifecycle Testが決定的に成功する。
- [x] completionとcancelの回数・順序を確認する。
- [x] Production変更がない。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- Fake taskはlock-backed、processing coordinatorはactor-backedとし、Sendable未同期状態を作らない。
- 2026-07-14にUnit Test 374件、UI Test 10件が成功した。

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

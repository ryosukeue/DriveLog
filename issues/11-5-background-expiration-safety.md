# [Application] Expiration時の安全な中断を実装する

## Summary

BGTaskの通常完了とexpirationが競合しても、処理取消とOS完了通知を一貫させるlifecycle stateを実装する。

## Background

expiration cancellationは11-2で接続済みだが、通常完了直後に遅延expirationが届く場合の不要なcancelを明示的に防ぐ必要がある。

## Goal

active、expired、completedの一方向状態遷移で、expirationとcompletionをexactly-onceとして扱う。

## Non-Goals

- DayProcessing pipelineやRepository transactionの変更
- Scheduler、Lifecycle、UI変更
- BGTask実機確認

## Required Documents

- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 11-2 BackgroundTaskCoordinator
- DayProcessingCoordinator cancellation

## Scope

### Allowed Changes

- `issues/11-5-background-expiration-safety.md`
- `DriveLog/DriveLog/Application/BackgroundTasks/BackgroundTaskCoordinator.swift`

### Forbidden Changes

- Scheduler、Lifecycle、DayProcessing Coordinator、Repository変更
- Project設定、外部Package、Signing変更

## Requirements

1. stateをactive、expired、completedで管理する。
2. activeからの最初のexpirationだけがtrueを返す。
3. expiration handlerはtrueの場合だけ処理取消を開始する。
4. active完了はsuccess trueを返してcompletedへ遷移する。
5. expired完了はsuccess falseを返してcompletedへ遷移する。
6. completed後のexpirationは処理取消を開始しない。
7. OS完了通知はbatch Taskから1回だけ行う。
8. lock外でasync処理を開始する。

## Acceptance Criteria

- [x] expiration/通常完了競合が一方向状態遷移で解決される。
- [x] 完了後expirationがcancelを発生させない。
- [x] expired batchはfailure完了する。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- 詳細な競合Unit Testは実装計画11-6で追加する。

## Decision / Deviations

- OS completion自体は既存どおりbatch Taskだけが所有し、stateはsuccess値とcancel可否だけを決定する。
- 2026-07-14にUnit Test 370件、UI Test 10件が成功した。

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

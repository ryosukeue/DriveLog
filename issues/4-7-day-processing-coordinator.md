# [Application] DayProcessingCoordinatorを実装する

## Summary

ユーザー表示日と未処理日を優先度・件数上限付きで日別処理へ渡し、実行中処理をキャンセルできるCoordinatorを実装する。

## Goal

日別処理の入口、再試行、キャンセルを一つのApplication境界へ集約する。

## Non-Goals

- BGTask登録、Foreground lifecycle接続、UI状態、再試行回数制限

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/4-7-day-processing-coordinator.md`
- `DriveLog/DriveLog/Application/Processing/DayProcessingGate.swift`
- `DriveLog/DriveLog/Application/Processing/DayProcessingCoordinator.swift`
- `DriveLog/DriveLogTests/Application/DayProcessingGateTests.swift`
- `DriveLog/DriveLogTests/Application/DayProcessingCoordinatorTests.swift`

### Forbidden Changes

- ProcessDayUseCase、Repository実装、Processing、Platform、UI、Project設定

## Requirements

1. `DayProcessingCoordinating: Sendable`を設計どおり定義する。
2. `processIfNeeded`は指定日とpriorityを二重処理防止ゲートへ渡す。
3. `processPendingDays`はRepositoryが返す古い順のキーを正のlimit件まで処理する。
4. pending日はbackground priorityで順次処理し、個別失敗で残りを停止しない。
5. failed日はRepositoryのpendingDateKeysに含まれるため次回再試行する。
6. `cancelCurrentProcessing`は実行中ゲートTaskをキャンセルし、処理中Batchを終了する。
7. GateをProtocol化してCoordinator Testでpriorityとキャンセルを観測可能にする。
8. キャンセルがoperationへ伝播することを実Gateでも確認する。

## Acceptance Criteria

- [x] 指定日と3段階priorityをゲートへ渡せる。
- [x] pending日をlimit件だけ古い順に処理する。
- [x] limit 0以下では処理しない。
- [x] 個別失敗後も次の日を処理する。
- [x] キャンセルが実行Taskへ伝播し、Batchが次日へ進まない。
- [x] 同日要求は既存Gateにより1回へ合流する。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Definition of Done

- [x] Acceptance Criteria、Allowed Changes、全検証を満たす。

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
### Manual Verification
### Deviations
### Unresolved Issues

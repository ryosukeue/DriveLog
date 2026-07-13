# [Application] 日別二重処理防止を実装する

## Summary

同じ日への同時処理要求を1つのTaskへ合流させ、異なる日は独立して処理できるActorゲートを実装する。

## Goal

日別派生データの二重生成・二重保存をApplication層で防止する。

## Non-Goals

- pending日の選択、キュー順序、件数上限、全体キャンセル、BGTask

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

- `issues/4-6-day-processing-gate.md`
- `DriveLog/DriveLog/Application/Processing/DayProcessingGate.swift`
- `DriveLog/DriveLogTests/Application/DayProcessingGateTests.swift`

### Forbidden Changes

- ProcessDayUseCase、Repository、Processing、Platform、UI、Project設定

## Requirements

1. `ProcessingPriority`を設計どおりbackground、normal、userVisibleで定義する。
2. Actorが日付キーごとに実行中Taskを保持する。
3. 同じ日の同時要求は同じ結果または同じErrorを受け取り、operationを1回だけ実行する。
4. 異なる日付は互いをブロックせず実行できる。
5. 完了・失敗後はEntryを除去し、同じ日を再実行できる。
6. 古い待機呼出の復帰で新しいEntryを削除しないよう実行IDを照合する。
7. priorityをTaskPriorityへ保守的に写像する。

## Acceptance Criteria

- [x] 同日同時要求でoperationが1回だけ実行される。
- [x] 同日の全呼出元が同じ結果を受け取る。
- [x] 別日を同時実行できる。
- [x] 成功後と失敗後に再実行できる。
- [x] 3段階の優先度順とTaskPriority写像が正しい。
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

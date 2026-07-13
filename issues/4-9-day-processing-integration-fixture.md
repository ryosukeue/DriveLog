# [Test] 日別処理統合Fixtureを追加する

## Summary

in-memory SwiftData上でRaw Event保存から日別処理、派生データ取得、世代更新までを通す統合Fixtureを追加する。

## Goal

Phase 4の日別処理が各層を跨いで設計どおり連携することを証明する。

## Non-Goals

- Production実装変更、性能測定、BGTask、UI

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/4-9-day-processing-integration-fixture.md`
- `DriveLog/DriveLogTests/Integration/DayProcessingIntegrationTests.swift`

### Forbidden Changes

- Production Swift、Schema／Model、Project設定、外部Package

## Requirements

1. V1 Schemaのin-memory ModelContainerを使用する。
2. 実際のRaw、State、Override、Derived RepositoryとDefaultProcessDayUseCaseを接続する。
3. 徒歩Motionを含むRaw EventからwalkingLike区間と有効日を保存する。
4. 車Motionを含むRaw Eventからautomotive区間を保存する。
5. 長い停止を含むRaw EventからStayを保存する。
6. localDateKeyごとのRaw取得と派生保存が別日へ干渉しないことを確認する。
7. 処理後のRaw追加でrawRevisionが増え、再処理後にprocessedRevisionが追随することを確認する。
8. Overrideが処理後もRepositoryに維持されることを確認する。
9. キャンセル時に派生データを保存せずfailed状態へ遷移することを確認する。
10. 固定Clockを使い、待ち時間に依存しない。

## Acceptance Criteria

- [x] 徒歩、車、滞在Fixtureが期待する派生データを保存する。
- [x] 日付境界で別日のデータが混入しない。
- [x] rawRevision変更後に再処理され、世代が一致する。
- [x] Overrideが再処理後も残る。
- [x] cancellationで派生データが確定しない。
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

# [UI] DayDetailViewModelを実装する

## Summary

Day Detailの日付別読込、表示データ、再集計、空、Error状態を管理するViewModelを追加する。

## Goal

ViewがUseCaseやRepositoryの詳細を知らずにDay Detail状態を描画できるようにする。

## Non-Goals

- View、Map Preview、削除、Media操作

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 6-1、6-2

## Scope

### Allowed Changes

- `issues/6-3-day-detail-view-model.md`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailViewModel.swift`
- `DriveLog/DriveLogTests/Features/DayDetailViewModelTests.swift`

### Forbidden Changes

- UseCase、Repository、MapScene、View、SwiftData、Project設定、外部Package

## Requirements

1. `@MainActor @Observable`のViewModelとSendableな状態Enumを追加する。
2. 日付キーと`LoadDayDetailUseCase`をInitializer Injectionする。
3. idle、loading、loaded、empty、errorを管理する。
4. `DriveLogError.invalidData`と無効移動Aggregateを空状態にする。
5. `isReprocessing`を取得データから公開する。
6. 再読込失敗時は既存データを破棄しない。
7. 競合する古いRequest結果を反映しない。

## Acceptance Criteria

- [x] 成功、再集計、空、Error、再試行をテストする。
- [x] ViewModelからRepository／SwiftDataを参照しない。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
### Manual Verification
### Deviations
### Unresolved Issues

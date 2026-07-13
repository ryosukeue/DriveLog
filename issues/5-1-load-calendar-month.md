# [Application] LoadCalendarMonthUseCaseを実装する

## Summary

指定月のDayAggregateをCalendar表示用データへ変換するUseCaseを実装する。

## Goal

CalendarFeatureがSwiftDataやRaw Eventへ依存せず月別移動日を取得できるようにする。

## Non-Goals

- Calendar UI／ViewModel、未処理日の実行、日別詳細遷移

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/5-1-load-calendar-month.md`
- `DriveLog/DriveLog/Domain/Entities/CalendarDayData.swift`
- `DriveLog/DriveLog/Domain/Entities/CalendarMonthData.swift`
- `DriveLog/DriveLog/Application/Calendar/LoadCalendarMonthUseCase.swift`
- `DriveLog/DriveLogTests/Application/LoadCalendarMonthUseCaseTests.swift`

### Forbidden Changes

- Repository実装、Raw Event、Processing、UI、Project設定

## Requirements

1. `CalendarMonthData: Sendable, Equatable`をinterfaces.mdどおり定義する。
2. `LoadCalendarMonthUseCase: Sendable`を定義し、DerivedDataRepositoryだけから取得する。
3. AggregateをlocalDateKey順のCalendarDayDataへ変換する。
4. `hasValidMovement == true`の日だけtotalDistanceMetersを返す。
5. 無効日はCalendarDayDataとして残し、distanceをnilとする。
6. localDateKey末尾から1...31の日を安全に抽出し、不正値はinvalidDataとして失敗する。
7. 空月は空のdaysを返す。
8. DriveLogErrorは維持し、その他のErrorは固定コードのpersistenceFailureへ変換する。
9. RawEventRepositoryを依存に持たない。

## Acceptance Criteria

- [x] 有効日だけ距離を返す。
- [x] 無効日は距離nilかつhasValidMovement falseとなる。
- [x] 日付順、空月、不正キーが正しい。
- [x] Repository ErrorをDriveLogErrorとして返す。
- [x] Raw Eventを取得しない構造である。
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

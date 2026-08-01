# [Application] 徒歩以外の移動を表示する

## Summary

Production UIの移動表示を「車両系のみ」から「徒歩系だけ除外」へ変更し、車両系とその他の移動を日別・月間で一貫して表示する。

## Background

既存の`AutomotiveMovementFilter`は`.automotiveLike`だけを残すため、電車、自転車、分類が確定しない移動など`.other`の区間が表示されない。最新の実機フィードバックでは徒歩以外を表示対象とする。

## Goal

`.walkingLike`だけを非表示とし、`.automotiveLike`と`.other`を同じ表示・集計境界で扱う。

## Non-Goals

- MovementClassifierの閾値変更
- 保存済みRaw/Derived dataの再処理
- 分類変更UIの再表示

## Required Documents

- [x] `AGENTS.md`
- [x] `docs/project-rules.md`
- [x] `docs/processing-rules.md`
- [x] `docs/test-plan.md`
- [x] `issues/16-1-automotive-movement-filter.md`
- [x] `issues/16-4-automotive-filter-boundary.md`

## Scope

### Allowed Changes

- `issues/18-2-non-walking-movement-display.md`
- `docs/project-rules.md`
- `DriveLog/DriveLog/Processing/Classification/AutomotiveMovementFilter.swift`
- `DriveLog/DriveLog/Application/DayDetail/LoadDayDetailUseCase.swift`
- `DriveLog/DriveLog/Application/Calendar/LoadCalendarMonthUseCase.swift`
- `DriveLog/DriveLog/Application/Calendar/LoadMonthlySummaryUseCase.swift`
- `DriveLog/DriveLog/Application/Calendar/LoadMonthlyOverviewUseCase.swift`
- 関連する`DriveLogTests`のTest file

### Forbidden Changes

- MovementClassifier、SwiftData Schema、Repository保存契約
- Location取得Mode
- UI Layout、Signing、外部Package

## Requirements

1. `.walkingLike`のMovementを表示対象から除外する。
2. `.automotiveLike`と`.other`のMovementを保持する。
3. 日別詳細、日別地図、月間地図、Calendar、月間サマリーへ同じ規則を適用する。
4. Aggregate fallbackも`.walkingLike`だけを除外する。
5. 表示用Aggregateの距離・時間・開始終了は保持した非徒歩区間から再構築する。
6. 表示用`automotiveDurationSeconds`は車両系区間だけ、`walkingDurationSeconds`は0とする。

## Privacy Requirements

- 座標、経路、日時、分類対象IDをLoggerへ追加しない。
- 外部通信を追加しない。

## Test Requirements

- Filterが車両系と`.other`を保持し、徒歩系を除外すること。
- `.other`だけの有効なAggregateを表示できること。
- Calendar、月間Overview、月間Summaryが`.other`を含むこと。
- Build、Test、Lint、Format、Diff Checkを成功させる。

## Acceptance Criteria

- [ ] 徒歩系区間は表示されない。
- [ ] 車両系とその他の区間は表示される。
- [ ] 日別と月間の合計が同じ表示規則に従う。
- [ ] 自動検証が成功する。

## Completion Report Format

- Summary
- Display Policy
- Changed Files
- Tests Added
- Verification
- Deviations
- Unresolved Issues

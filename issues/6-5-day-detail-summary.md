# [UI] 基本サマリーを実装する

## Summary

Day Detailの地図直下へ、距離、移動時間、開始、終了、Media件数、代表仮分類を仕様順に表示する。

## Goal

当日の主要な移動情報を小型画面とDynamic Typeでも読み取れるカードとして提供する。

## Non-Goals

- 詳細統計、Media Grid、分類修正

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 6-4

## Scope

### Allowed Changes

- `issues/6-5-day-detail-summary.md`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DaySummaryCard.swift`
- `DriveLog/DriveLog/Shared/Formatting/DayDetailFormatter.swift`
- `DriveLog/DriveLogTests/Shared/DayDetailFormatterTests.swift`

### Forbidden Changes

- Domain、UseCase、Repository、SwiftData、Map Preview、Project設定、外部Package

## Requirements

1. 距離、移動時間、開始、終了、Media件数、代表仮分類の順で表示する。
2. 距離と移動時間を主要値として強調する。
3. Duration、時刻、分類の表示変換をViewから分離する。
4. 端末の現在Time Zoneで時刻を表示する。
5. nil時刻を`--`として安全に表示する。
6. Adaptive Gridにより小型画面とDynamic Typeで自然に折り返す。

## Decisions

- Durationは秒を切り捨てた分単位とし、60分以上は「時間 分」で表示する。
- 仮分類は「車っぽい移動」「徒歩っぽい移動」「その他」の固定文言を使う。

## Acceptance Criteria

- [x] 6項目を仕様順で表示する。
- [x] Formatterの距離、Duration、時刻、nil、分類をテストする。
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

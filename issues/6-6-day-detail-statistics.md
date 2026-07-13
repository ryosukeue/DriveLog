# [UI] 詳細統計を実装する

## Summary

Day Detailの基本サマリー下へ、区間、滞在、記録点、除外点、分類別時間の詳細統計を表示する。

## Goal

当日の処理結果と記録品質を、仕様で許可された集計値だけで確認できるようにする。

## Non-Goals

- 日全体平均速度、最高速度、区間Callout、修正操作

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 6-5

## Scope

### Allowed Changes

- `issues/6-6-day-detail-statistics.md`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayStatisticsCard.swift`

### Forbidden Changes

- Domain、UseCase、Repository、Formatter、SwiftData、Map、Project設定、外部Package

## Requirements

1. 移動区間数、滞在地点数、総滞在時間、記録点数、除外位置点数、車っぽい移動時間、徒歩っぽい移動時間の順で表示する。
2. 日全体平均速度と最高速度を追加しない。
3. 件数は非負の整数、時間は既存Formatterで表示する。
4. Adaptive GridとDynamic Type対応Textを使用する。
5. AccessibilityでLabelとValueを組み合わせて読み上げる。

## Acceptance Criteria

- [x] 仕様の7項目を順番に表示する。
- [x] 仕様外の速度統計を表示しない。
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

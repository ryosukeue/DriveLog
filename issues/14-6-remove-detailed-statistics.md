# [UI] Day Detailの詳細統計表示を削除する

## Summary

Day Detailから価値の低い詳細統計Cardを削除し、地図、基本距離/時間、Mediaを中心にする。

## Background

`DayStatisticsCard`は区間数、滞在数、記録/除外点数、分類別時間を表示し画面を複雑にしている。`DaySummaryCard`は総距離、総移動時間、開始/終了、Media件数を保持する。集計Model/Processing値は将来利用と互換性のため削除しない。

## Goal

詳細統計専用Presentationだけを削除してDay Detailを簡潔にする。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/data-model.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/14-6-remove-detailed-statistics.md`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayStatisticsCard.swift`
- 対応するUI Test

### Forbidden Changes

- Aggregate Model/Schema/Processing/Repository
- 基本Summary、地図、Media

## Requirements

1. 詳細統計Sectionと専用Viewを削除する。
2. 基本距離、移動時間、開始/終了、Media件数を維持する。
3. 内部集計データを変更しない。

## Acceptance Criteria

- [ ] `dayDetail.statistics`がProduction UIにない
- [ ] `dayDetail.summary`、地図、Mediaが維持される
- [ ] Build/Test/Lint/Format/diff check成功

## Decisions / Deviations

- FormatterはMap Calloutにも使用されるため削除しない。
- Aggregateの詳細値とProcessing Testは内部データとして維持する。

## Completion Report Format

- Summary
- Removed UI/files/tests
- Preserved data
- Verification
- Deviations

## Completion

- `DayStatisticsCard`とDay Detailへの挿入、専用UI assertionを削除した。
- 基本Summary、地図、Media Gridと全Aggregate/Processingデータを維持した。
- Build、全393 Test、SwiftLint、SwiftFormat、`git diff --check`成功。
- 実機レイアウトは未確認。環境由来以外の新規Warningはない。

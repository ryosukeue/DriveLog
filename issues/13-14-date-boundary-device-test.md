# [Device] 日付境界Testを実施する

## Summary

現地時刻の深夜を跨ぐ移動でRaw event固定日付、区間分割、日別集計、削除境界を実機確認する。

## Required Documents

- [x] `docs/data-model.md`
- [x] `docs/processing-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-14-date-boundary-device-test.md`
- 実機または自動Testで再現した境界不具合に直接関係する実装とTest

### Forbidden Changes

- 既存Raw eventの日付再解釈、V1 Schema変更、実測なしの実機成功記録

## Requirements

1. 23:50〜00:10を跨ぐ移動を記録する。
2. 記録時localDateKey/offsetで2日に固定・分割する。
3. 各日のCalendar/Day Detailと完全削除境界を確認する。
4. 後日のTimeZone変更で過去日の所属が変わらないことを確認する。

## Acceptance Criteria

- [ ] 接続実機で深夜跨ぎを完了する。
- [x] Boundary splitterと削除境界の自動Testが成功する。
- [ ] 実機表示と保存結果を確認する。

## Decision / Deviations

- LocalDayBoundarySplitter、RecordedTimeContext、日別Repository/削除Integration Testは全Suiteで成功済み。
- 現実の深夜Background deliveryは接続実機と時刻経過が必要なため未実施。成功扱いにしない。

## Files Expected to Change

- 現時点では本Issue文書のみ。

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

# [Device] TimeZone変更Testを実施する

## Summary

端末TimeZoneを変更しても過去Raw eventのlocalDateKeyとutcOffsetが固定され、新規記録だけが新TimeZoneを使うことを実機確認する。

## Required Documents

- [x] `docs/data-model.md`
- [x] `docs/processing-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-15-time-zone-device-test.md`
- 実機または自動Testで再現したTimeZone不具合に直接関係する実装とTest

### Forbidden Changes

- 過去Raw event再解釈、V1 Schema変更、実測なしの実機成功記録

## Requirements

1. TimeZone変更前後にRaw eventを記録する。
2. 変更前eventの日付Key/offsetが不変であることを確認する。
3. 変更後eventが新TimeZone contextを使うことを確認する。
4. Calendar表示と再処理結果を確認する。

## Acceptance Criteria

- [ ] 接続実機でTimeZone変更Testを完了する。
- [x] Clock/TimeZone/RecordedTimeContextの自動Testが成功する。
- [ ] 実機のBackground eventと表示を確認する。

## Decision / Deviations

- Fixed Clock/TimeZone、RecordedTimeContext、day boundaryのUnit Testは全Suiteで成功済み。
- 実機Settings変更とOS event deliveryが必要なため実機部分は未実施。成功扱いにしない。

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

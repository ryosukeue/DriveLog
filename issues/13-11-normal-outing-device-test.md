# [Device] 普通の外出1日Testを実施する

## Summary

徒歩・滞在・通常移動を含む実際の外出1日で、Background収集から翌日の振り返りまでを実機確認する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/processing-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-11-normal-outing-device-test.md`
- 実機で再現した不具合に直接関係する実装とTest

### Forbidden Changes

- 実測なしの成功記録、Raw Log自動削除、常時高精度GPS追加

## Requirements

1. 位置を常に許可し、Motionを許可する。
2. 徒歩・滞在・通常移動を含む1日を記録する。
3. Background/再起動後もRaw eventを保持する。
4. Calendar、Day Detail、Map、集計を翌日に確認する。

## Acceptance Criteria

- [ ] 接続実機で1日Testを完了する。
- [ ] Crash、欠損、異常なbattery消費がない。
- [ ] 表示とRaw/derived整合を確認する。

## Decision / Deviations

- 接続された署名済み実機と現実の外出が必要なため自動実行不能。成功扱いにしない。
- Simulator UI Test、Pipeline Unit/Integration Test、Background coordinator Testは成功済みだが、実機SLC/Motion/Background deliveryの代替にはならない。

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

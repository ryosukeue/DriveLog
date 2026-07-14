# [Performance] 日別処理負荷を確認する

## Summary

設計上の代表負荷で日別PipelineとMap scene構築が実用的な時間内に完了することを自動Testで確認する。

## Required Documents

- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-7-day-processing-performance.md`
- `DriveLog/DriveLogTests/Performance/DayWorkloadPerformanceTests.swift`

### Forbidden Changes

- Production algorithm、閾値、Schema、Project設定の変更

## Requirements

1. 1,000 Locationを日別Pipelineへ入力する。
2. 100 Movement、100 Stay、1,000 MediaをMapSceneへ入力する。
3. Debug Simulatorでも固定待機なしに5秒以内で完了する。
4. 件数と出力を検証し、処理省略による偽成功を防ぐ。

## Acceptance Criteria

- [x] 代表負荷Testが成功する。
- [x] 1,000 Location、100 Movement、100 Stay、1,000 Mediaを実際に生成する。
- [x] Build、全Test、Lint、Format、Diff Checkが成功する。

## Decision / Deviations

- 5秒はCI/Debug Simulatorの揺らぎを許容しつつ、明白な性能退行を検知する保守的上限とする。
- Memory peakの計測は13-8で扱う。
- iPhone 17 / iOS 26.5 Debug Simulatorで代表負荷は約0.05秒だった。
- 全Testは失敗0（Swift Testing 381件を含む）で成功した。

## Files Expected to Change

- Allowed Changes記載の2ファイルのみ。

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

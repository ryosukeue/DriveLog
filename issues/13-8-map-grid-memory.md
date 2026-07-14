# [Performance] MapとGridのメモリ負荷を確認する

## Summary

Media付きDay Detail、Media Grid、Full Mapを反復表示し、Simulator上のMemory metricを記録してCrashや明白な増加を検知する。

## Required Documents

- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-8-map-grid-memory.md`
- `DriveLog/DriveLogUITests/DriveLogMemoryPerformanceTests.swift`

### Forbidden Changes

- Cache仕様、画像品質、Map仕様の計測前変更

## Requirements

1. Seed済みMedia Day Detailを起動する。
2. GridまでScrollし、Full Mapを表示する。
3. `XCTMemoryMetric`で3回反復測定する。
4. 各反復で画面が操作可能でCrashしないことを確認する。

## Acceptance Criteria

- [x] Memory performance Testが成功する。
- [x] 3反復のMetricが記録される。
- [x] Build、全Test、Lint、Format、Diff Checkが成功する。

## Decision / Deviations

- Simulator metricは実機peak memoryを保証しない。実機Instruments確認はRelease前確認に残す。
- `XCTMemoryMetric`の3反復と全Test（失敗0）がiPhone 17 / iOS 26.5で成功した。
- Source由来の新規Warningはなく、Simulator LLDB/Accessibility Warningのみだった。

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

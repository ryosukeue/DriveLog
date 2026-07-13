# [Processing] 区間距離・平均速度を実装する

## Summary

位置点列から隣接地表距離、区間時間、表示可能な区間平均速度を一貫して計算する。

## Goal

2分、100m、2点の全条件を満たす区間だけ平均速度を持ち、日全体平均や最高速度を生成しない純粋計算を実装する。

## Non-Goals

- 日全体平均速度・最高速度
- Map Matching・道路距離補正
- 表示Format

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 3-1 ProcessingConfiguration
- Issue 3-7 GeodesicDistanceCalculator／MovementSegmentCandidate

## Scope

### Allowed Changes

- `issues/3-11-movement-metrics.md`
- `DriveLog/DriveLog/Processing/Metrics/MovementMetricsCalculator.swift`
- `DriveLog/DriveLog/Processing/Segmentation/MovementSegmenter.swift`
- `DriveLog/DriveLog/Processing/Classification/MovementClassifier.swift`
- `DriveLog/DriveLogTests/Processing/MovementMetricsCalculatorTests.swift`
- `DriveLog/DriveLogTests/Processing/MovementClassifierTests.swift`

### Forbidden Changes

- Domain保存型、Repository、SwiftData Schema、Platform、UI、Project設定、外部Package

## Requirements

1. 隣接位置点間のHaversine地表距離を合計する。
2. durationは末尾timestamp−先頭timestampとする。
3. 2分以上、2点以上、100m以上、正時間の全条件でのみ平均速度を返す。
4. 2分、2点、100mの境界を含める。
5. 空配列と負時系列は計算不能としてnilを返す。
6. 1点、0秒、条件未満は距離・時間を返し平均速度だけnilとする。
7. MovementSegmenterの候補へ同じ計算結果を保持する。
8. MovementClassifierの速度fallbackは候補のoptional平均速度だけを使う。
9. 日全体平均速度と最高速度を生成しない。

## Acceptance Criteria

- [x] 距離合計と時間差が正しい。
- [x] 2分／100m／2点の上下・境界が正しい。
- [x] 空、1点、0秒、負時系列を安全に扱う。
- [x] SegmenterとClassifierが同じmetricsを利用する。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Decisions

- 空配列と負時系列は入力契約違反としてnil、0秒は有効な観測列だが平均速度算出不能な`MovementMetrics`として区別する。
- 平均速度は候補のoptional propertyとして保持し、Motion分類は速度なしでも可能、速度fallbackだけはnil時にotherとする。

## Test Requirements

### Unit Tests

- [x] 複数点距離合計。
- [x] 2分未満／ちょうど、100m未満／ちょうど、1点／2点。
- [x] 空、0秒、負時系列。
- [x] Segmenter格納とClassifier nil fallback回帰。

### Integration / UI Tests

- なし。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- Allowed Changes記載の6ファイル。

## Definition of Done

- [x] GoalとAcceptance Criteriaを満たす。
- [x] Allowed Changes内だけを変更する。
- [x] 全検証が成功する。

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
- Build:
- Unit Tests:
- Integration Tests:
- UI Tests:
- SwiftLint:
- SwiftFormat:
- Diff Check:
### Manual Verification
### Deviations
### Unresolved Issues

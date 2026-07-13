# [Processing] DaySummaryBuilderを実装する

## Summary

処理済みの位置点、移動区間、滞在区間からカレンダーと日別詳細に必要な日次集計を決定的に生成する。

## Goal

距離・時間・区間数・表示滞在・代表自動分類と、1km／1区間／2点の有効移動日判定を`DayAggregateData`へ集約する。

## Non-Goals

- 日全体の平均速度・最高速度
- ユーザー分類による代表自動分類の上書き
- SwiftData保存、UI Format、Calendar表示

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 3-1 ProcessingConfiguration
- SanitizedLocations、MovementSegmentData、StaySegmentData、DayAggregateData

## Scope

### Allowed Changes

- `issues/3-15-day-summary-builder.md`
- `DriveLog/DriveLog/Processing/Summary/DaySummaryBuilder.swift`
- `DriveLog/DriveLogTests/Processing/DaySummaryBuilderTests.swift`

### Forbidden Changes

- Domain型、Repository、SwiftData Schema、Platform、UI、Project設定、外部Package

## Requirements

1. `DaySummaryBuilding: Sendable`を設計文書のSignatureで実装する。
2. 全Movementの距離、時間、件数、最早開始、最遅終了を集計する。
3. automotiveLikeとwalkingLikeの時間を分類別に集計する。
4. 最も合計移動時間が長い自動分類を代表とし、同率・区間なしはotherとする。
5. 表示対象Stayだけの件数と時間を集計する。
6. accepted／rejected位置点数、mediaCount、sourceRawRevision、generatedAtを保持する。
7. 距離1000m以上、Movement 1件以上、accepted位置2点以上の全条件でhasValidMovementをtrueにする。
8. 各境界値を含める。
9. 空入力と全位置点除外を成功する空集計として扱う。
10. 日全体平均速度と最高速度を生成しない。
11. MainActor、UI、OS Framework、SwiftDataへ依存しない。

## Interface Contract

```swift
protocol DaySummaryBuilding: Sendable {
    func build(
        localDateKey: String,
        sanitizedLocations: SanitizedLocations,
        movements: [MovementSegmentData],
        stays: [StaySegmentData],
        mediaCount: Int,
        sourceRawRevision: Int,
        generatedAt: Date
    ) -> DayAggregateData
}
```

## Decisions

- 代表分類は分類ごとの`durationSeconds`合計を比較し、最大値が一意の場合のみ採用する。otherも同じ比較対象とする。
- `StaySegmentData.isVisibleByAutomaticRule`は前段でOverride適用済みの最終表示可否として集計する。

## Acceptance Criteria

- [x] 距離、時間、開始・終了、Movement件数が正しい。
- [x] 表示Stay件数・時間と分類別時間が正しい。
- [x] 代表分類と同率otherが正しい。
- [x] 1000m／1区間／2点の有効日境界が正しい。
- [x] 空、全除外、mediaCount、revision、generatedAtを扱える。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Test Requirements

### Unit Tests

- [x] 全集計項目、表示／非表示Stay、分類別時間。
- [x] 代表分類、一意最大、同率、区間0件。
- [x] 999m／1000m、0／1区間、1／2点、全除外。
- [x] mediaCount、rejectedLocationCount、revision、generatedAt。

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

- Allowed Changes記載の3ファイル。

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

# [Processing] DefaultDayProcessorを実装する

## Summary

Phase 3の純粋Processing Componentを順番に実行し、生ログから保存可能な日別Aggregate、Movement、Stayを生成する。

## Goal

指定localDateKeyのRawDayEventsを決定的に処理し、Overrideを保持・再適用しながらSwiftData非依存の`DayProcessingResult`を返す。

## Non-Goals

- 派生データのSwiftData保存・世代状態更新
- BGTask、UI更新、メディア座標検索
- Override自体の更新・削除

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

- Issues 3-1〜3-15のProcessing Component
- Clock、StableIDGenerating、RawDayEvents、派生Domain Data

## Scope

### Allowed Changes

- `issues/3-16-default-day-processor.md`
- `DriveLog/DriveLog/Processing/Pipeline/DefaultDayProcessor.swift`
- `DriveLog/DriveLogTests/Processing/DefaultDayProcessorTests.swift`

### Forbidden Changes

- Domain型、Repository、SwiftData Schema、Platform、UI、AppContainer、Project設定、外部Package

## Requirements

1. `DayProcessing: Sendable`を設計文書のasync throws Signatureで実装する。
2. sanitize、localDateKey分離、segment、stay、classification、Override、route、label、summaryの順で処理する。
3. 指定日以外のRaw EventとOverrideを結果へ混入させない。
4. Movement stableIDを既存StableIDGeneratingで生成する。
5. Movementごとに自動分類、簡略化経路、labelCoordinate、revision、generatedAtを設定する。
6. Stay OverrideはstableID完全一致または一意の近似一致を再適用する。
7. Classification Overrideは自動分類を上書きせず、後続の表示データ生成で既存Overrideを一意に再照合できる状態を維持する。
8. Summaryは最終Movement／Stayから生成する。
9. Clockのnowを1回取得し、全派生データのgeneratedAtへ同じ値を使用する。
10. 空、1点、全除外入力を成功結果として返す。
11. 同じ入力、Clock、Configurationから同じ結果を返す。
12. 処理段階間でTask cancellationを確認し、中断時は結果を返さない。
13. SwiftData保存、OS Framework、UI、MainActorへ依存しない。

## Interface Contract

```swift
protocol DayProcessing: Sendable {
    func process(
        localDateKey: String,
        rawEvents: RawDayEvents,
        mediaCount: Int,
        rawRevision: Int
    ) async throws -> DayProcessingResult
}
```

## Decisions

- `StayDetecting`の既存Signatureがrevision／generatedAtを受け取らないため、Default実装はprocessごとに同じConfigurationとStableID generatorから`StayDetector`を生成する。
- `MovementSegmentData`はユーザー分類Propertyを持たず、設計上も自動値とOverrideを分離保存する。したがってClassification Overrideで自動分類を上書きせず、Phase 6の表示値生成で`OverrideMatcher`を使用する。
- RouteLabelの文字列は永続Schemaの対象外なので、このPipelineは算出したcoordinateだけをMovementへ保持する。
- Media座標は入力契約に存在しないため、label衝突候補には表示Stayと先行Movement labelだけを渡す。

## Acceptance Criteria

- [x] 全Componentを定義順で統合し、保存可能な3種の結果を返す。
- [x] stableID、分類、経路、label、revision、generatedAtが一貫する。
- [x] Stay Override完全一致・近似一致を適用できる。
- [x] 空、1点、全除外、別日混入を安全に扱う。
- [x] 同一入力の結果が決定的で、キャンセルを伝播する。
- [x] SwiftData保存を行わない。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Test Requirements

### Unit Tests

- [x] 具体ComponentによるMovement、分類、経路、label、Summary統合。
- [x] Stay近似Override再適用。
- [x] 空、1点、全除外、別日分離。
- [x] fixed Clockによる決定性とrawRevision伝播。
- [x] 事前キャンセル時のCancellationError。

### Integration / UI Tests

- なし（SwiftData保存はPhase 4）。

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

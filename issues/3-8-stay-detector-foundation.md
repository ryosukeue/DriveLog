# [Processing] StayDetector基礎を実装する

## Summary

移動区間間のGapから、3分／5分、150m、Visit、automotive→walking証拠を使って滞在候補を生成する。

## Goal

代表座標、推定到着・出発、信頼度、検出元、Override適用結果を持つ`StaySegmentData`を決定的に生成する。

## Non-Goals

- automotive→stationary→automotiveの渋滞・信号除外（Issue 3-9）
- Override近似再紐づけ（Issue 3-14）
- 永続化

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

- Issue 1-9 Stable ID
- Issue 3-1 ProcessingConfiguration
- Issue 3-7 MovementSegmenter

## Scope

### Allowed Changes

- `issues/3-8-stay-detector-foundation.md`
- `DriveLog/DriveLog/Processing/Stay/StayDetector.swift`
- `DriveLog/DriveLogTests/Processing/StayDetectorTests.swift`
- `DriveLog/DriveLog/Domain/Entities/StaySegmentData.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/StayConfidence.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/StayDetectionSource.swift`
- `DriveLog/DriveLog/Domain/Identifiers/StableIDGenerating.swift`
- `DriveLog/DriveLog/Domain/Identifiers/SHA256StableIDGenerator.swift`

### Forbidden Changes

- Repository、SwiftData Schema、Platform、UI、Project設定、外部Package

## Requirements

1. `StayDetecting`を`docs/interfaces.md`どおり実装する。
2. 3分未満は自動非表示、3分以上5分未満はVisitまたはautomotive→walking証拠がある場合だけ表示する。
3. 5分以上はこのIssueでは自動表示する。
4. VisitがなければGap両端が150m以内の場合だけ候補化し、境界を含める。
5. Visitがあればその座標、arrivalDate、departureDateを優先する。
6. Visitがなければ精度加重座標とGap前後時刻を使う。
7. automotive→stationary→walkingもMotion証拠として扱う。
8. localDateKey境界から日跨ぎStayを作らない。
9. 完全一致stableIDの最新Override actionを適用する。
10. sourceRawRevisionとgeneratedAtはInitializerで処理コンテキストから注入し、placeholderを使わない。
11. stableIDは既存`StableIDGenerating`を使用する。
12. 純粋Domain依存型を`nonisolated`とし、値と保存形式は変えない。

## Acceptance Criteria

- [x] 3分未満、3分、5分未満、5分境界が正しい。
- [x] VisitとMotion証拠を反映する。
- [x] 150m境界を含め、超過を除外する。
- [x] Visit到着・出発・座標を優先し、未確定Visitを扱う。
- [x] confirm、hide、automatic Overrideを完全一致で適用する。
- [x] metadataとstableIDが決定的である。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Decisions

- `StaySegmentData`が生成metadataを必須とする一方、Protocol引数にrevision／生成時刻がないため、Concrete DetectorのInitializerへ処理コンテキストとして必須注入する。
- 3分未満や証拠不足の候補もOverride可能にするためDataを生成し、`isVisibleByAutomaticRule`をfalseとする。
- ProtocolがOverrideを入力に含むため、この段階では同fieldへ完全一致Override後の可視性を返す。自動値と表示値の分離が必要ならDayProcessor統合時に再監査する。
- Visitがある場合はSLC端点の粗さに左右されず候補化する。VisitなしではGap両端を停止中観測点として150m判定する。
- Haversineの浮動小数点往復誤差で150mちょうどを誤除外しないよう、比較時だけ閾値の`1e-12`倍を数値許容差とする。

## Test Requirements

### Unit Tests

- [x] 3分未満、3分、3〜5分、5分、5分超。
- [x] Visit、automotive→walking、automotive→stationary→walking。
- [x] 150m、150m超、日付境界。
- [x] Visit arrival／departure／座標、出発未確定。
- [x] confirm／hide／automatic、metadata、複数Gap。

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

- Allowed Changes記載のIssue、StayDetector、Unit Test、純粋Domain型。

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

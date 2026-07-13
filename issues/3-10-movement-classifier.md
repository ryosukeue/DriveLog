# [Processing] MovementClassifierを実装する

## Summary

区間内Motionの重複排除済み重み付き占有率と、Motion不足時の速度・距離fallbackから3種の自動移動分類を生成する。

## Goal

automotiveLike、walkingLike、otherと信頼度、構造化された根拠を決定的に返す。

## Non-Goals

- 自転車専用表示分類
- 電車・バス・自家用車の自動断定
- ユーザーOverride適用

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
- Issue 3-7 MovementSegmentCandidate

## Scope

### Allowed Changes

- `issues/3-10-movement-classifier.md`
- `DriveLog/DriveLog/Processing/Classification/MovementClassifier.swift`
- `DriveLog/DriveLogTests/Processing/MovementClassifierTests.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/AutomaticMovementType.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/ClassificationConfidence.swift`

### Forbidden Changes

- 永続化Model、Repository、Platform、UI、Project設定、外部Package

## Requirements

1. `MovementClassifying`を設計どおり実装する。
2. 同一状態の重複Motion時間を二重加算しない。
3. low=0.5、medium=0.75、high=1.0の重みを設定から使う。
4. automotive 50%以上をautomotiveLikeとする。
5. walking／running 40%以上をwalkingLikeとする。
6. Motionがない場合だけ15km/h以上かつ2km以上をautomotiveLike fallbackとする。
7. Motionがない場合だけ8km/h以下かつ3km以下をwalkingLike fallbackとする。
8. cycling／unknown中心、証拠競合、情報不足をotherとする。
9. 競合時は重み付き占有率が高い側、同値なら明確なautomotiveを優先する。
10. 70%以上かつ非競合をhigh、40%以上をmedium、それ以外とfallbackをlowとする。
11. 2点未満または非正時間はother／lowとする。
12. 自由文字列でない`ClassificationEvidence`を返す。

## Acceptance Criteria

- [x] automotive 50%とwalking 40%の上下・境界が正しい。
- [x] Motion重複とconfidence重みを正しく扱う。
- [x] 速度・距離fallbackの全境界が正しい。
- [x] cycling、unknown、競合、情報不足をotherにする。
- [x] high／medium／lowとEvidenceが決定的である。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Decisions

- 重複Motionはイベント境界で時間軸を細分化し、同一状態では各区間の最大confidence重みだけを加算する。異なる状態の同時報告は競合証拠として各状態へ加算する。
- cycling／unknownは50%以上かつ他証拠以上の場合に「中心」と扱いotherとする。
- 速度fallbackで使う平均速度は候補の距離÷正の時間とし、表示用平均速度のnil規則はIssue 3-11で分離する。

## Test Requirements

### Unit Tests

- [x] automotive 49%／50%／51%、walking 39%／40%／41%。
- [x] confidence weight、重複時間、競合。
- [x] Motionなし速度・距離fallback境界。
- [x] cycling、unknown、点不足、0秒。
- [x] confidence high／medium／low、Evidence順序。

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

- Allowed Changes記載の5ファイル。

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

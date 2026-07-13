# [Processing] OverrideMatcherを実装する

## Summary

再処理でstableIDが変化した場合も、保守的な時刻・重なり・座標条件で既存Overrideを一意の派生区間へ再紐づけする。

## Goal

stableID完全一致を優先し、近似候補が1件だけの場合に限ってMovement／Stay Overrideを再適用できる純粋処理を実装する。

## Non-Goals

- Overrideの保存・削除・変更
- ユーザー修正のUI
- 派生区間への値適用

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
- `ClassificationOverrideData`、`StayOverrideData`、Movement／Stay Segment Data

## Scope

### Allowed Changes

- `issues/3-14-override-matcher.md`
- `DriveLog/DriveLog/Processing/Override/OverrideMatcher.swift`
- `DriveLog/DriveLogTests/Processing/OverrideMatcherTests.swift`

### Forbidden Changes

- Override／Segment Domain型、Repository、SwiftData Schema、Platform、UI、Project設定、外部Package

## Requirements

1. `OverrideMatching: Sendable`を設計文書の2メソッドで実装する。
2. stableID完全一致が1件なら近似判定せず返す。
3. Movement近似は同じlocalDateKey、開始差15分以内、終了差15分以内、短い方に対する時間重なり50%以上をすべて満たす。
4. Stay近似は同じlocalDateKey、到着差15分以内、出発差15分以内、代表座標差300m以内をすべて満たす。
5. 境界値を含める。
6. 近似候補が0件または複数ならnilを返す。
7. stableID完全一致が重複する不正入力も誤適用を避けてnilを返す。
8. Overrideと候補配列を変更しない。
9. MainActor、UI、Apple位置Framework、SwiftDataへ依存しない。

## Interface Contract

```swift
protocol OverrideMatching: Sendable {
    func matchClassificationOverride(
        _ override: ClassificationOverrideData,
        to segments: [MovementSegmentData]
    ) -> MovementSegmentData?

    func matchStayOverride(
        _ override: StayOverrideData,
        to stays: [StaySegmentData]
    ) -> StaySegmentData?
}
```

## Decisions

- 0秒以下の区間は重なり率を定義できないためMovement近似候補から除外する。
- 完全一致が複数ある入力も「複数候補を適用しない」を優先してnilとする。
- Haversine計算の丸めで理論上300mの値を除外しないよう、座標境界比較だけに1µmの数値誤差許容を加える。

## Acceptance Criteria

- [x] stableID完全一致を最優先できる。
- [x] Movementの時刻・50%重なり境界が正しい。
- [x] Stayの時刻・300m境界が正しい。
- [x] localDateKey不一致、候補0件／複数を拒否する。
- [x] 元Overrideを変更しない。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Test Requirements

### Unit Tests

- [x] Movement完全一致、開始／終了15分、重なり50%、0／1／複数、別日。
- [x] Stay完全一致、到着／出発15分、座標300m、0／1／複数、別日。
- [x] Override入力不変性。

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

# [Processing] RouteLabelPlacerを実装する

## Summary

移動区間の表示ラベルを経路距離上の候補位置へ配置し、時間・距離を固定形式で表現する。

## Goal

経路距離50%を優先し、占有時は40%、45%、55%、60%の順で選べる純粋な`RouteLabelPlacing`実装を追加する。

## Non-Goals

- Mapの画面端・Annotation frameによる衝突判定
- MapKit描画、ラベルView、タップ処理
- 経路簡略化

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
- Issue 3-11 Movement metrics
- `MovementSegmentData`、`RouteCoordinate`

## Scope

### Allowed Changes

- `issues/3-13-route-label-placer.md`
- `DriveLog/DriveLog/Processing/Route/RouteLabelPlacer.swift`
- `DriveLog/DriveLogTests/Processing/RouteLabelPlacerTests.swift`

### Forbidden Changes

- Domain保存型、Repository、SwiftData Schema、Platform、UI、Project設定、外部Package

## Requirements

1. `RouteLabelPlacing: Sendable`と`makeLabel(for:occupiedCoordinates:)`を実装する。
2. 配置候補は経路距離の50%、40%、45%、55%、60%の順とする。
3. 配列indexではなく隣接点間地表距離の累積比率で座標を補間する。
4. 占有座標と一致する候補は飛ばし、全候補が占有済みなら50%へ戻す。
5. 単一点はその点を使用する。
6. ラベルは区間stableID、選択座標、`時間・距離`文字列を保持する。
7. 1km未満は整数m、1km以上は小数第1位kmとする。
8. 60分未満は整数分、60分以上は`X時間Y分`とする。
9. MainActor、UI、MapKit、永続化へ依存しない。

## Interface Contract

```swift
protocol RouteLabelPlacing: Sendable {
    func makeLabel(
        for segment: MovementSegmentData,
        occupiedCoordinates: [RouteCoordinate]
    ) -> RouteLabel
}
```

## Decisions

- 設計例のUUIDは現在のV1 Domainが採用するString stableIDへ読み替え、`RouteLabel.movementSegmentID`もStringとする。
- `occupiedCoordinates`は純粋処理で与えられる候補座標との完全一致として扱う。画面上のframe、急カーブ、地図端の衝突はMap表示側の責務とする。
- 分数秒は切り捨てて完了分として表示する。空経路は有効なMovement Segmentでは発生しないが、既存labelCoordinate、次に`0,0`を安全な最終fallbackとする。

## Acceptance Criteria

- [x] 距離50%地点を配列中央ではなく累積距離から求める。
- [x] fallback順と全候補競合時の50%復帰が正しい。
- [x] 短い経路と単一点を安全に扱う。
- [x] ラベル文字列の距離・時間境界が正しい。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Test Requirements

### Unit Tests

- [x] 50%、50%占有、40%、45%、55%、60%、全候補競合。
- [x] 不均等点間隔、短い経路、単一点。
- [x] m/km、分/時間のラベル形式。

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

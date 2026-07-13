# [Processing] RouteSimplifierを実装する

## Summary

表示用経路を30m許容差のDouglas-Peucker方式で簡略化し、元の座標列と端点を維持する。

## Goal

10点以上の経路だけを決定的に簡略化できる純粋な`RouteSimplifying`実装を追加する。

## Non-Goals

- 生の位置イベントや保存済み経路の変更
- 地図ズーム連動の再簡略化
- ラベル位置計算

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
- `RouteCoordinate`

## Scope

### Allowed Changes

- `issues/3-12-route-simplifier.md`
- `DriveLog/DriveLog/Processing/Route/RouteSimplifier.swift`
- `DriveLog/DriveLogTests/Processing/RouteSimplifierTests.swift`

### Forbidden Changes

- Domain保存型、Repository、SwiftData Schema、Platform、UI、Project設定、外部Package

## Requirements

1. `RouteSimplifying: Sendable`と設計文書どおりの` simplify(_:)`を実装する。
2. 10点未満は入力と同じ座標列を返す。
3. 10点以上は30m許容差のDouglas-Peucker方式で簡略化する。
4. 開始点と終了点を必ず維持する。
5. 許容差から30m以下の点は除去対象、30mを超える点は維持対象とする。
6. 空、1点、直線、曲線、同一座標の連続を安全に扱う。
7. 入力配列と座標値を変更せず、新しい表示用配列を返す。
8. MainActor、UI、Apple位置Framework、永続化へ依存しない。

## Interface Contract

```swift
protocol RouteSimplifying: Sendable {
    func simplify(_ coordinates: [RouteCoordinate]) -> [RouteCoordinate]
}
```

## Decisions

- 点と線分の距離は、線分始点を基準に経度差を正規化した局所正距円筒座標へ投影して求める。MVPの短い移動区間で30m判定を安定させ、MapKit依存を避ける。
- 最大距離が許容差と等しい場合は除去し、超えた場合だけ分割する。

## Acceptance Criteria

- [x] 0、1、9点を変更しない。
- [x] 10点以上の直線経路を端点へ簡略化できる。
- [x] 30m境界と曲線形状を正しく扱う。
- [x] 端点、同一座標、入力不変性を保証する。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Test Requirements

### Unit Tests

- [x] 0点、1点、9点、10点。
- [x] 直線、曲線、30m以下／超、開始・終了点。
- [x] 同一座標の連続と入力不変性。

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

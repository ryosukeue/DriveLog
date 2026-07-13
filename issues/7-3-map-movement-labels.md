# [Map] 区間ラベルを実装する

## Summary

移動区間の算出済みLabel座標へ「移動時間・距離」を表示し、Tapで区間選択できるようにする。

## Goal

経路を色だけでなく数値Labelでも識別し、細いPolyline以外からもCallout導線を開始できるようにする。

## Non-Goals

- Callout内容、分類変更、Label位置再計算

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 7-2

## Scope

### Allowed Changes

- `issues/7-3-map-movement-labels.md`
- `DriveLog/DriveLog/Domain/Entities/MapScene.swift`
- `DriveLog/DriveLog/Features/Map/MapSceneBuilder.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLogTests/Features/MapSceneBuilderTests.swift`

### Forbidden Changes

- 永続Model、UseCase、Repository、SwiftData、App Navigation、Project設定

## Requirements

1. `MapMovementLabel`へ固定表示文字列を保持する。
2. Durationを分、距離を小数1桁kmで「32分・18.4km」形式にする。
3. Labelは既存の算出済み座標へ配置する。
4. Labelを文字、背景、枠線で表示し、選択時は枠線を強調する。
5. Label TapをPolylineと同じStable ID Callbackへ送る。
6. Accessibility LabelとIdentifierを付ける。

## Acceptance Criteria

- [x] Label文字列と座標をBuilder Testで確認する。
- [x] Label Tapで区間を選択できる。
- [x] 選択状態を色だけでなく枠線でも表現する。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
### Manual Verification
### Deviations
### Unresolved Issues

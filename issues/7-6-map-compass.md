# [Map] MapKit標準コンパスを設定する

## Summary

Full MapへMapKit標準Compassを有効化し、Previewでは非表示にする。

## Goal

地図回転時に標準UIで方角確認とNorth Up復帰を可能にする。

## Non-Goals

- 独自Compass、方位Sensor管理、地図回転仕様変更

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 7-5

## Scope

### Allowed Changes

- `issues/7-6-map-compass.md`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`

### Forbidden Changes

- 独自Compass UI、Location、Domain、UseCase、Repository、Project設定

## Requirements

1. Full modeで`showsCompass`を有効にする。
2. Preview modeではCompassを表示しない。
3. MapKit標準の表示、Tap、Safe Area挙動を利用する。
4. 独自画像、Gesture、方位計算を追加しない。

## Acceptance Criteria

- [x] Full modeで標準Compassが有効である。
- [x] PreviewではCompassが無効である。
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

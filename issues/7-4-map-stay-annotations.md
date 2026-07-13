# [Map] 滞在Annotationを実装する

## Summary

表示対象の滞在地点を推定滞在時間付きAnnotationとして描画し、Tap選択を追加する。

## Goal

経路上の滞在をPolylineより目立つ文字付きPointで確認し、Stay Callout導線へ接続できるようにする。

## Non-Goals

- Stay Callout内容、Override操作、非表示更新

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 7-3

## Scope

### Allowed Changes

- `issues/7-4-map-stay-annotations.md`
- `DriveLog/DriveLog/Domain/Entities/MapScene.swift`
- `DriveLog/DriveLog/Features/Map/MapSceneBuilder.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLogTests/Features/MapSceneBuilderTests.swift`

### Forbidden Changes

- 永続Model、UseCase、Repository、SwiftData、App Navigation、Project設定

## Requirements

1. `MapStayAnnotation`へ推定滞在時間文字列を保持する。
2. 60分未満は分、60分以上は「時間 分」で表示する。
3. StayをPolyline Labelより大きい丸形Annotationとして表示する。
4. Stay Tapを専用Stable ID Callbackへ送る。
5. 選択Stayの枠線を強調する。
6. Accessibility LabelとIdentifierを付ける。

## Acceptance Criteria

- [x] 滞在時間と座標をBuilder Testで確認する。
- [x] Stay Tapで選択Callbackを呼べる。
- [x] 選択を色だけでなく枠線でも表現する。
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

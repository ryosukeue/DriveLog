# [Map] MKMapView Wrapperを実装する

## Summary

MapSceneをMKMapViewへ描画するSwiftUI Bridgeを追加し、PreviewとFullの共通Lifecycleを確立する。

## Goal

Polyline、Annotation、初期領域を差分更新できるRouteMap共通コンポーネントを実装する。

## Non-Goals

- 選択、Callout、現在地、コンパス、Media Thumbnail

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 6-2、6-4

## Scope

### Allowed Changes

- `issues/7-1-map-view-wrapper.md`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayMapPreview.swift`

### Forbidden Changes

- MapScene契約、UseCase、Repository、SwiftData、App Navigation、Project設定、外部Package

## Requirements

1. `UIViewRepresentable`でMKMapViewの生成、更新、Delegate保持を行う。
2. PreviewとFullの操作モードを定義する。
3. MapScene変更時だけOverlay、Annotation、初期領域を差分更新する。
4. Polyline、Stay、Media位置を描画可能にする。
5. PreviewはPan、Zoom、Rotate、Pitch、選択を無効にする。
6. Fullは標準地図操作を有効にする。
7. DayMapPreviewを共通Wrapperへ置換する。
8. iOS 17で利用可能なAPIだけを使う。

## Acceptance Criteria

- [x] SwiftUIからMKMapViewを表示できる。
- [x] MapScene更新で重複Overlay／Annotationを作らない。
- [x] PreviewとFullで操作可否が分離される。
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

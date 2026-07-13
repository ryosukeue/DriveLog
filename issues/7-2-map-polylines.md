# [Map] 移動ポリライン描画を実装する

## Summary

Full Mapの区間Polylineへ広いTap判定と選択状態の視覚的強調を追加する。

## Goal

細い経路線でも区間を選択でき、現在の選択対象を色だけに依存せず判別できるようにする。

## Non-Goals

- Label、Callout、分類変更、ViewModel

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 7-1

## Scope

### Allowed Changes

- `issues/7-2-map-polylines.md`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`

### Forbidden Changes

- MapScene、Domain、UseCase、Repository、SwiftData、Navigation、Project設定

## Requirements

1. Full modeでPolyline TapをStable IDとしてCallbackする。
2. Hit Pathは表示線より広い22ptを確保する。
3. 選択区間は線幅を広げて強調する。
4. 選択状態変更時だけRendererを再描画する。
5. 空白Tapを別Callbackする。
6. Preview modeでは選択Gestureを追加しない。

## Acceptance Criteria

- [x] 区間別にTap判定できる。
- [x] 選択中区間を線幅でも識別できる。
- [x] 空白Tapを識別できる。
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

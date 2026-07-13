# [UI] RouteMapViewModelを実装する

## Summary

Full MapのMapScene、Movement／Stay選択、Callout排他、空白Tapを管理するViewModelと画面を追加する。

## Goal

MKMapView Wrapperへ状態と操作をInitializer Injectionし、1度に1つだけCalloutを表示する。

## Non-Goals

- Override保存、Media Preview、App Navigation接続

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

- Issue 7-1〜7-8

## Scope

### Allowed Changes

- `issues/7-9-route-map-view-model.md`
- `DriveLog/DriveLog/Features/Map/RouteMapViewModel.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLogTests/Features/RouteMapViewModelTests.swift`

### Forbidden Changes

- Domain、UseCase、Repository、SwiftData、App Navigation、Project設定

## Requirements

1. `@MainActor @Observable`のViewModelへMapSceneを注入する。
2. Movement選択時はStay選択を解除する。
3. Stay選択時はMovement選択を解除する。
4. Sceneに存在しないStable IDを選択しない。
5. 空白Tapで全選択を解除する。
6. Full画面はMap全体を使用しSafe AreaとNavigation Barを考慮する。
7. RouteMapViewのFull modeへ状態とCallbackを接続する。

## Acceptance Criteria

- [x] Movement、Stay、無効ID、排他、空白解除をUnit Testする。
- [x] Full Map画面がViewModelだけを参照する。
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

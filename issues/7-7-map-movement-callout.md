# [Map] 区間Calloutを実装する

## Summary

選択中の移動区間へ開始、終了、時間、距離、平均速度、仮分類、ユーザー分類をMap上の吹き出しで表示する。

## Goal

区間の詳細をFull Mapから離れず確認できるようにする。

## Non-Goals

- 分類変更操作、Override保存、日全体平均速度

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 7-3、7-6

## Scope

### Allowed Changes

- `issues/7-7-map-movement-callout.md`
- `DriveLog/DriveLog/Domain/Entities/MapScene.swift`
- `DriveLog/DriveLog/Features/Map/MapSceneBuilder.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLog/Shared/Formatting/DayDetailFormatter.swift`
- `DriveLog/DriveLogTests/Features/MapSceneBuilderTests.swift`
- `DriveLog/DriveLogTests/Shared/DayDetailFormatterTests.swift`

### Forbidden Changes

- Override保存、Repository、SwiftData、日全体平均速度、Bottom Sheet、Project設定

## Requirements

1. Map Movement表示値へCallout用区間情報を保持する。
2. 選択区間の開始、終了、時間、距離、推定平均速度、仮分類、ユーザー分類を表示する。
3. CalloutはMap上の吹き出し形式としBottom Sheetを使わない。
4. 選択中Calloutは1つだけにする。
5. 推定平均速度がない場合は`--`を表示する。
6. 分類変更はPhase 9まで追加しない。
7. Accessibility LabelとIdentifierを付ける。

## Decisions

- MapSceneBuilding契約はRaw Movementを受け取るため、Phase 9まではユーザー分類をnil（未設定）として保持する。
- Callout位置は算出済みMovement Label座標を使用する。

## Acceptance Criteria

- [x] BuilderがCallout用値を保持する。
- [x] 選択区間だけCalloutを表示する。
- [x] Formatterの平均速度とユーザー分類をテストする。
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

# [Map] 滞在Calloutを実装する

## Summary

選択中の滞在地点へ到着、出発、滞在時間、信頼度、判定状態をMap上の吹き出しで表示する。

## Goal

滞在の推定根拠をFull Mapから離れず確認できるようにする。

## Non-Goals

- Stay Override操作、保存、非表示反映

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 7-4、7-7

## Scope

### Allowed Changes

- `issues/7-8-map-stay-callout.md`
- `DriveLog/DriveLog/Domain/Entities/MapScene.swift`
- `DriveLog/DriveLog/Features/Map/MapSceneBuilder.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Shared/Formatting/DayDetailFormatter.swift`
- `DriveLog/DriveLogTests/Features/MapSceneBuilderTests.swift`
- `DriveLog/DriveLogTests/Shared/DayDetailFormatterTests.swift`

### Forbidden Changes

- Override保存、Repository、SwiftData、Bottom Sheet、Project設定

## Requirements

1. Map Stay表示値へCallout用の到着、出発、Duration、信頼度、表示状態を保持する。
2. 選択StayだけMap上の吹き出しで表示する。
3. 到着、出発、滞在時間、判定信頼度、自動判定状態を表示する。
4. 信頼度を低・中・高の固定文言で表示する。
5. Override操作はPhase 9まで追加しない。
6. Accessibility LabelとIdentifierを付ける。

## Acceptance Criteria

- [x] BuilderがStay Callout用値を保持する。
- [x] 選択StayだけCalloutを表示する。
- [x] 信頼度Formatterをテストする。
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

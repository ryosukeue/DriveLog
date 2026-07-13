# [UI Test] Map Callout導線を追加する

## Summary

Day DetailのMap PreviewからFull Mapへ遷移し、Movement／Stay CalloutとMap操作導線をUI Testで確認する。

## Goal

Phase 7の地図機能が実App NavigationとV1 Fixtureで操作可能であることを保証する。

## Non-Goals

- 分類／Stay修正、Media、削除

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 7-1〜7-9

## Scope

### Allowed Changes

- `issues/7-10-map-ui-test.md`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayMapPreview.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

### Forbidden Changes

- Schema、Repository、Processing、Signing、Project設定、外部Package

## Requirements

1. Day Map Preview TapをFullRouteMapViewへPushする。
2. UI FixtureへV1 MovementSegmentModelとStaySegmentModelを追加する。
3. Fixture RouteはPropertyListRouteEncoderで生成する。
4. UI TestでFull Map、Movement Label／Callout、Stay／Callout、排他切替、現在地Buttonを確認する。
5. Navigation BackでDay Detailへ戻れる。
6. FixtureはDEBUG、明示Launch Argument、in-memory Containerへ隔離する。

## Acceptance Criteria

- [x] PreviewからFull Mapへ遷移できる。
- [x] MovementとStay Calloutを切り替えられる。
- [x] 一度に1つだけCalloutを表示する。
- [x] 現在地Buttonが存在する。
- [x] Build、Unit Test、UI Test、Lint、Format、Diff Checkが成功する。

## Decisions

- `ContentRoute.fullMap`へ`MapScene`を保持し、遷移と表示データを同一のNavigation path要素として扱う。
- MapKit子要素をiOS 26 SimulatorのAccessibility階層へ安定して公開するため、ContainerとSwiftUIのAccessibility操作表現を併用する。
- Accessibility上の現在地操作はrequest IDを更新し、実際の`MKMapView`を`.follow`へ変更する。

## Deviations

- UI TestはIssue作成時に想定していた`routeMap.full`ではなく、Navigation BackとMap操作要素の存在でFull Map遷移を確認する。iOS 26 Simulatorでは`UIViewRepresentable`ルートのidentifierが安定して公開されないため。

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

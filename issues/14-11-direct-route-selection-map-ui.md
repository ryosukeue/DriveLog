# [Map] Polyline直接選択とCallout UIを統一する

## Summary

経路上の距離・時間ラベルを廃止してPolylineを直接選択できるようにし、MovementとStayの詳細表示を同じSystem MaterialベースのUIへ統一する。

## Goal

地図上の選択入口と情報階層を単純化し、MovementとStayを一貫した操作・外観で確認できるようにする。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `issues/14-5-stay-override-ui.md`
- [x] `issues/14-10-movement-callout-polish.md`

## Scope

### Allowed Changes

- `issues/14-11-direct-route-selection-map-ui.md`
- `docs/ui-spec.md`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapMovementCalloutView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapStayCalloutView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapMetricsView.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

### Forbidden Changes

- Domain、Data、Processing、SwiftData Schema
- 経路・平均速度・Stay判定計算
- Stay OverrideのUseCase、Repository、Schema
- 写真Annotation、Project設定、Signing、外部Package

## Requirements

1. Full MapではMovement Label Annotationを表示しない。
2. Polylineの22pt相当のHit領域を直接タップして経路を選択する。
3. 選択中Polylineは既存どおり太く表示する。
4. Movement Calloutは所要時間、開始、終了、平均速度を表示する。
5. Stay Calloutは滞在時間、到着、出発を表示する。
6. MovementとStayは同じMaterial、角丸、Shadow、Font階層を使う。
7. Stayの確定、非表示、自動判定へ戻す操作と保存状態を維持する。
8. Annotation操作をPolyline/空白Tap判定が横取りしない。
9. VoiceOver用にPolyline選択入口とCallout情報を提供する。

## Acceptance Criteria

- [x] 地図上に距離・時間のMovementボックスが表示されない。
- [x] Polyline TapでMovement Calloutが表示される。
- [x] Movementに4項目、Stayに3項目だけが表示される。
- [x] MovementとStayの外観が統一される。
- [x] Stay Override操作が維持される。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Decisions / Deviations

- `MapMovementLabel`はCallout位置と表示データとして引き続き使用するが、常設Annotationは生成しない。
- MapKit OverlayはVoiceOver要素を直接提供しないため、SwiftUI上の透明なAccessibility Buttonを`map.polyline`として維持する。
- 実線4ptに対しHit領域は既存の22ptを維持し、細い経路も押しやすくする。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Completion Report Format

- Summary
- Changed Files
- Tests Added
- Build Result
- Test Result
- SwiftLint Result
- SwiftFormat Result
- Manual Verification
- Deviations
- Unresolved Issues

## Completion

- 常設Movement Annotationと専用Viewを削除し、Polylineの直接Tapだけを視覚的な選択入口にした。
- Polylineは既存の22pt Hit領域、選択時7pt表示を維持した。
- Movementは所要時間・開始・終了・平均速度、Stayは滞在時間・到着・出発だけを表示する。
- 両Calloutを共通のSystem Material、16pt角丸、Shadow、caption/title3階層へ統一した。
- Stayの確定・非表示・自動判定、保存中無効化、Accessibilityを維持した。
- Annotation/Button上のTapをPolyline/空白Tap recognizerが横取りしないようGesture Delegateを追加した。
- Build成功。Unit/Integration 385件、UI/Performance/Launch 13件がすべて成功した。
- SwiftLint 0 violation、SwiftFormat、`git diff --check`成功。
- Simulator UI TestでPolyline用Accessibility入口からMovement Calloutを開き、Stay選択で切り替わることを確認した。実機で線上を指で直接Tapする操作感は未確認。

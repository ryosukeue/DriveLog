# [Map] Polyline選択中の地図Gestureと場所選択を安定化する

## Summary

全画面地図でPolylineを選択した後もPan／Pinch Zoomを継続できるようにし、地図操作中に未選択のMedia／Stay場所Sheetが開く誤作動を防ぐ。

## Background

全画面地図の上にはVoiceOverとUI Test用の透明な44pt ButtonがMovement、Stay、Mediaの件数分配置されている。これらが通常のTouchを受け取るため、密な地図ではPinchの片方または両方のTouchをMapKitへ渡さず、透明なMedia ButtonがTapとして成立すると場所Sheetが開く。

Polyline用`UITapGestureRecognizer`もMapKit内部Gestureとの同時認識を一律で許可しているため、Pan／Pinchと区間選択・空白選択解除が競合できる。

## Goal

通常のTouchは常に地図へ渡し、MapKitのNavigation GestureがPolyline・場所選択より優先されるようにする。

## Required Documents

- [x] `AGENTS.md`
- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `issues/14-13-map-selection-reliability.md`
- [x] `issues/18-4-media-preview-stability.md`

## Scope

### Allowed Changes

- `issues/18-5-map-gesture-selection-stability.md`
- `docs/ui-spec.md`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Polyline.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLogTests/Features/RouteMapPolylineSelectionTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`
- `DriveLog/DriveLogUITests/DriveLogFeedbackUITests.swift`
- `DriveLog/DriveLogUITests/July17MapBackUITests.swift`

### Forbidden Changes

- SwiftData Schema、Media Cache、PhotoKit、Processing、Location取得
- Polyline生成、Stay判定、Mediaの場所Grouping
- Project設定、Signing、Capability、外部Package

## Requirements

1. VoiceOver用透明Controlは通常のTouchを横取りしない。
2. Full MapのMapKit ViewをUI Testから直接操作可能にする。
3. Polyline TapはPan、Pinch、Rotationより後にだけ判定する。
4. Navigation Gesture中に発生したAnnotation選択は場所Sheetを開かない。
5. Navigation Gesture後の新しい明示TapではMedia／Stay選択を再び許可する。
6. Polylineの44pt Hit領域、選択強調、Calloutを維持する。
7. VoiceOverのPolyline、Stay、Media、現在地操作を維持する。

## Acceptance Criteria

- [x] Polyline選択後も繰り返しPan／Pinch Zoomできる。
- [x] Pan／Pinch Zoomで場所SheetやMedia Previewが開かない。
- [x] 明示的なPolyline、Stay、Media Tapは従来どおり動作する。
- [x] Unit／UI Test、Build、Lint、Format、Diff Checkが成功する。

## Completion Report Format

- Summary
- Root Cause
- Changed Files
- Tests Added
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion Report

### Summary

全画面地図でMapKitのPan／Pinch／Rotationを選択操作より優先し、Polyline選択後も安定して地図を移動・拡大縮小できるようにした。地図操作中に場所SheetやMedia Previewを誤表示しない。

### Root Cause

VoiceOver用の透明な44pt Buttonが通常のTouchも受け取り、密な地図でPinchを横取りしていた。Polyline用Tap GestureもMapKit内部Gestureと同時認識していたため、地図操作とPolyline／Annotation選択が競合していた。

### Changed Files

- Full Mapの補助Accessibility Controlを通常Touchの対象外にした。
- MapKitのNavigation GestureをPolyline Tapより優先し、Navigation中のAnnotation選択を抑止した。
- Full Map本体へUI Test用Identifierを追加した。
- 既存UI Testを画面上の実AnnotationとMap本体を操作する形へ更新した。
- UI仕様へGesture優先順位を追加した。

### Tests Added

- Pinch／PanがPolyline Tapより優先されるUnit Test。
- Navigation中の場所選択を抑止し、次の明示Tapでは復帰するUnit Test。
- Polyline選択後の拡大・縮小で場所Sheet／Media Previewが開かないUI Test。

### Verification

- `DriveLogTests`: 452 tests passed。
- 地図関連UI Test: 4 tests passed。
- iPhone 15向けDebug Build成功。
- SwiftLint、SwiftFormat、Diff Check成功。

### Manual Verification

修正版を接続中のiPhone 15へInstallし、起動成功を確認した。実端末上の指操作による最終確認はユーザーへ引き継ぐ。

### Deviations

なし。

### Unresolved Issues

なし。

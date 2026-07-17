# [Map] 場所PopupとStay Clusterを統一する

## Summary

Stayのみ、Mediaのみ、StayとMediaの3状態を同じ場所Popupで表示し、縮小時に複数のStay時間表示をClusterへまとめる。

## Goal

地図の拡大率や場所の内容によって操作とPopupが変わらず、Stayラベルが重ならない表示にする。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/14-3-media-annotation-reliability.md`
- [x] `issues/14-13-map-selection-reliability.md`

## Allowed Changes

- `issues/15-2-place-popup-and-stay-clustering.md`
- `docs/ui-spec.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

## Forbidden Changes

- SwiftData Schema、Processing、Media Cache、PhotoKit
- Polyline hit test、Movement Callout
- Signing、外部Package

## Decision

MediaとStayは近接時に既存150m規則で統合済みのため、StayだけへMapKit clustering identifierを付与する。Mediaは既存Media clusterを維持し、両方のCluster選択結果を同じ`MapPlaceSelection`へ変換する。単体Annotationも直接Preview/Stay Calloutへ分岐せず、同じ場所Popupを開く。

## Requirements

1. Stay Annotationは縮小時にStay同士でCluster化する。
2. Stay Clusterは回数と合計時間を表示する。
3. Cluster選択ではMedia IDとStay IDを型別に正しく分離する。
4. Stayのみ、Mediaのみ、両方の単体/Clusterは同じ場所Popupを開く。
5. 場所Popup内のMediaからPreviewへ遷移できる。
6. 位置情報、Identifierをログへ追加しない。

## Acceptance Criteria

- [x] 縮小時にStay時間表示が重ならない。
- [x] 3種類の場所内容が同じPopup構造で開く。
- [x] Media/Stay IDが混同されない。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Completion Report Format

- Summary
- Decision
- Changed Files
- Tests Added
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion

- Stay同士をMapKit Clusterへまとめ、回数と合計滞在時間を1つのAnnotationで表示した。
- Stayのみ、Mediaのみ、StayとMediaの選択を同じ「この場所」Sheetへ統一した。
- Cluster内のMedia IDとStay stable IDを型別に抽出するRegression Testを追加した。
- Simulator UI TestでPolyline詳細、Stay Popup、写真と滞在を含むMedia Clusterを操作確認した。
- Build、全Test、SwiftLint strict、SwiftFormat lint、`git diff --check`は成功した。

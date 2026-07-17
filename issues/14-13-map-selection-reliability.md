# [Map] Cluster遷移とPolyline選択を確実にする

## Goal

実写真のClusterをタップしたら必ず構成Media一覧を開き、Polylineをタップしたら確実に選択強調と詳細Calloutを表示する。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `issues/14-3-media-annotation-reliability.md`
- [x] `issues/14-11-direct-route-selection-map-ui.md`
- [x] `issues/14-12-map-selection-emphasis.md`

## Allowed Changes

- `issues/14-13-map-selection-reliability.md`
- `docs/ui-spec.md`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Polyline.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Places.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapMovementCalloutView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapStayCalloutView.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapPolylineSelectionTests.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

## Forbidden Changes

- SwiftData Schema、Media Cache、PhotoKit Asset、Processing
- Location取得、経路生成、Stay Override内部実装
- Project設定、Signing、外部Package

## Root Cause

1. Cluster tapは全構成Mediaの座標が完全一致した場合だけ場所Sheetを開き、実写真で一般的な微小座標差があるClusterはZoomだけ行っていた。
2. Polylineの太さとopacityはRenderer生成時だけ設定され、選択ID変更時は`setNeedsDisplay()`のみでStyle値を更新していなかった。
3. Movement Calloutの表示優先度がMedia Annotationより低く、同じ場所ではMapKitの衝突回避により隠れる可能性があった。
4. Hit領域が22ptで、指による実機操作には狭かった。
5. Clusterから開く場所Sheetに、削除済みのStay修正Menuが残っていた。

## Requirements

1. Media Clusterは座標差に関係なくタップで構成Mediaと関連Stayの場所Sheetを開く。
2. Clusterの件数表示とStay要約を維持する。
3. 場所SheetのMediaはタップでMedia Previewへ遷移する。
4. 場所SheetからStay修正操作を削除する。
5. Polyline選択変更時に既存Rendererへ太さとopacityを再適用する。
6. Polyline Hit領域を44ptにする。
7. MapKit内部GestureとPolyline Tapを同時認識可能にする。
8. Movement Calloutを最前面・必須表示にし、Mediaとの衝突で消えないようにする。
9. 選択解除時は全Polylineを通常Styleへ戻す。

## Acceptance Criteria

- [x] 微小座標差のあるClusterも場所Sheetを開く。
- [x] SheetにMedia件数分の項目とStay要約が表示される。
- [x] Stay修正Menuが表示されない。
- [x] Polyline Tap後に選択StyleとCalloutが表示される。
- [x] 選択解除で通常Styleへ戻る。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Decisions / Deviations

- Issue 14-3の「通常ClusterはZoom」を実機フィードバックで置き換え、全Clusterを一覧表示へ統一する。Zoomと一覧の予測不能な分岐をなくすためである。
- Clusterの代表Thumbnail、件数、Stay要約の表示仕様は維持する。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Completion Report Format

- Summary
- Root Cause
- Changed Files
- Tests Added
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion

- Root causeだったCluster座標の完全一致分岐を削除し、すべてのMedia Cluster Tapで場所Sheetを開くよう統一した。
- 代表Thumbnail、件数、Cluster下のStay回数・合計時間を維持した。
- 場所Sheetから残存していたStay修正Menuを削除し、Media Preview遷移を維持した。
- Polyline選択ID変更時に既存Rendererへ太さ・opacityを再適用するよう修正した。
- Hit TestをMapKit Renderer Path依存から画面座標の線分距離判定へ変更し、44pt幅を保証した。
- MapKit内部Gestureとの同時認識を許可し、Annotation/UIControl Tapは横取りしない。
- Polyline Tap直後に選択StyleとCalloutを即時反映し、CalloutをTap位置へ配置した。
- Movement/Stay Calloutを必須表示・最前面へ設定し、Mediaとの衝突で消えないようにした。
- 完全一致・微小座標差Cluster、44pt境界、Style再適用、実線TapからCallout生成をUnit Testで確認した。
- Build成功。全Unit/Integration/UI/Performance/Launch Test成功。SwiftLint 0 violation、SwiftFormat、`git diff --check`成功。
- Simulator UI TestでCluster Sheet、Media 2件、Stay表示、修正Menu不在、Photo Preview遷移を確認した。
- 接続中のiPhone 15向けBuildと上書きインストールは成功した。端末がLock中だったため自動起動だけはOSに拒否され、実写真と指によるPolyline Tap感は追加確認対象。

# [Media] 位置情報付きMedia Annotationを確実に表示する

## Summary

位置情報付きの写真・動画をDay Detail PreviewとFull Mapへ表示し、Thumbnail取得に失敗してもAnnotationを維持する。各処理段階は個人情報を含まない件数で診断可能にする。

## Background

調査の結果、PhotoKit取得、日付Cache、Media Placement、MapScene生成は実装済みで、500m閾値はAnnotation除外ではなくMovement関連付けだけに使用されている。一方、Day Detail Previewは`MapScene`を渡す際に別のMedia配列を渡しておらず、`RouteMapCoordinator.addAnnotations`が空の`mediaByIdentifier`との再照合でScene内の全Media Annotationを破棄していた。これは実機でAnnotationが表示されない直接原因である。

Thumbnail Viewには角丸、動画Badge、Cluster、失敗時Iconが既にあるため維持する。Scene Annotation自身へMedia種別を持たせ、描画可否を別snapshotへ依存させない。

## Goal

MapSceneに配置された位置情報付きMediaを、補助Media snapshotやThumbnail成否に関係なく地図へ表示する。

## Non-Goals

- 位置情報のないMediaを地図へ表示すること
- 500mのMovement関連付け閾値変更
- SwiftData Schema変更
- 写真Assetの変更または削除

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 14-1

## Scope

### Allowed Changes

- `issues/14-3-media-annotation-reliability.md`
- `DriveLog/DriveLog/Application/Media/RefreshMediaCacheUseCase.swift`
- `DriveLog/DriveLog/Domain/Entities/MediaPlacement.swift`
- `DriveLog/DriveLog/Domain/Entities/MapScene.swift`
- `DriveLog/DriveLog/Processing/Media/MediaPlacementCalculator.swift`
- `DriveLog/DriveLog/Features/Map/MapSceneBuilder.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapViewModel.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Places.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`（UI Test fixtureのみ）
- `DriveLog/DriveLog/Shared/Logging/LogEvent.swift`
- `DriveLog/DriveLog/Shared/Logging/OSLogLogger.swift`
- 対応する`DriveLogTests/`ファイル

### Forbidden Changes

- SwiftData V1 Schema
- PhotoKit Asset本体
- Signing、Team、Bundle Identifier
- 外部Package
- 位置情報のないMediaの地図表示

## Requirements

1. `MapMediaAnnotation`がMedia種別を保持する。
2. Map描画は別のMedia配列との再照合を表示条件にしない。
3. 写真は角丸正方形、動画は再生Icon付きで表示する。
4. MediaだけをCluster化し、タップ時は既存Preview導線を使用する。
5. Thumbnail失敗時もfallback Iconを表示する。
6. 位置情報なしMediaはGridへ残し、地図へは配置しない。
7. 権限、取得、適格、位置付き、配置の状態を固定codeと件数だけで診断する。
8. 座標とPhotoKit localIdentifierをログへ出さない。
9. Media clusterは代表Thumbnailを表示し、その下に件数を表示する。
10. 通常のcluster tapは既存どおり構成Mediaが見える範囲へ拡大する。
11. 全構成Mediaの座標が完全一致するclusterは拡大で分離不能なため、tapでMedia gridを表示する。
12. Media annotationの表示優先度を維持し、広域表示でも単体またはclusterのどちらかを表示する。
13. Cluster範囲はMapKitの画面上の衝突判定に従い、拡大縮小に応じて動的に変化する。
14. 150m以内のMediaとStayを同一場所として扱い、Media表示の下にStay要約を統合する。
15. 同一場所への複数Stayは1つへまとめ、回数と合計滞在時間を表示し、個別Stay操作は一覧から維持する。

## Acceptance Criteria

- [ ] Previewへ位置情報付きMedia Annotationが表示される
- [ ] Full MapでThumbnail、動画Badge、Cluster、Preview遷移が維持される
- [ ] Thumbnail失敗でもAnnotationが消えない
- [ ] 位置情報なしMediaは地図に出ずGridに残る
- [ ] Privacy-safeな段階別診断Testが成功する
- [ ] Build/Test/Lint/Format/diff checkが成功する
- [ ] 新規Warningと仕様外変更がない

## Test Requirements

- MapSceneがMedia種別を保持する
- 空の補助Media snapshotでもScene Annotationを追加する
- Media Placementが位置情報なしだけを除外する
- 診断Eventが権限codeと各件数を記録する
- 既存Cluster、Thumbnail fallback、Preview UI Testを維持する

## Decisions / Deviations

- 500mは表示閾値ではなく関連Movement選択だけに使用されるため変更しない。
- PreviewはThumbnail loaderを持たないためfallback Iconを表示する。Full Mapでは実Thumbnailを非同期取得する。
- 実PhotoKit limited selection、iCloud未Download、実写真のCluster/Previewは実機確認対象とする。

## Completion Report Format

- Summary
- Root cause
- Changed files and reasons
- Tests added
- Build/Test/Lint/Format/diff results
- Manual verification
- Deviations
- Unresolved issues

## Completion

- Root causeだった`MapScene`と空の補助Media snapshotの再照合を除去し、Scene Annotation自身がMedia種別を保持するようにした。
- 位置情報付きMediaはPreviewでもfallback Iconとして表示され、Full Mapでは既存のThumbnail、動画Badge、Cluster、Preview遷移を使用する。
- 権限code、取得、適格、位置付き/配置の件数を座標・Identifierなしで診断する。
- 500m閾値は表示除外に使われていなかったため変更していない。
- Build成功。全399 Testが成功し、SwiftLint、SwiftFormat、`git diff --check`も成功した。
- Simulator UI TestでCluster、Annotation tap、Media Previewを確認した。実写真、Limited権限、iCloud Thumbnailは実機未確認。
- XcodeのAppIntents metadata skip、DebuggerVersionStore、Simulator accessibility重複classは環境由来Warningで、新規Source Warningはない。

## Device Feedback Follow-up（2026-07-16）

- 赤い件数markerではなく、代表Thumbnailと件数を常時表示する。
- 完全同一座標clusterだけはtapでgridを開き、通常clusterのzoom動作は維持する。
- Mediaの表示優先度を上げ、広域でも単体またはclusterとして確認可能にする。
- 写真があるStayは写真表示へ要約を統合し、重複Stayは回数と合計時間へ集約する。

### Follow-up Completion

- Clusterと単体Mediaを代表Thumbnailで表示し、Thumbnail下へ件数、その下へStay回数と合計時間を表示する。
- MapKitの画面上の衝突判定で拡大率に応じてcluster範囲を変え、Media表示優先度を`required`にした。
- 完全同一座標clusterはMedia gridと個別Stay操作を含む場所Sheetを開き、異なる座標を含むclusterは従来どおりzoomする。
- 150m以内のStayをMediaへ統合し、Mediaがない同一場所の複数Stayも1 markerへ集約する。
- Simulator UI Testで代表clusterから場所Sheet、2件のMedia grid、Stay修正、写真Previewへの遷移を確認した。
- Build成功。全396 Test（UI Test 13件を含む）、SwiftLint、SwiftFormat、`git diff --check`が成功した。
- 実PhotoKit Thumbnail、実データでの広域表示密度、実機上のタップ感は未確認。

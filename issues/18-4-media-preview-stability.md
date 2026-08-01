# [Media] 地図とギャラリーのPreview遷移を安定化する

## Summary

地図の場所Sheetから写真・動画を開く際のPresentation競合をなくし、ギャラリーと地図のどちらからでも全画面Previewへ確実に遷移できるようにする。同じ場所のMediaは左右Swipeで連続表示する。

## Background

場所Sheetを閉じるState更新とNavigation pushを同時に行っており、実機で地図から写真を開くと固まることがある。月間全画面地図では、表示中の`fullScreenCover`の背面から別の`fullScreenCover`を重ねていた。単体Annotationの選択元配列も1件だけだった。

## Goal

現在のPresentationを閉じた後にだけPreviewへ遷移し、選択地点の写真・動画を標準Page TabViewでSwipeできるようにする。

## Non-Goals

- ピンチZoom、写真編集、Media削除
- PhotoKit Provider、Cache、SwiftData Schemaの変更
- Page TabViewを置き換える独自Paging UIの追加

## Required Documents

- [x] `AGENTS.md`
- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/15-2-place-popup-and-stay-clustering.md`
- [x] `issues/15-3-media-preview-paging.md`
- [x] `issues/16-3-monthly-overview-map-gallery.md`

## Scope

### Allowed Changes

- `issues/18-4-media-preview-stability.md`
- `docs/ui-spec.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/Features/Calendar/MonthlyOverviewView.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapViewModel.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewView.swift`
- `DriveLog/DriveLogTests/Features/RouteMapViewModelTests.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`
- `DriveLog/DriveLogUITests/DriveLogFeedbackUITests.swift`
- `DriveLog/DriveLogUITests/July17MapBackUITests.swift`

### Forbidden Changes

- PhotoKit Provider、Media Cache、SwiftData Schema
- MapKit clustering方式、Polyline、Stay保存
- Signing、Capability、外部Package

## Requirements

1. 場所Sheet内のMedia選択時はSheetのdismiss完了後にPreview遷移を通知する。
2. 月間全画面地図のMedia選択時は地図coverのdismiss完了後にPreview coverを表示する。
3. 月間ギャラリーのセル選択は直接Previewを表示する。
4. 同じ場所は既存Stay半径と同じ150m以内として扱う。
5. 単体Annotationの場所Contextにも150m以内のMediaを含める。
6. Cluster Contextは既存memberに加え、各memberから150m以内のMediaを含める。
7. Previewは選択Mediaから始まり、選択元順の写真・動画を左右Swipeする。
8. Previewの戻るボタン、共有対象、動画停止を維持する。

## Accessibility Requirements

- `map.placeSheet`、`mediaPreview.back`、`mediaPreview.photo`、`mediaPreview.video`を維持する。
- 戻るボタンは44pt以上で操作可能にする。
- localIdentifierや座標をLabelへ含めない。

## Privacy Requirements

- 写真・動画本体を永続化しない。
- localIdentifier、座標、ファイル名をLoggerへ出力しない。
- 外部通信を追加しない。

## Test Requirements

- Unit Testで同一場所のMedia Contextと遠方除外を確認する。
- UI Testで場所SheetからPreviewへ遷移し、左右Swipeできることを確認する。
- UI Testで月間全画面地図からPreviewへ遷移し、戻れることを確認する。
- Build、Test、Lint、Format、Diff Checkを成功させる。

## Acceptance Criteria

- [x] 地図から写真・動画を開いて固まらない。
- [x] ギャラリーセルから拡大Previewへ遷移する。
- [x] 同じ場所のMediaを左右Swipeできる。
- [x] Previewを戻るボタンで閉じられる。
- [x] 自動検証が成功する。

## Completion Report Format

- Summary
- Root Cause
- Presentation Sequence
- Paging Context
- Changed Files
- Tests Added
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion Report

### Summary

場所Sheetと月間全画面地図を閉じ終えてからMedia Previewを表示し、Gallery、地図、動画ページのどこからでも安定して左右Pagingできるようにした。

### Root Cause

Sheet/coverのdismissと次のPresentationを同時に更新していたこと、単体AnnotationのContextが1件だけだったこと、`VideoPlayer`がPage Swipeと競合していたことが原因だった。

### Presentation Sequence

場所Sheet選択はpendingへ保持してSheetの`onDismiss`後に通知する。月間地図はpendingへ保持して地図coverの`onDismiss`後にPreview coverを表示する。

### Paging Context

既存Stay半径と同じ150m以内のMediaを撮影場所Contextへ含め、Page TabView上の水平DragをPreview全体で一貫して処理する。

### Changed Files

Monthly Overview、Full Route Map、Route Map ViewModel、Media Preview、Unit/UI Test、UI/Test文書を更新した。

### Tests Added

150m内外のContext Unit Test、Gallery Preview、月間地図からのdismiss順序、写真・動画Swipe、密集地図の操作をUI Testで確認した。

### Verification

450 Unit TestとUI Test 18本を確認し、Build、SwiftLint strict、SwiftFormat lint、Diff Checkを通過した。

### Manual Verification

iPhone 17 Simulatorで自動操作確認済み。実機確認は未実施。

### Deviations

標準Page TabViewは維持したまま、`VideoPlayer`とのGesture競合を避ける水平Drag判定を親Viewへ追加した。

### Unresolved Issues

なし。

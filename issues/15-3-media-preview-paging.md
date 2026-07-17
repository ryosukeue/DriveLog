# [Media] 選択元のMediaを左右ページングする

## Summary

Cluster内または日別Gallery内の写真・動画を開いた後、左右Swipeで同じ選択元の前後Mediaへ移動できるPreviewにする。

## Goal

Previewを閉じて再選択せず、同じ場所または同じ日の写真・動画を連続して確認できるようにする。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/14-8-simplify-primary-ui.md`
- [x] `issues/15-2-place-popup-and-stay-clustering.md`

## Allowed Changes

- `issues/15-3-media-preview-paging.md`
- `docs/ui-spec.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewView.swift`
- `DriveLog/DriveLogTests/Features/MediaPreviewViewModelTests.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

## Forbidden Changes

- PhotoKit Provider、Media Cache、SwiftData Schema
- Media本体の保存・削除
- 外部Package、Signing

## Decision

Preview routeへ「選択Media」だけでなく「選択元Media配列」を渡す。日別Galleryでは当日の全Media、場所Popupでは選択した場所/ClusterのMediaだけをContextとする。SwiftUI標準Page TabViewを使用し、独自Gesture競合を作らない。

## Requirements

1. 日別Galleryからは当日のMediaを作成日時順のままページングする。
2. 場所PopupからはそのPopupに含まれるMediaだけをページングする。
3. 選択したMediaからPreviewを開始する。
4. 写真、動画、読込失敗の各Pageを独立して表示する。
5. Page切替時に動画再生を停止する。
6. 共有は現在表示中のMediaを対象にする。
7. 戻る操作は上部左の矢印を使用する。

## Acceptance Criteria

- [x] Cluster内の複数Mediaを左右Swipeできる。
- [x] 日別Galleryの複数Mediaを左右Swipeできる。
- [x] 選択位置と共有対象が一致する。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Completion Report Format

- Summary
- Paging Context
- Changed Files
- Tests Added
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion

- 日別Galleryは当日の全Media、場所Popupはその場所のMediaをPreview contextとして渡すようにした。
- 標準Page TabViewで写真・動画・読込失敗を左右Swipeでき、Page切替時に前の動画を停止する。
- 共有対象を現在Pageへ追従させ、戻る入口を上部左矢印へ統一した。
- Simulator UI Testで日別Galleryの3 PageとCluster内の写真・動画Pageを実際にSwipeした。
- Build、全Test、SwiftLint strict、SwiftFormat lint、`git diff --check`は成功した。

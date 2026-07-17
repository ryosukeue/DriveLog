# [UI] 日付ページ遷移と全画面地図Chromeを整理する

## Summary

Calendarの日付を下から現れる日付ページとして表示し、下SwipeでCalendarへ戻れるようにする。記録日は左右Page Swipeで切り替え、全画面地図は地図と半透明の戻る矢印だけにする。

## Goal

Calendar、日付ページ、地図、Media Previewの階層を、画面の方向と戻り方が予測できる一貫したNavigationへ整理する。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/14-7-continuous-calendar.md`
- [x] `issues/14-8-simplify-primary-ui.md`
- [x] `issues/15-3-media-preview-paging.md`

## Allowed Changes

- `issues/15-4-day-navigation-and-map-chrome.md`
- `docs/ui-spec.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/Features/Calendar/CalendarViewModel.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLogTests/Features/CalendarViewModelTests.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

## Forbidden Changes

- Domain/Data/Processing/SwiftData Schema
- Calendarの縦連続月Scroll
- 外部Animation/Navigation Package
- Signing、Deployment Target

## Decision

Calendarから日付ページはSwiftUI標準のlarge Sheetで表示する。これにより標準の下からのTransitionと下Swipe dismiss、Reduce Motion対応を得る。Sheet内は記録日のみをPage TabViewへ並べ、横Swipeで前後の記録日を切り替える。全画面地図はNavigation Barを隠し、Safe Area内の半透明な左矢印だけを戻る入口にする。

UI Testでは日付Page Swipeを検証できるよう、UI Test専用Storeに翌日の有効日Summaryも追加する。Production dataやSchemaは変更しない。

## Requirements

1. 日付選択時は標準Sheet transitionで下から表示する。
2. 日付ページは下SwipeでCalendarへ戻れる。
3. 記録日のPageは左右Swipeで切り替わる。
4. 記録のない日はPageへ含めない。
5. 全画面地図の上部Barと「経路」を表示しない。
6. 全画面地図は半透明背景の左矢印だけを戻る入口として表示する。
7. Media Previewも上部左矢印を戻る入口とする。
8. Reduce Motion、VoiceOver、Dynamic Typeを標準Componentへ委ねる。

## Acceptance Criteria

- [x] Calendar→日付ページが下から表示される。
- [x] 下SwipeでCalendarへ戻る。
- [x] 左右Swipeで前後の記録日へ移動する。
- [x] 全画面地図が画面全面を占め「経路」文字と上部縁がない。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Completion Report Format

- Summary
- Navigation Model
- Changed Files
- Tests Added
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion

- Calendarの日付選択を標準large Sheetへ変更し、下からの表示と下Swipe dismissを実現した。
- 有効移動日のみを左右Page Swipe対象とし、選択日をCalendar状態へ同期した。
- 全画面地図のNavigation Barと「経路」を削除し、Safe Area内の半透明左矢印だけを残した。
- UI Test専用Storeだけに翌日の有効Summaryを追加し、日付Swipeと下Swipe復帰を自動検証した。
- Unit/Integration 393件、UI/Launch/Performance 13件が成功した。
- Build、SwiftLint strict、SwiftFormat lint、`git diff --check`は成功した。

# [UI] 日付Swipe中の操作Menuを一意に保つ

## Summary

日付ページを左右Swipeした際、前後の`DayDetailView`が持つToolbarが同時に描画され、「その他の操作」Buttonが2個見える問題を修正する。

## Goal

Page transition中を含め、日付ページのNavigation titleと操作Menuを常に1組だけ表示する。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/10-4-day-detail-delete-menu.md`
- [x] `issues/15-4-day-navigation-and-map-chrome.md`

## Allowed Changes

- `issues/15-11-stable-day-detail-toolbar.md`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

## Forbidden Changes

- Delete UseCase、Repository、SwiftData Schema
- 日付Swipe、Calendar Sheet、全画面地図の仕様
- Signing、Deployment Target、外部Package

## Investigation

`DayDetailPagerView`の全Pageが、それぞれ`DayDetailView`内でNavigation titleとToolbar Menuを登録していた。SwiftUIのPage transitionは前後Pageを同時に描画するため、interactive Swipe中に双方のToolbar itemが合成されていた。

## Decision

Navigation title、Menu、削除確認、削除Error presentationを、Page contentではなく安定して1つだけ存在する`DayDetailPagerView`へ移す。削除対象は確認を開始した時点の日付として保持し、Swipeによる対象の取り違えを防ぐ。

## Requirements

1. Swipe中も`dayDetail.menu`は1個だけ存在する。
2. Navigation titleは現在表示中の日付へ追従する。
3. 削除確認、削除Progress、成功後のCalendar復帰、失敗Alertを維持する。
4. 削除確認後は、確認開始時の日付を削除する。
5. `DayDetailView`はPage固有contentだけを表示する。

## Acceptance Criteria

- [x] 日付ページでMenuが1個だけ表示される。
- [x] 日付Swipe後もMenuが1個だけ表示される。
- [x] 表示日タイトルと削除対象が一致する。
- [x] 既存の削除UI Testが成功する。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

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

- Pageごとに登録していたNavigation titleとToolbarを`DayDetailPagerView`へ集約した。
- 削除確認を開始した日付を保持し、削除対象がSwipe後の選択状態へ引きずられないようにした。
- UI TestへSwipe前後の`dayDetail.menu`個数検証を追加した。
- Unit/Integration 404件、UI/Launch/Performance 13件が成功した。
- Build、SwiftLint strict、SwiftFormat lint、`git diff --check`が成功した。
- SimulatorではMenuの一意性と削除導線を確認した。interactive Swipe途中の見た目は実機確認対象とする。
- Xcode/Simulator由来のDebugger version store、Accessibility bundle重複、AppIntents metadata、CoreLocation main-thread diagnostics以外に新規Warningはない。

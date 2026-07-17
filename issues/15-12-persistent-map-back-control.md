# [UI] 全画面地図の戻るControlを常時維持する

## Summary

7月17日の日付ページから全画面地図を開いた後、左上の戻る矢印が見えなくなる実機問題を修正する。

## Goal

地図、経路、Annotation、場所Sheetの更新状態にかかわらず、全画面地図の戻るControlを常に表示し、日付ページへ確実に戻せるようにする。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/15-4-day-navigation-and-map-chrome.md`
- [x] `issues/15-11-stable-day-detail-toolbar.md`

## Allowed Changes

- `issues/15-12-persistent-map-back-control.md`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

## Forbidden Changes

- Map data、Polyline、Annotation、Media、Stay behavior
- Sheet/Navigation hierarchyの変更
- SwiftData Schema、Signing、Deployment Target、外部Package

## Investigation

- UI Test用の7月17日を開き、経路選択、滞在場所Sheet、地図復帰まで実行すると、Simulatorでは既存の戻るButtonは操作できた。
- 戻るActionはdestination内のEnvironment `dismiss`へ委ねられ、表示もMapKitを含む同一`ZStack`内に置かれていた。
- PageごとのToolbar競合はIssue 15-11で除去したが、実機報告を回帰Testとして固定し、戻り先と表示階層を明示する必要がある。

## Decision

戻るActionは`ContentView`が所有するNavigation pathから最後のdestinationを明示的に除去する。戻るButtonはMap contentの兄弟ではなく、全画面地図の最上位overlayへ置き、MapKit更新から独立させる。半透明の丸い外観は維持しつつ、foregroundと境界を明示して地図色に埋もれないようにする。

## Requirements

1. 7月17日の全画面地図で戻るButtonが表示される。
2. 経路選択後も戻るButtonが表示される。
3. 場所Sheetを閉じた後も戻るButtonが表示される。
4. ButtonはNavigation pathを1段戻し、日付ページへ戻る。
5. 地図全面表示と半透明の矢印だけという既存仕様を維持する。
6. 44pt以上の操作領域とVoiceOver labelを維持する。

## Acceptance Criteria

- [x] 7月17日の地図を開いた直後に戻るButtonが1個表示される。
- [x] 経路/滞在操作後もButtonが表示され操作できる。
- [x] 戻ると同じ日付ページを表示する。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Completion Report Format

- Summary
- Investigation
- Changed Files
- Tests Added
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion

- 全画面地図の戻るControlをMap contentの最上位overlayへ分離し、MapKitの再描画から独立させた。
- foreground、半透明Material、細い境界を明示し、地図の配色に埋もれにくくした。
- Environment `dismiss`をやめ、`ContentView`が所有するNavigation pathを明示的に1段戻すようにした。
- 7月17日のUI Testで、表示直後、経路選択後、滞在場所Sheetを閉じた後の存在と操作可能性を検証した。
- Unit/Integration 404件、UI/Launch/Performance 13件が成功した。
- Build、SwiftLint strict、SwiftFormat lint、`git diff --check`が成功した。
- 実機は未接続のため未確認。7月17日の実データで戻るControlが維持されることは実機確認対象とする。
- Xcode/Simulator由来のDebugger version store、Accessibility bundle重複、AppIntents metadata、CoreLocation main-thread diagnostics以外に新規Warningはない。

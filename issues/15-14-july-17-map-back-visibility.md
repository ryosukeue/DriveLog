# [UI] 7月17日の全画面地図で戻るControlを確実に表示する

## Summary

他の日付では表示される全画面地図の戻るControlが、7月17日の実機データでは見えない問題を再調査し、日付やMap内容に依存せず表示・操作できるようにする。

## Background

Issue 15-12で戻るControlをMap contentのSwiftUI overlayへ移したが、回帰UI Testは7月17日ではなく最初の有効日を選んでいた。2026年7月18日の実行では7月18日が選ばれており、報告された条件を検証できていなかった。

接続端末から読み取った件数では、7月17日はMovement 7件、Stay 18件、位置付きMedia 2件を持ち、他の日よりMap内容が多い。ただし、実座標やMedia identifierはTest Fixtureへコピーしない。

## Goal

7月17日相当の複数経路・多数Stay・Mediaを持つ全画面地図でも、戻るControlをSafe Area内の最前面へ常時1個表示する。

## Non-Goals

- Map data、Polyline、Stay、Mediaの表示規則変更
- Navigation階層、日付Swipe、場所Sheetの仕様変更
- 実機データのTest Fixtureへの複製

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/15-4-day-navigation-and-map-chrome.md`
- [x] `issues/15-11-stable-day-detail-toolbar.md`
- [x] `issues/15-12-persistent-map-back-control.md`

## Dependencies

- Issue 15-12

## Allowed Changes

- `issues/15-14-july-17-map-back-visibility.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/UITestSupport/DriveLogApp+MapBackUITestSupport.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`
- `DriveLog/DriveLogUITests/July17MapBackUITests.swift`

## Forbidden Changes

- Domain、Application、Data、Processing、SwiftData Schema
- RouteMapのPolyline、Annotation、Clustering、Selection behavior
- Signing、Team、Bundle Identifier、Deployment Target、外部Package
- 実座標、PhotoKit localIdentifier、写真名のLoggerまたはFixtureへの追加

## Reproduction Steps

1. Calendarで7月17日を開く。
2. 日付ページの地図を開く。
3. 全画面地図の左上を確認する。

## Actual Result

他の日付では表示される戻るControlが、7月17日の全画面地図では見えない。

## Expected Result

Map内容と日付にかかわらず、Safe Area内の左上へ半透明の戻るControlが1個表示され、日付ページへ戻れる。

## Investigation

- Issue 15-12のUI Testは`firstMatch`の有効日を選択しており、7月17日を指定していなかった。
- 2026年7月18日のTest実行では`calendar.day.2026-7-18`が選択されていた。
- 戻るControlはSwiftUI overlayとして存在するが、視認性と画面内Frameを検証していない。
- 実機DBの件数監査では7月17日のMap要素が相対的に多いが、戻るControlの表示条件に日付分岐はない。
- 匿名の同等件数Fixtureで修正前のUI Testを実行すると、`map.back`は存在するが`isHittable == false`となった。Accessibility hierarchyでは透明な補助Button列が幅1196ptへ拡張し、402pt画面上の戻るControlがx=-385ptへ押し出されていた。

## Decision

Map操作をUI TestとVoiceOverへ公開する透明な補助Control群を、画面寸法へ固定した`GeometryReader`内でlayout・clipする。Control件数が増えても親`ZStack`の寸法へ影響させず、戻るoverlayを画面左上に維持する。MapデータとAnnotation実装は変更しない。

## Requirements

1. UI Test Fixtureへ7月17日相当の固定日を追加し、日付Identifierを明示して選択する。
2. Fixtureは架空座標と架空IDだけを使用し、複数Movement、多数Stay、Mediaを表現する。
3. 戻るControlをMap内容から独立した最前面overlayへ置く。
4. ControlのFrame全体をSafe Area内に維持する。
5. Light/Darkと地図色に依存しないSystem material、foreground、境界またはshadowで視認性を確保する。
6. 44pt以上の操作領域、VoiceOver label、`map.back` identifierを維持する。
7. 戻るControlは常に1個だけ表示する。
8. 戻ると選択中の日付ページへ戻る。

## Privacy Requirements

- 実機の座標、Media identifier、ファイル名をコード、Fixture、Loggerへ追加しない。
- 診断は日付別の件数だけを使用する。
- 外部送信しない。

## UI Requirements

- 地図全面表示と半透明の左矢印だけという仕様を維持する。
- Accent Color、Dynamic Type、Light/Dark、Reduce Motionへ影響させない。

## Accessibility Requirements

- Accessibility Label: `日付ページに戻る`
- Accessibility Identifier: `map.back`
- VoiceOver: 1個のButtonとして読み上げる。
- Minimum tap area: 44pt × 44pt

## Acceptance Criteria

- [x] 7月17日をIdentifierで選ぶ回帰UI Testが修正前に問題を検出する。
- [x] 7月17日相当のMapで`map.back`が1個表示される。
- [x] `map.back`が画面内にあり操作可能である。
- [x] 戻ると7月17日の日付ページが表示される。
- [x] 他の日付の既存導線が維持される。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] Allowed Changes外の変更がない。

## Test Requirements

### UI Tests

- [x] 7月17日を明示選択する。
- [x] 多数のMap要素を読み込んだ後も戻るButtonが1個で、hittableかつ画面内にある。
- [x] 経路選択と場所Sheet復帰後も同じ条件を満たす。
- [x] 戻ると`dayDetail.currentDate`が7月17日を示す。

### Manual Tests

- [ ] 接続実機の7月17日データで表示と操作を確認する。
- [ ] Light/Darkの双方で視認できる。

## Test Fixtures

- Date: 2026-07-17相当の固定Identifier
- Coordinates: 東京周辺ではない架空の一般座標
- IDs: `ui-` prefixの架空値
- Other: 実機データの値をコピーしない

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Files Expected to Change

- `issues/15-14-july-17-map-back-visibility.md`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/UITestSupport/DriveLogApp+MapBackUITestSupport.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`
- `DriveLog/DriveLogUITests/July17MapBackUITests.swift`
- 必要な場合だけ`ContentView.swift`、`docs/test-plan.md`

## Migration Requirements

なし。SwiftData Schemaと既存保存データを変更しない。

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

7月17日を明示した匿名の高密度Map Fixtureで不具合を再現し、戻るControlを画面外へ押し出していた補助Accessibility layoutを画面寸法内へ固定した。経路選択後と場所Sheet復帰後を含め、戻るControlが常に1個、画面内、操作可能であることを回帰UI Testへ固定した。

### Root Cause

`FullRouteMapView`は、Polyline、Stay、MediaをUI TestとVoiceOverへ公開する透明な44pt Buttonを1本の`HStack`へ並べていた。7月17日はMap要素が多いため、このHStackが1196ptまで拡張して親`ZStack`の幅を押し広げた。402pt幅の画面に対して戻るControlのFrameはx=-385ptとなり、Accessibility上は存在しても画面外で`isHittable == false`だった。

Issue 15-12のTestは有効日の`firstMatch`を選び、実際には7月18日を検証していたため、この件数依存条件を検出できなかった。

### Changed Files

- `FullRouteMapView.swift`: 補助Accessibility controlsを`GeometryReader`の画面寸法へ固定し、画面外の要素をclipした。
- `DriveLogApp.swift`: 7月17日固定Fixtureの選択と既存UI Test seed接続を追加した。
- `DriveLogApp+MapBackUITestSupport.swift`: 架空座標による7 Movement、18 Stayの高密度Fixtureを分離した。
- `July17MapBackUITests.swift`: 日付、Button個数、Frame、hittable、経路選択、場所Sheet復帰、戻り先を検証した。
- `docs/test-plan.md`: Map要素数によるAccessibility layout回帰を追加した。

### Tests Added

- 修正前: `map.back`は存在するが`isHittable`検証で失敗し、Frame x=-385ptを確認した。
- 修正後: 7月17日相当の高密度Mapで同Testが成功した。
- 実機データの座標、Media identifier、写真名はFixtureへコピーしていない。

### Verification

- `./scripts/build.sh`: 成功。
- `./scripts/test.sh`: 成功。Swift Testing 407 tests / 88 suites、UI/Launch/Performance 14 executions、失敗0。
- `swiftlint lint --strict`: 成功。266 files、違反0。
- `swiftformat --lint .`: 成功。変更要求0。
- `git diff --check`: 成功。
- Allowed Changes監査: 対象外変更なし。

### Manual Verification

- 接続端末から7月17日の件数だけを読み取り、Movement 7件、Stay 18件、位置付きMedia 2件を確認した。
- 実機画面の自動監査は、Test開始時に端末がロックされていたため未実施。
- Simulatorでは7月17日相当の高密度Mapで、表示直後、経路選択後、場所Sheet復帰後のButtonを確認した。

### Deviations

Privacy要件に従い、実機データは直接Fixtureへ複製せず、件数だけを同等にした架空データで再現した。

### Unresolved Issues

修正版を実機へ入れた後、実データの7月17日で戻るControlの視認性と操作を確認する必要がある。

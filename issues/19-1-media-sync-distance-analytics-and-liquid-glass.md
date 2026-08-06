# [UI/Media] 月間Media同期・日別距離Analytics・Liquid Glass Navigationを追加する

## Summary

月間ギャラリーをPhotosの現在状態へ同期し、位置情報付きMediaだけを表示する。初回設定でCameraの位置情報設定を案内し、Calendarと日別距離Analyticsを下部Tabで切り替えられるようにする。iOS 26では標準Liquid Glass、iOS 17〜25ではMaterial fallbackを使用する。

## Background

月間表示はMedia Cacheだけを読み、Photos側で削除された参照を再検証していなかった。また、日ごとの移動距離を月単位で比較する画面と、位置情報付き写真を撮るための初回案内がなかった。

## Goal

月間の写真・動画と距離を、現在のPhotos状態および既存の徒歩除外ルールに従って正確に振り返れるようにする。

## Non-Goals

- Photos資産の削除・位置情報編集
- Cameraの位置情報権限をDriveLogから検査または変更すること
- SwiftData Schema変更
- Analytics SDK、外部通信、サーバー集計
- App Storeへの提出・公開

## Required Documents

- [x] `AGENTS.md`
- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/8-13-photo-library-change.md`
- [x] `issues/16-3-monthly-overview-map-gallery.md`
- [x] `issues/18-2-non-walking-movement-display.md`

## Scope

### Allowed Changes

- 本Issue、`docs/project-rules.md`、`docs/ui-spec.md`、`docs/test-plan.md`、`docs/implementation-plan.md`
- Monthly Overview、Photo Library change配信、Onboarding
- Application composition、root navigation
- Monthly distance Domain/Application/Feature
- Liquid Glass互換Presentation helperと既存control surface
- 関連Unit/UI Test

### Forbidden Changes

- Location取得、Movement/Stay判定、Raw Event、Override、SwiftData Schema
- Photos資産本体、Signing、Capability、Bundle Identifier、外部Package
- App Store Connect操作

## Requirements

1. 月間表示前に対象日のPhotosを再取得し、削除済み・Limited Access外の参照を日単位の完全置換で除去する。
2. refresh失敗時は既存Cacheを表示し、クラッシュや月全体の読込失敗にしない。
3. 月間ギャラリーと月間地図は、写真・動画とも位置情報付きMediaだけを使用する。
4. Photos変更通知は複数の表示購読者へ配信し、月間表示を再読込する。
5. Foreground復帰時にも現在月を再読込する。
6. OnboardingのPhotos権限案内後に、Cameraの位置情報設定手順と既存Mediaには遡及しないことを説明する。
7. RootへCalendarとAnalyticsの2 Tabを追加する。
8. Analyticsは現在月を初期表示し、過去月へ移動でき、未来月へ移動できない。
9. 選択月の1日から月末までを棒グラフにし、記録なしを0kmとして表示する。
10. 距離は既存Production規則どおり徒歩を除外し、車両系とotherを合計する。
11. 棒選択時に日付と正確な距離を表示する。
12. iOS 26では標準Liquid Glassをcontrol/navigation layerへ適用し、iOS 17〜25ではMaterialまたは標準button styleへfallbackする。データcontent cardへGlassを乱用しない。

## Accessibility / Privacy

- Tab、月移動、グラフ、初回案内へ安定したAccessibility label/identifierを付ける。
- Media identifier、座標、ファイル名をLoggerやUI labelへ追加しない。
- Photos資産を削除・変更せず、外部通信を追加しない。

## Test Requirements

- Unit Testで月間Mediaの位置情報filter、refresh優先、失敗時Cache fallbackを確認する。
- Unit Testで全日zero-fill、徒歩除外、保存済Aggregate fallback、月遷移を確認する。
- Unit TestでOnboardingのCamera位置情報案内Phaseを確認する。
- UI TestでAnalytics Tabと日別棒グラフ、Onboarding案内からCalendar到達を確認する。
- Build、全Unit/Integration/UI Test、Lint、Format、Diff Checkを実行する。

## Acceptance Criteria

- [x] 削除済みMediaが月間表示の再読込後に残らない。
- [x] 月間ギャラリーへ位置情報なしMediaが表示されない。
- [x] 初回設定でCamera位置情報の設定方法が分かる。
- [x] CalendarとAnalyticsを下部Tabで切り替えられる。
- [x] 選択月の日別距離を1日から月末まで確認できる。
- [x] 徒歩距離がAnalyticsへ含まれない。
- [x] iOS 26 Liquid Glassと旧OS fallbackがBuildできる。
- [x] 自動検証が成功する。

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

- 月間表示のPhotos再同期と位置情報filterを追加し、削除済み・Limited Access外・位置情報なしMediaを月間ギャラリーと月間地図から除外した。
- 初回設定へCameraの位置情報設定案内を追加した。
- Calendar / Analyticsの下部Tabと、選択月の日別移動距離グラフを追加した。
- iOS 26のLiquid GlassとiOS 17〜25のMaterial fallbackをcontrol/navigation layerへ適用した。

### Root Cause

- 月間表示は保存済みMedia Cacheだけを参照しており、Photos側の削除や権限範囲変更を表示前に反映していなかった。
- Photo Library変更通知が単一のAsyncStreamを共有していたため、複数画面の購読を確実にfan-outできなかった。
- RootがCalendar単画面構成で、月別の日別距離を集計・表示するApplication/Feature層がなかった。

### Changed Files

- Monthly Overview、Photo Library Provider、Onboarding、Root Tab、Analytics Domain/Application/Featureを更新・追加した。
- Liquid Glass互換helperを追加し、既存の主要control surfaceへ適用した。
- UI仕様、テスト計画、実装計画、プロジェクトルールへ本Issueの優先仕様を追記した。

### Tests Added

- 月間Mediaの位置情報filter、Photos再同期、再同期失敗時Cache fallback。
- 月別距離の全日zero-fill、徒歩除外、Aggregate fallback。
- Analytics月遷移と未来月制限。
- OnboardingのCamera位置情報案内。
- Calendar / Analytics TabのUI smoke test。

### Verification

- `./scripts/build.sh`: 成功。
- `./scripts/test.sh`: Unit 458件、UI 20件、失敗0。
- SwiftLint 0.65.0 strict: 301 Swift files、違反0。
- SwiftFormat 0.62.1 lint: 301 Swift files、要修正0。
- `git diff --check`: 成功。

### Manual Verification

- iPhone 17 / iOS 26.5 SimulatorでCalendar、Analytics、Onboarding、Media Preview、Map操作をUI Test確認した。

### Deviations

- なし。Location取得、判定ロジック、SwiftData Schema、Signing、App Store Connectは変更していない。

### Unresolved Issues

- 実機Photosでの削除・Limited Access変更と、iOS 17〜25のMaterial表示はリリース前の実機確認を推奨する。

# [Calendar] 月間Overviewに全移動地図とギャラリーを追加する

## Summary

CalendarのNavigation Titleを外して表示領域を上へ詰め、月間サマリーの下へ対象月の全車移動をまとめた地図と、対象月の全写真・動画ギャラリーを縦に続けて表示する。地図はタップで全画面表示し、既存のMedia AnnotationとPreview導線を再利用する。

## Goal

月を左右へめくる既存Calendarを入口として、同じ月の距離・時間・都市ランキング、全移動地図、写真・動画を一つの縦スクロール画面で確認できるようにする。

## Required Documents

実装前に次を読むこと。

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`
- [x] `issues/16-1-automotive-movement-filter.md`
- [x] `issues/16-2-monthly-summary-and-calendar-swipe.md`
- [x] `issues/8-6-day-detail-media-grid.md`
- [x] `issues/8-10-media-annotation.md`
- [x] `issues/8-12-media-clustering.md`

## Dependencies

- `MonthlySummaryData`、`LoadMonthlySummaryUseCase`
- `DerivedDataRepository`、`MediaCacheRepository`
- `AutomotiveMovementFilter`
- `MapSceneBuilder`、`MediaPlacementCalculator`
- `RouteMapView`、`FullRouteMapView`、`MediaGridSection`、`MediaPreviewView`

## Scope

### Allowed Changes

- `issues/16-3-monthly-overview-map-gallery.md`
- `DriveLog/DriveLog/Domain/Entities/MonthlyOverviewData.swift`
- `DriveLog/DriveLog/Application/Calendar/LoadMonthlyOverviewUseCase.swift`
- `DriveLog/DriveLog/Features/Calendar/MonthlyOverviewViewModel.swift`
- `DriveLog/DriveLog/Features/Calendar/MonthlyOverviewView.swift`
- `DriveLog/DriveLog/Features/Calendar/MonthlySummaryView.swift`
- `DriveLog/DriveLog/Features/Calendar/CalendarView.swift`
- `DriveLog/DriveLog/Features/DayDetail/MediaGridSection.swift`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/UITestSupport/DriveLogApp+MapBackUITestSupport.swift`
- `DriveLog/DriveLogTests/Application/LoadMonthlyOverviewUseCaseTests.swift`
- `DriveLog/DriveLogTests/Features/MonthlyOverviewViewModelTests.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

### Forbidden Changes

- SwiftData V1 Model、Schema、Migration、Repository永続化形式
- Raw Event、Location取得、充電Mode、Processing Pipeline、Classifierの変更
- Day Detail、Stay Override、Full Mapの既存操作契約を壊す変更
- PhotoKit Asset本体の削除、localIdentifierや座標の通常ログ出力
- Signing、Team、Bundle Identifier、Capability、外部Package
- `NavigationStack`全体の別画面構成への置換

## Decision

1. Calendarの月切り替えはIssue 16-2の`TabView` Page Styleを維持する。外側だけを縦`ScrollView`へ包み、Calendar、Monthly Summary、月間Map、月間Galleryを順番に遅延評価する。全期間の月や全データを一括生成しない。
2. `LoadMonthlyOverviewUseCase`は対象月のDerived DataとMedia Cacheを読み、`AutomotiveMovementFilter`後のMovementだけを`MapSceneBuilder`へ渡す。位置情報のないMediaもギャラリーには残し、位置情報付きMediaだけを`MediaPlacementCalculator`経由でMapSceneへ配置する。
3. 地図のプレビューは既存`RouteMapView`を使用し、タップ可能な全画面ボタンから既存`FullRouteMapView`を開く。写真AnnotationのThumbnailとCluster、タップ後の既存Media Previewを再利用する。
4. 月間Galleryは既存`MediaGridSection`の列・Thumbnail・動画再生Iconを再利用し、全Assetを撮影日時とIdentifierの安定順で表示する。Media CacheにないPhotos Assetを直接列挙する新APIは追加しない。
5. Calendarの`.navigationTitle("移動ログ")`は削除し、Navigation Barのタイトル分の余白をなくす。Month見出しとAccessibility Headerは維持する。
6. Summary内部のScrollViewを除去し、画面全体の外側ScrollViewでSummary、Map、Galleryを連続表示する。既存のSummaryの空・エラー・Progress表示は維持する。

## Requirements

1. Calendar上部から下方向へスクロールすると、Monthly Summary、対象月の全車移動Map、対象月の全Media Galleryが順番に表示される。
2. Map Previewをタップすると全画面Mapが開き、既存のPolyline、Stay、位置情報付きMedia Annotationを表示する。
3. Full Map上のMedia Annotation／Placeから既存のMedia Previewへ遷移できる。
4. Galleryでは位置情報のないMediaも表示し、Thumbnail失敗時もCellのFallbackを表示する。
5. 月変更時にOverviewの古い非同期応答を適用しない。
6. 月間データが空の場合、Summary、Map、Galleryそれぞれの空状態を表示する。
7. iPhone SE幅、Dynamic Type、Dark Mode、VoiceOverで見出し・操作ラベルが破綻しない。
8. 月間Mapは自動車分類済みMovementだけを使い、既存の保存データとSchemaを変更しない。
9. `fatalError()`、`try!`、`as!`、`print()`、`debugPrint()`、`NSLog()`を使用しない。

## Acceptance Criteria

- [x] 「移動ログ」Navigation Titleが表示されず、Calendarが上へ詰まる。
- [x] Calendarの月Page Swipeを維持したまま、Summary、Map、Galleryを縦スクロールで最後まで表示できる。
- [x] 月間Mapをタップして全画面Mapを開ける。
- [x] 全画面Mapに車Polylineと位置情報付き写真・動画Annotationが表示される。
- [x] 月間Galleryに位置情報の有無を問わず対象月のMediaが並ぶ。
- [x] GalleryまたはMapから既存Media Previewを開き、左右Pagingできる。
- [x] 月変更の競合応答、空状態、Thumbnail失敗をSwift Testingで確認する。
- [x] UI Testでタイトル非表示、縦スクロール、Mapカード、GalleryのAccessibility Identifierを確認する。
- [x] Build、Test、SwiftLint、SwiftFormat、`git diff --check`が成功する。

## Privacy Requirements

- 座標、経路、PhotoKit localIdentifier、写真・動画名をLoggerへ出力しない。
- Media Cacheと既存PhotoKit Providerの範囲を越えてAssetを外部送信しない。

## Completion Report Format

### Summary

月間Summaryの下へ、対象月の車移動をまとめたMap Preview／全画面Mapと、全Media Galleryを追加し、Calendarから縦スクロールで連続表示する。Navigation Titleは削除する。

### Changed Files

- `MonthlyOverviewData.swift` / `LoadMonthlyOverviewUseCase.swift`: 月間Movement、Stay、Media、MapSceneの集約。
- `MonthlyOverviewViewModel.swift` / `MonthlyOverviewView.swift`: 状態管理、Map全画面、Gallery、Preview導線。
- `CalendarView.swift` / `MonthlySummaryView.swift`: 外側ScrollViewと上部オフセット。
- `AppContainer.swift` / `ContentView.swift` / `DriveLogApp.swift`: Dependency Injection。
- `MediaGridSection.swift`: 月間タイトルと空状態の再利用。
- Unit/UI Test: 集約、競合応答、縦スクロール、Map/Gallery導線。

### Tests Added

Monthly Overview UseCase／ViewModelとCalendar UIのテストを追加する。

### Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

### Manual Verification

実機で対象月のMap、写真Annotation、Cluster、Gallery、Preview、Dynamic Type、VoiceOverを確認する。

### Deviations

既存の月Page Swipeは維持し、ユーザー要求の「スクロールして全部出る」はCalendarページ内部を外側縦ScrollViewで拡張する形で実現する。Map／Mediaの取得は既存Cacheと既存Map／Preview導線を再利用する。

### Unresolved Issues

長期間のMedia Cache欠損、PhotoKit権限変更、実機での大量Assetのメモリ使用量は実機確認が必要。

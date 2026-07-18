# [Calendar] 月間サマリーと月ページスワイプを実装する

## Summary

Calendarを縦連続Scrollから左右Page Swipeへ変更し、画面を上部Calendar約40%、下部Monthly Summary約60%へ再構成する。Summaryには車っぽい移動の総距離、総移動時間、訪れた都市名の訪問回数ランキングを表示する。

## Background

現在のCalendarは月Sectionを縦に連続表示しているが、実機では一つの月と集計を同時に把握しづらい。月を左右へめくりながら、その月の主要な移動と都市を確認できる構成へ変更する。

## Goal

月ごとのCalendarとMonthly Summaryを同じページで確認し、左右Swipeで標準的なページ遷移アニメーションを使って月を切り替えられるようにする。

## Non-Goals

- 年間サマリー、グラフ、AI分析、燃費・速度ランキング
- 新しいSwiftData Model、Migration、外部Package
- 地図画面、Day Detail、写真Previewの操作変更
- 位置情報のないMediaからの都市推定
- 正確な座標や都市名のLogger出力

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
- [x] `issues/14-7-continuous-calendar.md`
- [x] `issues/5-2-calendar-view-model.md`
- [x] `issues/5-5-calendar-swipe.md`

## Dependencies

- Issue 16-1 `AutomotiveMovementFilter`
- `DerivedDataRepository`
- `CalendarViewModel`
- `CalendarGridBuilder`
- `LocalTimeContext`で固定された`localDateKey`

## Scope

### Allowed Changes

- `issues/16-2-monthly-summary-and-calendar-swipe.md`
- `DriveLog/DriveLog/Domain/Entities/MonthlySummaryData.swift`
- `DriveLog/DriveLog/Application/Calendar/LoadMonthlySummaryUseCase.swift`
- `DriveLog/DriveLog/Platform/Geocoding/CityNameProviding.swift`
- `DriveLog/DriveLog/Platform/Geocoding/SystemCityNameProvider.swift`
- `DriveLog/DriveLog/Features/Calendar/MonthlySummaryViewModel.swift`
- `DriveLog/DriveLog/Features/Calendar/MonthlySummaryView.swift`
- `DriveLog/DriveLog/Features/Calendar/CalendarView.swift`
- `DriveLog/DriveLog/Features/Calendar/CalendarViewModel.swift`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`
- `DriveLog/DriveLogTests/Application/LoadMonthlySummaryUseCaseTests.swift`
- `DriveLog/DriveLogTests/Features/MonthlySummaryViewModelTests.swift`
- `DriveLog/DriveLogTests/Features/CalendarViewModelTests.swift`

### Forbidden Changes

- SwiftData V1 Model、Schema、Repository persistence format
- Raw Event collection、Location Mode、充電判定、Processing thresholds
- Day Detail、Full Map、Media Preview、Stay Override UI
- Signing、Team、Bundle Identifier、Capability、外部Package
- 地理座標、PhotoKit localIdentifier、写真・動画名の通常ログ出力

## Decision

1. `MonthlySummaryData`は`totalDistanceMeters`、`totalMovementDurationSeconds`、`cityRankings`だけを持つ。
2. 都市名はPlatformの`CityNameProviding`へ座標を渡し、`CLGeocoder`の`locality`、なければ`subAdministrativeArea`または`administrativeArea`を使う。失敗した地点はランキングへ追加しない。
3. 都市の訪問地点は、対象月の表示対象Stayの代表座標だけとし、同一都市名のStay数を降順でランキングする。同数は都市名の安定した昇順とし、上位5件だけをUIへ表示する。
4. Summaryの距離・時間はIssue 16-1のAutomotive Filter後のMovementだけから合計する。
5. `CalendarView`は`TabView`のPage Styleを使い、既存の日付選択で使われる標準Sheetの遷移と同じく、独自の3D回転・Bounce・長時間Animationを追加しない。
6. 初期月の前後2か月を保持し、左右の端へ到達したとき3か月ずつ遅延追加する。全期間を一括生成しない。

このIssueは現在の`project-rules.md`と`ui-spec.md`に残る「縦連続Calendar」記述を、ユーザー承認済みの新しいPage Swipe仕様で置き換える。既存のToday、選択日、記録なし日の無効化、日付Sheetの下から表示、日別Page Swipeは維持する。

## Requirements

1. Calendar領域を画面高の約40%、Monthly Summary領域を約60%として、固定端末サイズに依存せずDynamic Typeでも破綻しない。
2. 左Swipeで次月、右Swipeで前月を表示し、標準Page遷移Animationを使う。横矢印Buttonは追加しない。
3. 現在月付近から開始し、端で過去・未来月を遅延ロードする。
4. Summaryへ総移動距離、総移動時間、都市ランキングを表示する。
5. 都市ランキングは都市名と訪問回数を表示し、都市名取得失敗時もSummary全体を失敗にしない。
6. 日付セルのToday、選択状態、距離、記録なし日の遷移禁止を維持する。
7. Summaryのロード中、空、失敗状態を表示し、月変更時の古い応答を適用しない。
8. Accessibility Label/Identifier、VoiceOverの月操作、iPhone SE幅、Dark Mode、Reduce Motionへ対応する。
9. DomainへCoreLocation、MapKit、SwiftUIをimportしない。

## Acceptance Criteria

- [x] CalendarがScrollViewではなく左右Page Swipeで月を切り替える。
- [x] Calendar約40%、Summary約60%の構成で表示される。
- [x] Summaryへ車っぽい総距離、総時間、都市ランキングが表示される。
- [x] 都市名取得失敗時に距離・時間は表示される。
- [x] 月の初期Windowと端の遅延ロードが動作する。
- [x] Today、日付選択、記録なし日の無効化、日付Sheetが維持される。
- [x] Swift Testingで集計、ランキング、空/失敗、月変更競合を確認する。
- [x] UI Testで左右Swipe、Summary表示、日付選択導線を確認する。
- [x] Build、Test、SwiftLint、SwiftFormat、`git diff --check`が成功する。

## Privacy Requirements

- 座標はCityNameProvider内部の逆ジオコードにだけ使い、Loggerへ出力しない。
- PhotoKit localIdentifier、写真・動画名を扱わない。
- 外部Analytics、Server、Packageを追加しない。

## Completion Report Format

### Summary

Calendarを標準TabView Page Styleの左右Swipeへ変更し、画面をCalendar約40%／Monthly Summary約60%へ再構成した。車移動の距離・時間と、Stay代表地点の逆ジオコードによる都市訪問ランキングを表示する。

### Changed Files

- `MonthlySummaryData.swift`: 月間集計と都市ランキングのDomain型。
- `LoadMonthlySummaryUseCase.swift`: 車分類の集計、都市名取得、上位5件ランキング。
- `CityNameProviding.swift` / `SystemCityNameProvider.swift`: CLGeocoderをPlatformへ隔離。
- `CalendarView.swift` / `CalendarViewModel.swift`: Page Swipe、遅延月Window、状態表示。
- `MonthlySummaryView.swift` / `MonthlySummaryViewModel.swift`: Summary UIと状態管理。
- `AppContainer.swift` / `ContentView.swift` / `DriveLogApp.swift`: Dependency Injectionと画面接続。
- UI/Unit Test: 月Swipe、Summary表示、集計・ランキング・状態を検証。

### Tests Added

LoadMonthlySummaryUseCase、MonthlySummaryViewModel、Calendar UIのテストを追加・更新。

### Verification

- `./scripts/build.sh`: 成功
- `./scripts/test.sh`: 成功（433 tests / 94 suites、UI 14件を含む）
- `swiftlint lint --strict`: 成功
- `swiftformat --lint .`: 成功
- `git diff --check`: 成功

### Manual Verification

iPhone 17 SimulatorでCalendarの月Swipe、Summary表示、日付選択からDay Detailへの遷移、既存Map/Media導線をUI Testで確認した。実機でのCLGeocoder応答、Dynamic Type最大サイズ、VoiceOver実操作は未確認。

### Deviations

都市名取得は`locality`、`subAdministrativeArea`、`administrativeArea`の順で採用し、失敗地点はSummaryを失敗させず除外した。既存の縦連続Calendar仕様は本Issueの承認済みPage Swipe仕様で置き換えた。

### Unresolved Issues

都市名はOSの逆ジオコード結果に依存するため、地域によって表記揺れが残る。実機での長期間スクロール相当の連続Swipe確認は別途必要。

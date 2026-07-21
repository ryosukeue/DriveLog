# [Recording] 起動直後の手動記録開始導線を追加する

## Summary

アプリ起動後、ユーザーが1回タップするだけで高密度の位置記録を開始できるホーム画面を追加する。既存の自動記録、Raw Event保存、Processing、Calendar、Day Detail、地図、写真表示は維持し、記録参照ボタンから従来のCalendarへ遷移できるようにする。

## Background

実機で移動状態の自動切り分けが不安定なため、まずユーザーが運転開始を明示できる導線を提供する。既存の`LocationRecordingMode.automotiveHighAccuracy`を手動開始後の記録Modeとして使用し、低電力時の自動判定ロジックと保存形式を変更しない。

## Goal

起動直後のホーム画面から「記録開始」を1回押すと、同一のLocation Providerで高密度記録へ切り替わり、下部の「移動記録を参照」から既存Calendarを開ける状態にする。

## Non-Goals

- Raw Location、Motion、Visitの保存形式やSwiftData V1 Schemaの変更
- 既存の自動Activity判定、充電判定、Processing分類、Polyline生成の変更
- 記録停止ボタン、設定画面、サーバー、外部Packageの追加
- Calendar、Day Detail、Full Map、Media UIの仕様変更

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- `StartMonitoringUseCase`
- `LocationProviding` / `LocationRecordingMode.automotiveHighAccuracy`
- `AppLifecycleCoordinator`
- 既存の`ContentView`とCalendar導線

## Scope

### Allowed Changes

- `issues/feature-manual-recording-start.md`
- `DriveLog/DriveLog/Application/Monitoring/StartMonitoringUseCase.swift`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/Features/Recording/RecordingStartView.swift`
- `DriveLog/DriveLog/Features/Recording/RecordingStartViewModel.swift`
- `DriveLog/DriveLog/UITestSupport/UITestPhotoLibraryProvider.swift`
- `DriveLog/DriveLogTests/Application/StartMonitoringUseCaseTests.swift`
- `DriveLog/DriveLogTests/Features/RecordingStartViewModelTests.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`
- `DriveLog/DriveLogUITests/RecordingStartUITests.swift`

### Forbidden Changes

- SwiftData Model、Migration、Raw Event Repository、Processing Pipeline
- `LocationProviding`の既存公開契約変更
- 既存の自動車Activity判定、充電Mode判定、停車猶予の仕様変更
- Calendar、Day Detail、Full Map、Mediaの既存画面仕様変更
- Signing、Team、Bundle Identifier、Target、Scheme、Deployment Target
- Capability、Info.plist、CloudKit/iCloud、外部Package
- `fatalError()`、`try!`、`as!`、`print()`、`debugPrint()`、`NSLog()`
- 座標、経路、PhotoKit localIdentifier、写真名の通常ログ出力

## Requirements

1. Onboarding完了後の通常起動では、最初に記録開始ホームを表示する。
2. ホーム中央付近に大きな「記録開始」ボタンを配置する。
3. ホーム下部に「移動記録を参照」ボタンを配置する。
4. 「移動記録を参照」から既存のCalendar画面を開く。
5. 「記録開始」を押すと、既存の監視・保存Coordinatorを起動したまま、同一Location Providerを`automotiveHighAccuracy`へ切り替える。
6. 手動高密度記録中は、充電状態やMotion Activityの変化だけで低電力Modeへ戻さない。
7. 手動開始の二重タップや既に監視中の状態で、Providerを重複起動しない。
8. 開始成功時はホーム上で記録中であることをVoiceOverでも判別できるようにする。
9. 権限拒否・監視開始失敗時はクラッシュせず、再試行可能なエラー状態を表示する。
10. 既存の自動記録導線とLifecycleのforeground/background処理は維持する。
11. UIは赤Accent Color、Dynamic Type、VoiceOver、iPhone縦画面に対応する。

## Input

- ユーザーによる「記録開始」ボタンのタップ
- ユーザーによる「移動記録を参照」ボタンのタップ
- 既存のPermission、Power、Motion、Location Provider状態

## Output

- 高密度Location記録Modeへの切替
- 記録開始中／失敗状態のホーム表示
- 既存Calendar画面の表示

## State Changes

- `StartMonitoringUseCase`に手動高密度記録状態を追加する。
- SwiftDataのSchema、Raw Event、Processing Stateは変更しない。
- ホームViewModelの状態だけを更新する。

## Error Handling

- Location権限拒否、制限、監視不可、その他の開始失敗をUI表示用の状態へ変換する。
- 失敗後はボタンから再試行できるようにする。
- 強制終了後の高密度記録再開は保証しない。既存の起動時自動監視は維持する。

## Privacy Requirements

- 座標、経路、PhotoKit localIdentifier、写真・動画名をログへ出力しない。
- 手動開始とMode切替は固定の状態コードだけを既存Loggerへ渡す。
- 外部サーバーへ送信しない。

## UI Requirements

- ホームは標準的なSwiftUIレイアウトで、主要ボタンを画面中央付近へ大きく配置する。
- 参照ボタンは画面下部へ配置し、既存Calendarを開く。
- 成功時の表示は「記録中」、失敗時の表示は再試行可能な短い説明とする。
- 既存のCalendar以降の画面、Navigation、戻る動作は変更しない。

## Accessibility Requirements

- Accessibility Label: `記録開始`、成功後は`記録中`、参照ボタンは`移動記録を参照`
- Accessibility Identifier: `recordingStart.root`、`recordingStart.start`、`recordingStart.browse`
- Dynamic Type: システムフォントと標準Textスタイルを使用する。
- VoiceOver: 記録状態、失敗状態、再試行操作を読み上げ可能にする。
- Minimum tap area: 44pt以上。主要ボタンは十分な余白を持たせる。

## Processing Rules

- 手動開始後の位置取得は既存の`automotiveHighAccuracy`設定（Best accuracy、50m distance filter、automotive activity）を使用する。
- 新しいLocation Providerや高精度Managerを作らない。
- 既存の自動判定・分類アルゴリズムと派生データ生成は変更しない。

## Acceptance Criteria

- 通常起動でOnboarding完了後に記録開始ホームが表示される。
- 中央付近の大きな記録開始ボタンが表示される。
- 下部の移動記録参照ボタンから既存Calendarが表示される。
- 記録開始タップでLocation Modeが`automotiveHighAccuracy`になる。
- 手動高密度記録中にPower/Motionイベントで低電力へ戻らない。
- 二重タップで監視Providerが重複起動しない。
- Unit Test、UI Test、Build、Test、SwiftLint、SwiftFormat、`git diff --check`が成功する。
- Allowed Changes外の変更がない。

## Decision / Deviations

- 高密度記録は新しいModeではなく、既存の`automotiveHighAccuracy`を手動開始から使用する。これによりCore Location設定と保存形式を増やさず、既存の自動記録を維持する。
- 記録停止操作は今回追加しない。ユーザー要件が「開始」だけであり、停止仕様を独自に追加すると既存のLifecycle・Background仕様へ影響するためである。

## Completion Report Format

- Summary
- Changed files and reasons
- Tests added
- Build result
- Test result
- SwiftLint result
- SwiftFormat result
- Manual verification
- Deviations
- Unresolved issues

## Completion Report

- Summary: Onboarding完了後の起動ホームに大きな「記録開始」と下部の「移動記録を参照」を追加した。開始時は既存の監視CoordinatorとLocation Providerを再利用し、`automotiveHighAccuracy`へ切り替える。手動記録中はPower/Motionイベントで低電力Modeへ戻らない。
- Changed files and reasons:
  - `DriveLog/DriveLog/Application/Monitoring/StartMonitoringUseCase.swift`: 手動高密度記録のProtocol、状態、Mode切替を追加。
  - `DriveLog/DriveLog/Application/AppContainer.swift`: 起動ホームへ記録開始UseCaseを注入。
  - `DriveLog/DriveLog/DriveLogApp.swift`: 起動ホームとCalendar参照導線を追加。既存UITest用Photo Libraryを専用ファイルへ分離。
  - `DriveLog/DriveLog/Features/Recording/RecordingStartView.swift`: 起動ホームUIを追加。
  - `DriveLog/DriveLog/Features/Recording/RecordingStartViewModel.swift`: 開始中、成功、失敗、再試行状態を追加。
  - `DriveLog/DriveLog/UITestSupport/UITestPhotoLibraryProvider.swift`: 既存UITest用Providerを移動。
  - `DriveLog/DriveLogTests/Application/StartMonitoringUseCaseTests.swift`: 手動開始後のMode固定を追加検証。
  - `DriveLog/DriveLogTests/Features/RecordingStartViewModelTests.swift`: 成功、失敗、二重開始抑止を追加検証。
  - `DriveLog/DriveLogUITests/DriveLogUITests.swift`: Onboarding完了テストを専用ファイルへ分離。
  - `DriveLog/DriveLogUITests/RecordingStartUITests.swift`: 起動ホーム、手動開始、Calendar参照のUIテストを追加。
- Tests added: Unit 4件、UI 2件。
- Build result: `./scripts/build.sh` 成功。
- Test result: `./scripts/test.sh` 成功。Swift Testing 459件（99 suite）、UI Test 16件がすべて成功。
- SwiftLint result: `swiftlint lint --strict` 成功、違反0件。
- SwiftFormat result: `swiftformat --lint .` 成功、要修正0ファイル。
- Manual verification: iPhone 17 Simulatorで起動ホームを表示し、開始後に「記録中」へ変わること、参照ボタンでCalendarへ遷移することを確認。実機の位置取得・バックグラウンド継続は未確認。
- Deviations: 記録停止ボタンは追加していない。高密度記録は既存の`automotiveHighAccuracy`を使用し、新しいLocation ProviderやSchemaは追加していない。
- Unresolved issues: 実機での権限状態、Background実行、実際のGPS取得密度は別途確認が必要。

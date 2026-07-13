# [Application] RefreshMediaCacheUseCaseを実装する

## Summary

対象日のPhotoKit資産を再取得し、表示対象だけで日別メディアキャッシュと集計件数を置換する。

## Background

Issue 8-1から8-3でPhoto Library、適格性判定、永続キャッシュが実装された。これらをApplication層で結合し、削除・限定アクセスを含むPhotoKitの現在状態を日別表示へ反映する必要がある。

## Goal

`localDateKey`を入力として、対象日のeligibleなメディア参照を取得・保存・返却できるようにする。

## Non-Goals

- サムネイル、プレビュー、共有の取得
- PhotoKit変更通知の購読
- メディア地図配置

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 8-1 `PhotoLibraryProviding`
- Issue 8-2 `MediaEligibilityEvaluating`
- Issue 8-3 `MediaCacheRepository`
- `Clock`、`TimeZoneProviding`、`Logging`

## Scope

### Allowed Changes

- `issues/8-4-refresh-media-cache-use-case.md`
- `DriveLog/DriveLog/Application/Media/RefreshMediaCacheUseCase.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+MediaCache.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/MediaEligibility.swift`
- `DriveLog/DriveLog/Processing/Media/MediaEligibilityEvaluating.swift`
- `DriveLog/DriveLog/Shared/Time/TimeZoneProviding.swift`
- `DriveLog/DriveLogTests/Application/RefreshMediaCacheUseCaseTests.swift`
- `DriveLog/DriveLogTests/Data/MediaCacheRepositoryIntegrationTests.swift`
- `DriveLog/DriveLogTests/TestSupport/FakePhotoLibraryProvider.swift`

### Forbidden Changes

- PhotoKit、Domain、SwiftData V1 Schemaの変更
- Signing、Bundle Identifier、Team、Deployment Targetの変更
- 外部Package追加
- サムネイルやメディア本体の永続化
- Initial Templateや無関係な既存実装の変更

## Requirements

1. `RefreshMediaCacheUseCase`は`Sendable`で、`execute(localDateKey:) async throws`を持つ。
2. POSIX形式の`yyyy-MM-dd`を注入されたTimeZoneのGregorian Calendarで当日開始・翌日開始へ変換する。
3. `PhotoLibraryProviding`から対象区間を取得し、`MediaEligibilityEvaluating`がeligibleとした資産だけを残す。
4. creationDateなし、スクリーンショット、画面収録を除外し、位置情報なしは残す。
5. 結果をcreationDate昇順、同時刻はlocalIdentifier昇順にする。
6. `MediaCacheRepository.replaceAssets`をClockの現在時刻で1回呼ぶ。
7. キャッシュ置換と同じPersistenceActor操作で、存在するDayAggregateの`mediaCountCache`をeligible件数へ更新する。
8. PhotoKitで削除・限定アクセス外となった参照は日単位置換により除外する。
9. 限定アクセスでも提供された資産を通常どおり処理する。
10. 成功時だけ固定LogEventをinfoで記録し、識別子や座標をログへ含めない。
11. 不正な日付キーは`DriveLogError.invalidData`とする。
12. Default MainActor設定下でも値型と同期Protocolが意図せずMainActor隔離されないよう、既存宣言へ`nonisolated`を明示する。

## Input

- `localDateKey: String`

## Output

- eligibleかつ対象日の`[MediaAssetReference]`

## State Changes

- 対象日の`MediaAssetCacheModel`を完全置換する。
- 対応する`DayAggregateModel`が存在する場合、`mediaCountCache`を更新する。

## Error Handling

- 依存先の`DriveLogError`は保持して返す。
- 日付変換不能時は永続化やログを行わない。
- 取得・保存失敗時は成功ログを記録しない。

## Privacy Requirements

- 緯度、経度、経路、PhotoKit localIdentifier、ファイル名をログへ出力しない。
- 外部サーバーへ送信しない。
- 写真・動画本体を永続化しない。

## UI Requirements

- なし。

## Tests

- 日付キーからDSTを考慮した検索区間を生成する。
- eligibleのみを並べ替え、位置情報なしを保持する。
- 空取得で既存キャッシュを削除する。
- 限定アクセスでも処理する。
- 不正日付、取得失敗、保存失敗を検証する。
- DayAggregateのmediaCountCache更新をIntegration Testで検証する。

## Acceptance Criteria

- [x] 指定日のDateIntervalでPhoto Libraryを検索する。
- [x] eligibility適用後の資産だけでキャッシュを置換する。
- [x] 削除済み参照と集計件数が更新される。
- [x] 限定アクセスと依存先エラーを扱う。
- [x] Unit TestとIntegration Testが成功する。
- [x] Build、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warning、仕様外変更がない。

## Decision / Deviations

- PhotoKit資産に撮影時TimeZoneが保持されないため、設計の許容事項に従い、検索時に注入された現在TimeZoneを対象日の現地TimeZoneとして使用する。
- DayAggregateがまだ存在しない場合は新規作成せず、メディアキャッシュだけを保存する。後続の日次集計がキャッシュ件数を取り込む。
- Build時のAppIntents metadata skipとSimulatorのLLDB／Accessibility Runtimeメッセージは既存の環境由来Warningであり、Source Code由来の新規Warningはない。

## Files Expected to Change

- `issues/8-4-refresh-media-cache-use-case.md`
- `DriveLog/DriveLog/Application/Media/RefreshMediaCacheUseCase.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+MediaCache.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/MediaEligibility.swift`
- `DriveLog/DriveLog/Processing/Media/MediaEligibilityEvaluating.swift`
- `DriveLog/DriveLog/Shared/Time/TimeZoneProviding.swift`
- `DriveLog/DriveLogTests/Application/RefreshMediaCacheUseCaseTests.swift`
- `DriveLog/DriveLogTests/Data/MediaCacheRepositoryIntegrationTests.swift`
- `DriveLog/DriveLogTests/TestSupport/FakePhotoLibraryProvider.swift`

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

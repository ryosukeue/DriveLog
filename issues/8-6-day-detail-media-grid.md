# [UI] 日別詳細へ4列Media Gridを追加する

## Summary

日別詳細の最下部へ、その日のeligibleな写真・動画を遅延サムネイルで表示するMedia Gridを追加する。

## Background

日別Media CacheとThumbnail UseCaseは実装済みだが、`LoadDayDetailUseCase`はmediaを空配列として返し、UIにも表示先がない。日別詳細のデータ取得から4列グリッドまでを接続する必要がある。

## Goal

日別キャッシュをcreationDate順で読み込み、通常4列、拡大文字時3列の正方形Media Gridとして表示する。

## Non-Goals

- Photo／Video Preview遷移
- Share Sheet
- Map Media Annotation、Clustering
- Photo Library変更通知

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 8-3 `MediaCacheRepository`
- Issue 8-5 `LoadMediaThumbnailUseCase`
- 既存のDay Detail Feature

## Scope

### Allowed Changes

- `issues/8-6-day-detail-media-grid.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/Application/DayDetail/LoadDayDetailUseCase.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailViewModel.swift`
- `DriveLog/DriveLog/Features/DayDetail/MediaGridSection.swift`
- `DriveLog/DriveLogTests/Application/LoadDayDetailUseCaseTests.swift`
- `DriveLog/DriveLogTests/Features/DayDetailViewModelTests.swift`
- `DriveLog/DriveLogTests/Features/MediaGridSectionTests.swift`

### Forbidden Changes

- SwiftData Schema、PhotoKit Provider、Project設定の変更
- Signing、Bundle Identifier、Team、Deployment Targetの変更
- Preview／Share／Map Annotationの先行実装
- サムネイルやメディア本体の永続保存
- 外部Package追加

## Requirements

1. `LoadDayDetailUseCase`は`MediaCacheRepository.cachedAssets(for:)`を同じ日付キーで取得する。
2. mediaはcreationDate昇順、同時刻はlocalIdentifier昇順で返す。
3. 位置情報なしメディアもグリッド対象に残す。
4. `DayDetailViewModel`が`LoadMediaThumbnailUseCase`を呼び、ViewはPlatform Providerへ直接依存しない。
5. `LazyVGrid`で通常4列の正方形セルを表示する。
6. Dynamic Typeのaccessibility sizeでは3列へ減らす。
7. 各セルは表示時に個別にサムネイルを取得し、一括先読みしない。
8. 動画セルへ再生アイコンを重ねる。
9. メディア0件では専用の空状態を表示する。
10. Thumbnail失敗はセル内エラー表示とし、日別詳細全体をErrorにしない。
11. タップcallbackはPreview Issueで接続可能な形にするが、このIssueでは遷移しない。
12. Accessibility labelとidentifierを付与する。

## Input

- `DayDetailData.media`
- Dynamic Type size
- Thumbnail UseCase

## Output

- 日別詳細最下部のMedia GridまたはMedia空状態

## State Changes

- 各セル内のサムネイル読込状態のみ。
- 永続化変更なし。

## Error Handling

- Media Cache取得失敗は日別詳細取得失敗として既存経路へ返す。
- Thumbnail失敗は該当セルだけで表現する。

## Privacy Requirements

- localIdentifier、座標、ファイル名をログへ出力しない。
- 写真・動画・サムネイルを永続保存しない。
- 外部サーバーへ送信しない。

## UI Requirements

- セクション見出し「写真・動画」。
- 通常4列、accessibility Dynamic Typeで3列。
- 正方形、角丸、動画再生バッジ、Progress／Error placeholder。
- 0件時は「この日の写真・動画はありません」。

## Tests

- LoadDayDetailがmediaを取得・並べ替える。
- Media取得失敗を既存Error規則で扱う。
- ViewModelがThumbnail UseCaseを正しい値で呼び、成功・失敗を返す。
- 列数Policyが通常4列、accessibility sizeで3列となる。

## Acceptance Criteria

- [x] 日別キャッシュがDayDetailDataへ接続される。
- [x] 4列／3列の正方形Lazy Gridを表示する。
- [x] 動画、空状態、Progress、Thumbnail Errorを区別する。
- [x] ViewがPhotoKitへ直接依存しない。
- [x] Thumbnailを一括読込・永続保存しない。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- 3列への切替はDynamic Typeのaccessibility categoryに限定し、小型画面への追加調整は実機監査で必要なら行う。
- Preview遷移前でもセルをButtonとして実装し、callbackの既定値はno-opとする。
- Simulatorで既存のCalendar→Day Detail導線が成功し、全UI Test 6件が成功した。実メディアの見た目とスクロールはIssue 8-14および実機監査で確認する。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来であり、このIssueのSource Code由来の新規Warningはない。

## Files Expected to Change

- `issues/8-6-day-detail-media-grid.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/Application/DayDetail/LoadDayDetailUseCase.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailViewModel.swift`
- `DriveLog/DriveLog/Features/DayDetail/MediaGridSection.swift`
- `DriveLog/DriveLogTests/Application/LoadDayDetailUseCaseTests.swift`
- `DriveLog/DriveLogTests/Features/DayDetailViewModelTests.swift`
- `DriveLog/DriveLogTests/Features/MediaGridSectionTests.swift`

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

# [Platform] Photo Library Change反映を実装する

## Summary

PhotoKitのLibrary Change通知をApplication契約経由で購読し、表示中の日付のメディアキャッシュとDay Detailを再読込する。

## Background

`PhotoLibraryProvider`は既に`PHPhotoLibraryChangeObserver`を`AsyncStream<PhotoLibraryChange>`へ変換し、`RefreshMediaCacheUseCase`は日単位の完全置換で削除・Limited Access変更を反映できる。未接続の通知購読と表示更新をInitializer Injectionで結合する。

## Goal

日別詳細表示中に写真ライブラリの削除・アクセス範囲変更が起きても、利用可能な資産だけへ安全に更新される。

## Non-Goals

- PhotoKit変更差分の独自解析
- 全履歴日の一括再取得
- Photos Assetの削除
- Background常駐処理

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- `PhotoLibraryProviding.libraryChanges`
- Issue 8-4 `RefreshMediaCacheUseCase`
- Issue 8-6 Day Detail media grid

## Scope

### Allowed Changes

- `issues/8-13-photo-library-change.md`
- `DriveLog/DriveLog/Application/Media/ObservePhotoLibraryChangesUseCase.swift`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailViewModel.swift`
- `DriveLog/DriveLogTests/Features/DayDetailViewModelTests.swift`

### Forbidden Changes

- PhotoKit資産の削除、画像／動画本体の永続化
- SwiftData Schema、Domain、Processingルール変更
- 全日付キャッシュの一括走査
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. `PhotoLibraryProviding.libraryChanges`を公開するSendableなApplication UseCaseを定義する。
2. Day Detail ViewModelはProvider／Repositoryを直接参照せずUseCaseだけを呼ぶ。
3. 初回・再試行のDay Detail読込前に対象日のキャッシュをrefreshする。
4. refresh失敗時は既存キャッシュのDay Detail読込を継続する。
5. 表示中はLibrary Changeを購読し、各通知で対象日をrefresh後に再読込する。
6. SwiftUI taskキャンセルで購読を終了し、画面外で更新を継続しない。
7. 同じ`PhotoLibraryProvider`インスタンスをrefreshと変更購読で共有する。
8. 日単位置換により削除済み・Limited Access外の参照を除去する。
9. 利用可能な資産はcreationDate順の既存契約で再表示する。
10. localIdentifier、座標、ファイル名をログへ追加しない。

## State / Error Handling

- 更新成功後は`DayDetailData`、MapScene、メディアGridを再生成する。
- PhotoKit refresh失敗時はキャッシュ済み表示を維持し、クラッシュしない。
- Day Detail本体の読込失敗は既存Error Stateを維持する。
- Task cancellationはError表示にしない。

## Privacy Requirements

- Photos Assetを削除しない。
- メディア本体を永続化・外部送信しない。
- localIdentifier、座標、ファイル情報をLoggerへ出さない。

## Acceptance Criteria

- [x] 初回表示で対象日のキャッシュを再検証する。
- [x] Library Changeで対象日をrefreshしDay Detailを再読込する。
- [x] 削除・Limited Access外の参照が日単位置換で消える。
- [x] refresh失敗時に既存キャッシュ表示を試行する。
- [x] 購読が画面taskのCancellationに従う。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- 初回load前のrefresh呼出し。
- Library Change受信ごとのrefresh／再load。
- refresh失敗でもcached detailを表示。
- 購読Task cancellation後は追加更新しない。
- Production Providerの通知StreamはIssue 8-1の既存Platform Testを回帰実行する。

## Decision / Deviations

- `PhotoLibraryChange`は設計どおり汎用通知のため、全履歴を走査せず現在表示中の日付だけを完全置換する。別日を開いた際は初回refreshで最新化する。
- ViewModelへPlatform Providerを渡さず、Stream公開だけを責務とするApplication UseCaseを追加する。
- 利用可能な`iPhone 17 (iOS 26.5)` SimulatorでUnit Test 326件、UI Test 6件が成功した。
- 実Photosでの削除／Limited Access選択変更はIssue 8-14／最終実機確認対象とする。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来であり、本IssueのSource Code由来の新規Warningはない。

## Files Expected to Change

- Allowed Changes記載のIssue、Application UseCase／Composition、Day Detail View／ViewModel、Unit Test。

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

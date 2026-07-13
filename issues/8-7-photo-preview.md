# [UI] Photo Previewを実装する

## Summary

Media Gridの写真をタップし、PhotoKitを直接参照しない全画面プレビューで読み込み・メタデータ・参照不能状態を表示する。

## Background

日別Media GridとPhoto Library Providerは接続済みだが、セル選択後の遷移先がない。設計された`LoadMediaPreviewUseCase`をApplication境界に置き、写真表示導線を完成させる。

## Goal

1件の写真をアスペクト比を維持して画面内へ表示し、撮影日時と位置情報有無を確認できるようにする。

## Non-Goals

- AVPlayerによる動画再生
- Share Sheetの実処理と一時ファイルcleanup
- ピンチ／ダブルタップズーム
- 住所逆引き、複数選択

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 8-1 `PhotoLibraryProviding`
- Issue 8-6 Media Grid

## Scope

### Allowed Changes

- `issues/8-7-photo-preview.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/Application/Media/LoadMediaPreviewUseCase.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewView.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewViewModel.swift`
- `DriveLog/DriveLogTests/Application/LoadMediaPreviewUseCaseTests.swift`
- `DriveLog/DriveLogTests/Features/MediaPreviewViewModelTests.swift`

### Forbidden Changes

- Video Player、Share Sheet実処理
- PhotoKit Provider、SwiftData Schema、Project設定の変更
- Signing、Bundle Identifier、Team、Deployment Targetの変更
- 画像本体の永続保存
- 外部Package追加

## Requirements

1. 設計どおり`@MainActor`の`LoadMediaPreviewUseCase: AnyObject`を定義する。
2. Production実装はInitializer Injectionされた`PhotoLibraryProviding`へ写真要求を委譲する。
3. 空localIdentifierは`DriveLogError.invalidData`としProviderを呼ばない。
4. Media Gridの写真タップでMedia PreviewへNavigation遷移する。
5. ViewModelがUseCaseを呼び、idle/loading/photo/errorを表現する。
6. 読込中は中央にProgressViewを表示する。
7. 写真はアスペクト比を維持し、画面内へ収める。
8. 撮影日時を表示し、位置情報がある場合は「位置情報あり」を表示する。
9. 参照不能時は「この写真または動画を読み込めません」を表示しクラッシュしない。
10. 共有ボタンは表示するが、Issue 8-9までは無効とする。
11. localIdentifier、座標、ファイル名をログやAccessibility labelへ含めない。
12. 動画セルのPreview遷移はIssue 8-8で接続する。

## Input

- `MediaAssetReference`（写真）

## Output

- 写真全画面Preview、Progress、Errorのいずれか

## State Changes

- Media Preview ViewModelの表示状態のみ。
- 永続化変更なし。

## Error Handling

- Provider ErrorをViewModelがerror状態へ変換する。
- 再試行で同じ写真を再取得できる。

## Privacy Requirements

- localIdentifier、座標、画像名をログ・Accessibility表示へ含めない。
- 画像をSwiftDataやファイルへ保存しない。
- 外部サーバーへ送信しない。

## UI Requirements

- 黒背景の全画面領域。
- aspect fit写真、中央Progress、固定Error文言。
- 撮影日時、位置情報あり表示、標準Shareアイコン（無効）。
- 基本Accessibility identifierを付与する。

## Tests

- UseCaseの写真成功、不正入力、依存先失敗。
- ViewModelのloading→photo、error、retry、動画入力拒否。
- Grid callbackから写真Routeを生成する構成をBuild／UI回帰で確認する。

## Acceptance Criteria

- [x] 写真セルからPreviewへ遷移する。
- [x] 読込中、写真、参照不能を表示する。
- [x] 写真をaspect fitで表示する。
- [x] 撮影日時と位置情報有無を表示する。
- [x] 共有ボタンは無効で安全に表示される。
- [x] ViewがPhotoKitへ直接依存しない。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- `LoadMediaPreviewUseCase`は設計上写真・動画を同一Protocolに持つため両メソッドを宣言・委譲するが、このIssueのUIとUnit Test対象は写真側とし、動画側はIssue 8-8で完成させる。
- Shareアイコンは仕様上の配置を先行し、未接続操作を成功扱いにしないようdisabled表示とする。
- Unit Test 308件、既存UI Test 6件が成功した。実Photo Library写真の表示はIssue 8-14と実機監査で確認する。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来であり、このIssueのSource Code由来の新規Warningはない。

## Files Expected to Change

- `issues/8-7-photo-preview.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/Application/Media/LoadMediaPreviewUseCase.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewView.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewViewModel.swift`
- `DriveLog/DriveLogTests/Application/LoadMediaPreviewUseCaseTests.swift`
- `DriveLog/DriveLogTests/Features/MediaPreviewViewModelTests.swift`

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

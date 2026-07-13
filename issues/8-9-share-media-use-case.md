# [Application] ShareMediaUseCaseを実装する

## Summary

Preview中の写真・動画1件をiOS標準Share Sheetへ渡し、完了・キャンセル・失敗後に共有用一時ファイルを削除する。

## Background

Media Previewには無効なShareアイコンがある。Photo Library Providerは共有用一時Resourceを提供済みであり、UIActivityViewControllerをProtocol背後へ隠してcleanupまで保証するApplication処理が必要である。

## Goal

写真または動画1件を標準Share Sheetで共有し、共有用ファイルを残さない。

## Non-Goals

- 複数選択、独自共有先、共有履歴
- Photos Asset削除
- 共有Resourceの永続キャッシュ

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
- Issue 8-7／8-8 Media Preview

## Scope

### Allowed Changes

- `issues/8-9-share-media-use-case.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/Application/Media/ShareMediaUseCase.swift`
- `DriveLog/DriveLog/Platform/Sharing/SharePresenting.swift`
- `DriveLog/DriveLog/Platform/Sharing/SystemSharePresenter.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewView.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewViewModel.swift`
- `DriveLog/DriveLogTests/Application/ShareMediaUseCaseTests.swift`
- `DriveLog/DriveLogTests/Features/MediaPreviewViewModelTests.swift`

### Forbidden Changes

- PhotoKit Provider、SwiftData Schema、Project設定の変更
- 複数共有、Photos Asset削除
- Signing、Bundle Identifier、Team、Deployment Targetの変更
- 外部Package追加

## Requirements

1. 設計どおり`@MainActor SharePresenting: AnyObject`を定義する。
2. Production Presenterだけが`UIActivityViewController`を扱う。
3. `@MainActor ShareMediaUseCase: AnyObject`を定義し、localIdentifier 1件だけを受け取る。
4. Photo Providerから`ShareableMediaResource`を取得してPresenterへ渡す。
5. 完了・キャンセル・Presenter失敗後に一時ファイルを削除する。
6. 空Identifierを`DriveLogError.invalidData`とする。
7. cleanup失敗は`DriveLogError.unknown(code: "share_cleanup")`とする。
8. Previewの読込成功時だけShareボタンを有効にする。
9. 共有中の重複実行を防ぎ、失敗はAlert表示する。
10. localIdentifier、URL、ファイル名をログへ出力しない。

## Input

- Preview中のPhotoKit localIdentifier 1件

## Output

- iOS標準Share Sheet、共有後に削除された一時Resource

## State Changes

- PreviewのisSharing／shareFailed。
- 一時ファイルを削除する。SwiftData変更なし。

## Error Handling

- Resource取得・Presenter Errorを保持する。
- Presenter失敗時もcleanupを試行する。
- cleanup失敗を成功扱いにしない。

## Privacy Requirements

- localIdentifier、URL、ファイル名をログへ出力しない。
- 一時Resourceを共有後に残さない。
- 外部サーバーへ独自送信しない。

## UI Requirements

- Previewの標準Shareアイコンを有効化する。
- 共有中はProgress表示、失敗はAlert。

## Tests

- Resource取得→Presenterの順序と1件共有。
- 成功／キャンセル相当／Presenter失敗後のcleanup。
- Resource取得失敗、不正Identifier。
- ViewModelのボタン有効条件、重複防止、失敗状態。

## Acceptance Criteria

- [x] 写真・動画1件を標準Share Sheetへ渡す。
- [x] 完了・キャンセル・失敗後に一時ファイルを削除する。
- [x] PreviewのShareボタンが読込後だけ有効になる。
- [x] 共有失敗を安全に表示する。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- UIActivityViewControllerのキャンセルはcompletion errorなしとして正常終了し、同じcleanup経路を通す。
- Presenterはactive foreground UIWindowSceneの最前面ViewControllerから表示する。
- Unit Test 313件、既存UI Test 6件が成功した。実Share Sheetの共有先／キャンセルはIssue 8-14と実機監査で確認する。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来であり、このIssueのSource Code由来の新規Warningはない。

## Files Expected to Change

- `issues/8-9-share-media-use-case.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/Application/Media/ShareMediaUseCase.swift`
- `DriveLog/DriveLog/Platform/Sharing/SharePresenting.swift`
- `DriveLog/DriveLog/Platform/Sharing/SystemSharePresenter.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewView.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewViewModel.swift`
- `DriveLog/DriveLogTests/Application/ShareMediaUseCaseTests.swift`
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

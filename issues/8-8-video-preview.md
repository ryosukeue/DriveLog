# [UI] Video Previewを実装する

## Summary

Media Gridの動画をタップし、AVPlayerの標準Controlを備えた全画面Previewで再生できるようにする。

## Background

Issue 8-7でMedia Preview導線と共通UseCaseが実装されたが、動画は遷移対象外である。設計どおりAVPlayerを使用し、画面離脱時に不要な再生を停止する。

## Goal

1件の動画を標準の再生・一時停止・シーク操作でPreviewし、画面離脱時に停止する。

## Non-Goals

- 独自動画Control、Autoplay
- Share Sheet実処理
- 複数動画、編集、動画本体の永続保存

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 8-7 Photo Previewと`LoadMediaPreviewUseCase`

## Scope

### Allowed Changes

- `issues/8-8-video-preview.md`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewView.swift`
- `DriveLog/DriveLog/Features/MediaPreview/MediaPreviewViewModel.swift`
- `DriveLog/DriveLogTests/Application/LoadMediaPreviewUseCaseTests.swift`
- `DriveLog/DriveLogTests/Features/MediaPreviewViewModelTests.swift`

### Forbidden Changes

- PhotoKit Provider、SwiftData Schema、Project設定の変更
- Share Sheet実処理、独自AVPlayer Control
- Signing、Bundle Identifier、Team、Deployment Targetの変更
- 外部Package追加

## Requirements

1. 動画セルもMedia Preview Routeへ遷移する。
2. ViewModelは動画に`loadVideo(localIdentifier:)`を使用する。
3. 取得したAVAssetからAVPlayerをMainActor上で生成する。
4. ViewはAVKitの`VideoPlayer`を使用する。
5. 標準Controlで再生、一時停止、シークが可能である。
6. Autoplayせず、View消失時に`pause()`を呼ぶ。
7. 読込中、参照不能、Metadataは写真と共通化する。
8. 共有ボタンはIssue 8-9まで無効とする。
9. localIdentifier、座標、ファイル名をログやAccessibility表示へ含めない。

## Input

- `MediaAssetReference`（動画）

## Output

- AVPlayer標準Control付き動画Preview

## State Changes

- Preview ViewModelがAVPlayerを保持し、画面消失時にpauseする。

## Error Handling

- 取得失敗は共通の参照不能表示と再試行を使用する。

## Privacy Requirements

- 動画本体、localIdentifier、ファイル名を永続保存・ログ出力しない。
- 外部サーバーへ送信しない。

## UI Requirements

- 黒背景、標準VideoPlayer、共通Metadata、Progress、Error。
- Navigation titleは「動画」。

## Tests

- UseCaseの動画成功と空Identifier。
- ViewModelの動画取得、AVPlayer生成、写真回帰、エラー。
- stopでplayerがpause状態になる。

## Acceptance Criteria

- [x] 動画セルからPreviewへ遷移する。
- [x] AVPlayer／VideoPlayer標準Controlを使用する。
- [x] Autoplayせず、画面離脱時にpauseする。
- [x] Progress、Error、Metadataを表示する。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- `AVPlayer.timeControlStatus`をUnit Testで確認し、標準Control自体の操作はSimulator UI Test／実機監査へ残す。
- Unit Test 309件、既存UI Test 6件が成功した。実動画の再生・シーク・iCloud取得はIssue 8-14と実機監査で確認する。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来であり、このIssueのSource Code由来の新規Warningはない。

## Files Expected to Change

- `issues/8-8-video-preview.md`
- `DriveLog/DriveLog/ContentView.swift`
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

# [Map] Media Annotationを実装する

## Summary

位置情報付きの写真・動画を全画面地図へ正方形サムネイルとして表示し、選択時に既存Media Previewへ遷移できるようにする。

## Background

`MapSceneBuilder`は`MediaPlacement`からメディアIDと座標を持つ`MapMediaAnnotation`を生成済みだが、地図は標準Marker表示で、サムネイル読込とPreview導線がない。配置計算はIssue 8-11で接続する。

## Goal

全画面地図上で位置情報付きメディアを識別でき、写真・動画を安全にPreviewできる。

## Non-Goals

- MediaPlacement計算と日別MapSceneへの接続
- メディアクラスタリング
- 位置情報なしメディアの推測配置

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

- Issue 7-1 MapKit Wrapper
- Issue 8-5 Thumbnail UseCase
- Issue 8-7／8-8 Media Preview

## Scope

### Allowed Changes

- `issues/8-10-media-annotation.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapViewModel.swift`
- `DriveLog/DriveLogTests/Features/RouteMapViewModelTests.swift`

### Forbidden Changes

- Domainの`MapScene`／`MediaPlacement`契約変更
- MediaPlacement計算、クラスタリング、SwiftData Schema変更
- PhotoKit localIdentifierや座標のログ出力
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. `MapScene.mediaAnnotations`と当日メディアをIDで対応付ける。
2. 位置情報のある対応済みメディアだけを地図へ表示する。
3. 角丸の正方形サムネイルを非同期読込する。
4. 動画には再生アイコンを重ねる。
5. 読込失敗時は標準Placeholderを表示し、クラッシュしない。
6. 再利用時に古いサムネイルTaskをキャンセルする。
7. アノテーション選択で既存Media PreviewへPushする。
8. Preview用地図は従来どおり全画面地図へのタップを優先する。
9. localIdentifierや座標をAccessibility Label／Loggerへ出さない。

## Input

- `MapScene.mediaAnnotations`
- 当日の`MediaAssetReference`
- `LoadMediaThumbnailUseCase`

## Output

- 全画面地図の写真・動画サムネイル
- 選択した`MediaAssetReference`によるMedia Preview遷移

## State Changes

- なし。SwiftDataを変更しない。

## Error Handling

- サムネイル失敗はPlaceholderへFallbackする。
- Sceneと当日メディアが不整合なIDは表示・遷移対象外とする。

## Privacy Requirements

- 座標、localIdentifier、ファイル名をログとAccessibilityへ出さない。
- 外部通信を追加しない。

## UI / Accessibility Requirements

- 角丸正方形、動画再生バッジ、44pt以上の選択領域。
- Accessibility Labelは「写真」または「動画」。
- Accessibility Identifierは`map.mediaAnnotation`。

## Processing / Data Model Rules

- 位置情報なしメディアを地図へ仮配置しない。
- 永続Modelと配置計算は変更しない。

## Implementation Constraints

- DomainへUIKit、MapKit、PhotoKitをimportしない。
- Initializer Injectionを使用する。
- `fatalError()`、`try!`、`as!`、`print()`を追加しない。
- 新規Warningと未完成TODOを残さない。

## Acceptance Criteria

- [x] 位置情報付きメディアだけが角丸正方形サムネイルで表示される。
- [x] 動画に再生アイコンが表示される。
- [x] タップで既存Media Previewへ遷移する。
- [x] サムネイル失敗とView再利用を安全に扱う。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- Sceneに存在し位置情報を持つメディアだけを解決する。
- 写真・動画を解決できる。
- 未知ID、位置情報なしメディアを除外する。
- 選択したメディアをPreview callbackへ渡せる。

## Decision / Deviations

- Domainの`MapMediaAnnotation`は設計どおりIDと座標だけを保持し、UIに必要な種別は当日の`MediaAssetReference`を注入して解決する。
- Issue 8-11までは実データから`MediaPlacement`を生成しないため、本Issueは既存`MapScene`を表示するUI契約と導線を完成させる。
- 利用可能な`iPhone 17 (iOS 26.5)` SimulatorでUnit Test 314件、UI Test 6件が成功した。
- サムネイルの実Photo Library表示とPreview遷移は実資産が必要なため手動未確認で、Issue 8-14／最終実機確認対象とする。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来であり、本IssueのSource Code由来の新規Warningはない。

## Files Expected to Change

- Allowed Changes記載のIssue、Composition Root、Navigation、Day Detail、Map UI、ViewModel、Unit Test。

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

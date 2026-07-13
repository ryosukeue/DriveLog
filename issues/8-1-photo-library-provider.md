# [Platform] PhotoLibraryProvidingを実装する

## Summary

PhotoKitによる権限確認、日付範囲検索、Thumbnail／Preview／Video／共有用実体取得、Library変更通知をPlatform境界へ集約する。

## Goal

上位層がPhotoKit型へ依存せず、アクセス可能な写真・動画を非同期に参照できるようにする。

## Non-Goals

- Media Eligibility判定、SwiftData Cache、Grid／Preview UI、共有Sheet
- 写真・動画本体やThumbnailの永続保存
- Photos資産の変更・削除

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- `MediaAssetReference`、`MediaType`、`PhotoPermissionState`、`DriveLogError`

## Scope

### Allowed Changes

- `issues/8-1-photo-library-provider.md`
- `DriveLog/DriveLog/Platform/Photos/PhotoLibraryProviding.swift`
- `DriveLog/DriveLog/Platform/Photos/PhotoLibraryProvider.swift`
- `DriveLog/DriveLogTests/TestSupport/FakePhotoLibraryProvider.swift`
- `DriveLog/DriveLogTests/Platform/PhotoLibraryProviderTests.swift`

### Forbidden Changes

- Domain、Schema、Repository、AppContainer、既存Permission実装
- UI、Signing、Project設定、外部Package

## Requirements

1. `PhotoLibraryProviding: Sendable`をinterfaces.mdの7 APIで実装する。
2. Production実装はPhotoKit、UIKit、AVFoundationをProtocol背後で使用する。
3. `DateInterval`内のimage／videoだけをcreationDate昇順で返す。
4. `MediaAssetReference`へ種別、日時、任意位置、動画時間、Screenshot／Screen Recording flagを写す。
5. Limited時はPhotoKitから見える資産だけを返し、Denied／Restricted時は空配列を返す。
6. Thumbnailは要求size、Previewは高品質画像、Videoは`AVAsset`を返す。
7. Network accessを許可し、iCloud上のアクセス可能資産も取得対象にする。
8. 共有用資産は一意な一時fileへ書き出し、呼出側がcleanup可能なURLを返す。
9. `PHPhotoLibraryChangeObserver`をAsyncStreamへ変換する。
10. Photos資産を変更・削除せず、取得物を永続保存しない。
11. Callbackのcancel／error／nilを`DriveLogError`へ変換する。
12. Test Targetへ成功、失敗、Library変更を再現できるFakeを追加する。

## Interface Contract

```swift
protocol PhotoLibraryProviding: Sendable {
    func authorizationState() async -> PhotoPermissionState
    func fetchAssets(in interval: DateInterval) async throws -> [MediaAssetReference]
    func requestThumbnail(localIdentifier: String, targetSize: CGSize) async throws -> UIImage
    func requestPhotoPreview(localIdentifier: String) async throws -> UIImage
    func requestVideoAsset(localIdentifier: String) async throws -> AVAsset
    func requestShareableResource(localIdentifier: String) async throws -> ShareableMediaResource
    var libraryChanges: AsyncStream<PhotoLibraryChange> { get }
}
```

## Decisions

- `PhotoLibraryChange`は`.libraryDidChange`のみとし、PhotoKit差分型を公開せず後続UseCaseで全再検証する。
- `ShareableMediaResource`は`fileURL`と`mediaType`を持つ`Sendable, Equatable`な値型とする。URLの削除責務は後続ShareMediaUseCaseが負う。
- `PHImageManager`等はSendableでないがApple callback APIとしてthread-safeに使用し、Production classは状態をLockで保護した`@unchecked Sendable`とする。

## Privacy Requirements

- localIdentifier、位置、filenameをLoggerへ出力しない。
- 外部通信を追加しない。PhotoKitのiCloud取得だけをOS APIへ委ねる。
- 写真・動画本体をSwiftDataへ保存しない。

## Acceptance Criteria

- [x] ProtocolとProduction実装がBuildできる。
- [x] 権限状態、検索、各取得API、Library変更が実装される。
- [x] Fakeで成功、失敗、変更通知を再現できる。
- [x] Unit Testと既存Testが成功する。
- [x] Build、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warning、TODO、仕様外変更がない。

## Deviations

- Simulatorには検証用Photos資産がないため、実PhotoKitでのLimited、iCloud download、動画、共有file、change observerは実機未確認。Protocol/FakeとBuildで境界を検証した。
- Build時のAppIntents metadata skipとSimulator runtimeのAccessibility bundle重複は既存の環境Warningであり、新規Source Warningではない。

## Test Requirements

- Authorization mapping全case
- `ShareableMediaResource`と`PhotoLibraryChange`の等価性
- Fakeのasset／image／video／resource取得、失敗、通知順序

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
### Manual Verification
### Deviations
### Unresolved Issues

# [Release] App Store提出用App Iconを追加する

## Summary

DriveLogへ提出可能な不透明1024×1024 App Iconを追加し、Asset Catalogから必要なiPhone用Iconと`CFBundleIconName`を生成できるようにする。

## Background

署名修復後のApp Store Connect Uploadで、エラー90022（120×120 Icon不足）と90713（`CFBundleIconName`不足）が返った。`AppIcon.appiconset`には空のSlotだけがあり、画像ファイルと`filename`指定が存在しない。

## Goal

App Store ConnectのiPhone App Icon検証を通過させる。

## Non-Goals

- アプリ内UI、機能、Swiftソースの変更
- Signing、Team、Bundle Identifierの変更
- 外部Package追加
- Alternate Iconの追加

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/release-3-app-icon.md`
- `DriveLog/DriveLog/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `DriveLog/DriveLog/Assets.xcassets/AppIcon.appiconset/AppIcon.png`

### Forbidden Changes

- SwiftソースとTestコード
- Xcode Project、Signing、Capability、Team、Bundle Identifier
- Deployment Target、Target、Scheme、Build Configuration
- 外部Package
- 他のAsset

## Requirements

1. `AppIcon.png`は1024×1024のPNGとする。
2. Alpha Channelを含めず、全体を不透明にする。
3. 赤を基調とし、DriveLogの経路と写真を簡潔に表す。
4. 文字、既存ブランド、透かし、角丸を画像へ含めない。
5. `Contents.json`の通常iOS 1024×1024 Slotへ`AppIcon.png`を指定する。
6. Asset Catalogが提出用iPhone Iconと`CFBundleIconName`を生成することをArchiveで確認する。
7. App Store Connectへ再Uploadし、90022と90713が解消することを確認する。

## Privacy Requirements

- ユーザーの写真、位置情報、実機データを素材として使用しない。

## UI Requirements

- ホーム画面のApp Iconだけを追加する。
- アプリ内UI変更なし。

## Acceptance Criteria

- [x] 1024×1024、不透明PNGがAsset Catalogへ登録されている。
- [x] Buildが成功する。
- [x] Testが成功する。
- [x] SwiftLintが成功する。
- [x] SwiftFormat Checkが成功する。
- [x] `git diff --check`が成功する。
- [x] Release Archiveが成功する。
- [x] ArchiveのInfo.plistに`CFBundleIconName=AppIcon`が存在する。
- [x] Export IPAへ必要なApp Iconが含まれる。
- [x] IPAの厳格な署名検証が成功する。
- [x] App Store Connect UploadがApp Icon検証を通過する。
- [x] Allowed Changes外の変更がない。

## Test Requirements

### Unit Tests

- 新規ロジックがないため追加なし。既存Testを実行する。

### Integration Tests

- Release Archive、App Store Connect Export、IPA検証を実行する。
- App Store Connect Uploadを実行する。

### UI Tests

- 既存UI Testを実行する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- `issues/release-3-app-icon.md`
- `DriveLog/DriveLog/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `DriveLog/DriveLog/Assets.xcassets/AppIcon.appiconset/AppIcon.png`

## Files That Must Not Change

- SwiftソースとTestコード
- Xcode ProjectとSigning設定

## Migration Requirements

- なし。

## Logging Requirements

- なし。

## Definition of Done

- [x] Goalを満たしている。
- [x] Build、Test、Lint、Format、Diff Checkが成功している。
- [x] App Store Connect UploadがApp Icon検証を通過している。
- [x] Allowed Changes外の変更がない。

## Verification Results

- Build: `./scripts/build.sh`成功。
- Unit／Integration Tests: Swift Testing 455件成功。
- UI Tests: XCTest 15件成功。
- SwiftLint: 292ファイル、違反0件。
- SwiftFormat: 292ファイル中、要整形0件。
- Diff Check: 成功。
- Release Archive: 成功。
- App Store Connect Export: 成功。
- Generated iPhone Icon: `AppIcon60x60@2x.png`、120×120、Alphaなし。
- Info.plist: `CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconName=AppIcon`。
- Strict Code Signature Verification: 成功。
- App Store Connect Upload: 成功。Upload後のBuild処理待ち。
- Existing Warning: Release最適化時に`DriveLogApp.swift:58`のUI Test分岐が常にfalseと診断される既存Warning。Allowed Changes外のため本Issueでは変更しない。

## Completion Report Format

### Summary

### Changed Files

### Tests Added

### Verification

- Build:
- Unit Tests:
- Integration Tests:
- UI Tests:
- SwiftLint:
- SwiftFormat:
- Diff Check:
- App Store Upload:

### Deviations

### Unresolved Issues

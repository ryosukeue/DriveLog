# [Release] App Store提出用署名を修復する

## Summary

ユーザー向け表示名「ドライブログ」を維持しながら、内部Product／Executable名をASCIIの`DriveLog`へ戻し、App Store提出用IPAが厳格なコード署名検証を通る状態にする。

## Background

`PRODUCT_NAME`を「ドライブログ」へ変更したArchiveをApp Storeへ提出すると、エラー90034（Missing or invalid signature）が発生する。調査では、Apple Distribution証明書とApp Store Provisioning Profileは正常だが、書き出したIPAの`CodeResources`へ日本語名のメイン実行ファイルがResourceとして含まれ、`codesign --verify --deep --strict`が`a sealed resource is missing or invalid`で失敗した。

同一の証明書、Profile、Export Optionsを使用し、`PRODUCT_NAME=DriveLog`だけを一時的に上書きした比較IPAは厳格な署名検証に成功した。`CFBundleDisplayName`を「ドライブログ」とすれば、内部名を`DriveLog`に戻してもホーム画面の表示名は維持できる。

## Goal

表示名と内部Product／Executable名を分離し、App Store提出用IPAの署名を有効にする。

## Non-Goals

- App ID、Bundle Identifier、Development Teamの変更
- Signing方式、証明書、Provisioning Profileの手動固定
- Swiftソース、機能、UI、SwiftData Schemaの変更
- App Store ConnectのMetadata変更

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Apple Distribution証明書がKeychainへ存在すること
- App Store用Provisioning ProfileがAutomatic Signingで利用可能であること

## Reproduction Steps

1. 日本語の`PRODUCT_NAME`でRelease Archiveを作成する。
2. Automatic SigningでApp Store Connect用IPAを書き出す。
3. IPAを展開してアプリへ`codesign --verify --deep --strict`を実行する。

## Actual Result

署名検証が`a sealed resource is missing or invalid`で失敗し、App Store提出はエラー90034になる。

## Expected Result

内部実行ファイルが`DriveLog`、ユーザー向け表示名が「ドライブログ」となり、書き出したIPAが厳格な署名検証を通過する。

## Scope

### Allowed Changes

- `issues/release-2-app-store-signature.md`
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- `DriveLog/DriveLog.xcodeproj/xcshareddata/xcschemes/DriveLog.xcscheme`

### Forbidden Changes

- SwiftソースとTestコード
- Signing、Capability、Development Team
- Bundle Identifier、App ID
- Deployment Target、Target、Build Configuration
- 外部Package
- `CFBundleDisplayName`の「ドライブログ」以外への変更
- 関係のないファイル

## Requirements

1. App TargetのDebug／Release `PRODUCT_NAME`を`$(TARGET_NAME)`とする。
2. Product Referenceの名前とPathを`DriveLog.app`とする。
3. Shared SchemeのApp Buildable Nameを`DriveLog.app`とする。
4. `INFOPLIST_KEY_CFBundleDisplayName = "ドライブログ"`を維持する。
5. `INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.travel"`を維持する。
6. Automatic Signing、Team、Bundle Identifierを変更しない。
7. Release ArchiveをApp Store Connect方式で書き出す。
8. 書き出したIPAへ`codesign --verify --deep --strict`を実行する。
9. 書き出したAppの`CFBundleExecutable`が`DriveLog`、`CFBundleDisplayName`が「ドライブログ」であることを確認する。
10. メイン実行ファイルが`_CodeSignature/CodeResources`へResourceとして含まれないことを確認する。

## State Changes

- Xcode Build SettingとShared Schemeの内部Product名のみ変更する。
- 永続化データ変更なし。

## Privacy Requirements

- 位置情報、経路、Media Identifierを追加で取得または出力しない。
- 外部ServerまたはAnalyticsを追加しない。

## UI Requirements

- ホーム画面上の表示名「ドライブログ」を維持する。
- アプリ内UI変更なし。

## Accessibility Requirements

- UI変更なし。

## Processing Rules

- なし。

## Data Model Rules

- Schema変更なし。

## Implementation Constraints

- Signing、Team、Bundle Identifierを変更しない。
- `CODE_SIGN_IDENTITY`を手動指定しない。
- Swiftソースを変更しない。
- 新規Warningを増やさない。

## Acceptance Criteria

- [x] Debug／Releaseの`PRODUCT_NAME`が`$(TARGET_NAME)`である。
- [x] Product ReferenceとShared Schemeが`DriveLog.app`を参照する。
- [x] `CFBundleDisplayName`が「ドライブログ」である。
- [x] Release Archiveが成功する。
- [x] App Store Connect方式のExportが成功する。
- [x] ExportされたAppがApple Distribution証明書で署名されている。
- [x] `codesign --verify --deep --strict`が成功する。
- [x] Buildが成功する。
- [x] Testが成功する。
- [x] SwiftLintが成功する。
- [x] SwiftFormat Checkが成功する。
- [x] `git diff --check`が成功する。
- [x] Allowed Changes外の変更がない。

## Test Requirements

### Unit Tests

- 新規ロジックがないため追加なし。既存Testを実行する。

### Integration Tests

- Release ArchiveとApp Store Connect Exportを実行する。
- Export IPAのコード署名、Executable名、Display Nameを検証する。

### UI Tests

- 既存UI Testを実行する。

### Manual Tests

- Xcode Organizerから新しいArchiveをApp StoreへUploadする。この外部状態変更はユーザーが実行する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
xcodebuild archive -project DriveLog/DriveLog.xcodeproj -scheme DriveLog -configuration Release -destination 'generic/platform=iOS' -archivePath <temporary-path> -allowProvisioningUpdates
xcodebuild -exportArchive -archivePath <temporary-path> -exportOptionsPlist <temporary-export-options> -exportPath <temporary-path> -allowProvisioningUpdates
codesign --verify --deep --strict --verbose=4 <exported-app>
```

## Files Expected to Change

- `issues/release-2-app-store-signature.md`
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- `DriveLog/DriveLog.xcodeproj/xcshareddata/xcschemes/DriveLog.xcscheme`

## Files That Must Not Change

- SwiftソースとTestコード
- Signing／Capability関連ファイル
- Bundle IdentifierとDevelopment Team

## Migration Requirements

- なし。

## Performance Constraints

- 実行時処理の変更なし。

## Cancellation Behavior

- なし。

## Logging Requirements

- Production Logging変更なし。

## Definition of Done

- [x] Goalを満たしている。
- [x] Acceptance Criteriaを満たしている。
- [x] Build、Test、Lint、Format、Diff Checkが成功している。
- [x] App Store用IPAの厳格な署名検証が成功している。
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
- Exported IPA: `Apple Distribution: ryosuke ue (Z5MCP6ZQJ6)`で署名。
- Strict Code Signature Verification: 成功。
- Bundle: `CFBundleExecutable=DriveLog`、`CFBundleDisplayName=ドライブログ`。
- Existing Warning: Release最適化時に`DriveLogApp.swift:58`のUI Test分岐が常にfalseと診断される既存Warning。Allowed Changes外のため本Issueでは変更しない。
- Manual Upload: App Store Connectを変更する外部操作のため未実行。

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
- Manual Test:

### Deviations

### Unresolved Issues

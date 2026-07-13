# [Foundation] プロジェクト設定を確認する

## Summary

現在のXcode Project設定をDriveLog MVPの前提へ合わせ、iOS 17.0以降のiPhoneをPortraitのみで対象とし、Accent Colorをライト・ダークの両方で赤にする。

## Background

DriveLogの実装を開始する前に、`docs/implementation-plan.md`のPhase 0 Issue 0-1として、Xcode Projectの対応OS、対象Device、Orientation、Accent ColorをMVP仕様へ固定する必要がある。

## Goal

DriveLogのXcode Projectが、iOS 17.0以降・iPhoneのみ・Portraitのみ・赤いAccent ColorというMVPのプロジェクト設定を満たす。

## Non-Goals

- Swiftソースコードの変更
- アプリ機能、画面、データモデル、テストコードの追加または変更
- Signing、Bundle Identifier、Development Teamの変更
- Capability、CloudKit、iCloud同期、外部Packageの追加
- フォルダ構成の作成

## Required Documents

実装前に次を読むこと。

- [ ] `docs/project-rules.md`
- [ ] `docs/ui-spec.md`
- [ ] `docs/coding-rules.md`
- [ ] `docs/test-plan.md`
- [ ] `docs/implementation-plan.md`

## Dependencies

- Xcode Projectが作成済みであること
- `DriveLog` Schemeが存在すること
- `DriveLogTests`と`DriveLogUITests` Targetが存在すること

## Scope

### Allowed Changes

- `issues/0-1-project-settings.md`
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- `DriveLog/DriveLog/Assets.xcassets/AccentColor.colorset/Contents.json`

### Forbidden Changes

- Allowed Changesに記載されていないすべてのファイル
- Swiftソースコード
- Signing設定
- Bundle Identifier
- Development Team
- Capability、Entitlements、CloudKit、iCloud同期
- Swift Packageまたはその他の外部依存
- Target、Scheme、Build Configurationの追加・削除・改名
- Architectureの変更
- 関係のない設定変更や整形

## Requirements

1. Minimum Deployment TargetをiOS 17.0にする
2. 対象DeviceをiPhoneのみにする
3. 対応OrientationをPortraitのみにする
4. Accent Colorを赤にする
5. CloudKitや外部Packageを追加しない
6. Swiftソースコードを変更しない
7. Signing、Bundle Identifier、Teamを変更しない

## Input

- 現在の`DriveLog.xcodeproj` Build Settings
- 現在の`AccentColor.colorset`

## Output

- iOS 17.0をMinimum Deployment TargetとするiPhone専用Project設定
- Portraitのみを許可するOrientation設定
- ライト・ダークの両方で赤になるAccent Color Asset

## State Changes

- Xcode ProjectのBuild Settingsのみ変更する
- Accent Color Assetの色定義のみ変更する
- SwiftData Schemaやアプリ内状態の変更は行わない

## Error Handling

- Runtime処理の追加はない
- BuildまたはTestが失敗した場合は完了扱いにせず、失敗内容を報告する
- 既存Warningと新規Warningを区別して報告する

## Privacy Requirements

- 外部通信や外部依存を追加しない
- CloudKitまたはiCloud同期を有効にしない
- ユーザーデータ、位置情報、メディアに関する変更を行わない

## UI Requirements

- Accent Colorはライト・ダークの両方で赤とする
- iPhoneのPortraitのみをサポートする
- UI実装およびSwiftソースコードは変更しない

## Accessibility Requirements

- なし

## Processing Rules

- なし

## Data Model Rules

- なし

## Interface Contract

- なし

## Implementation Constraints

- Allowed Changes以外を変更しない
- Swiftソースコードを変更しない
- Signing、Bundle Identifier、Development Teamを変更しない
- Capability、CloudKit、iCloud同期を追加しない
- 外部Packageまたは外部ライブラリを追加しない
- Target、Scheme、Build Configurationを追加・削除・改名しない
- 新規Warningを増やさない
- 関係のないProject設定を変更しない

## Acceptance Criteria

- [ ] iOS Deployment Targetが17.0
- [ ] `TARGETED_DEVICE_FAMILY`がiPhoneのみ
- [ ] Landscape orientationが無効
- [ ] Portrait orientationが有効
- [ ] Accent Colorがライト・ダーク両方で赤
- [ ] CloudKitや外部Packageが追加されていない
- [ ] Swiftソースコードが変更されていない
- [ ] Signing、Bundle Identifier、Teamが変更されていない
- [ ] Buildが成功する
- [ ] Testが成功する
- [ ] SwiftLintが成功する
- [ ] SwiftFormat Checkが成功する
- [ ] 新規Warningがない
- [ ] 仕様外変更がない

## Test Requirements

### Unit Tests

- 新規Unit Testは追加しない
- 既存Unit Testが成功することを確認する

### Integration Tests

- なし

### UI Tests

- 新規UI Testは追加しない
- 既存UI Testが成功することを確認する

### Manual Tests

- [ ] iPhone 15 Simulatorでアプリが起動する
- [ ] Simulatorを回転してもLandscape表示にならない
- [ ] ライトモードでAccent Colorが赤である
- [ ] ダークモードでAccent Colorが赤である

## Test Fixtures

- なし

## Commands

```bash
# Build
./scripts/build.sh

# Test
SIMULATOR_NAME="iPhone 15" ./scripts/test.sh

# SwiftLint
swiftlint lint --strict

# SwiftFormat check
swiftformat --lint .
```

## Files Expected to Change

- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- `DriveLog/DriveLog/Assets.xcassets/AccentColor.colorset/Contents.json`

## Files That Must Not Change

- `DriveLog/DriveLog/**/*.swift`
- `DriveLog/DriveLogTests/**/*.swift`
- `DriveLog/DriveLogUITests/**/*.swift`
- Signing、Bundle Identifier、Development Teamに関する設定値
- Allowed Changesに記載されていないすべてのファイル

## Migration Requirements

- なし

## Performance Constraints

- なし

## Cancellation Behavior

- なし

## Logging Requirements

- なし

## Definition of Done

- [ ] Goalを満たしている
- [ ] Non-Goalsへ踏み込んでいない
- [ ] Required Documentsに従っている
- [ ] Acceptance Criteriaをすべて満たす
- [ ] Test Requirementsをすべて満たす
- [ ] Build成功
- [ ] Test成功
- [ ] SwiftLint成功
- [ ] SwiftFormat Check成功
- [ ] 新規Warningなし
- [ ] 変更範囲がAllowed Changes内で最小限
- [ ] 実装説明、Deviations、未解決事項が報告されている

## Completion Report Format

実装完了後、次の形式で報告すること。

### Summary

### Changed Files

- `path/to/file`
  - 変更理由

### Tests Added

- 追加なし、または追加内容

### Verification

- Build:
- Unit Tests:
- Integration Tests:
- UI Tests:
- SwiftLint:
- SwiftFormat:
- Manual Test:
- Warnings:

### Deviations

なし、またはIssueとの差異を記載する。

### Unresolved Issues

なし、または未解決事項を記載する。

# [Foundation] レイヤー別フォルダ構成を作成する

## Summary

DriveLogのSwiftソースを設計上の責務別に配置できるよう、Xcodeの同期ルートと今後のソース配置規則を確定する。

## Background

`docs/implementation-plan.md`のPhase 0 Issue 0-2では、後続Issueが責務境界に従って実装を追加できるよう、レイヤー別の配置先を定義する。Xcode Projectを確認した結果、`PBXFileSystemSynchronizedRootGroup`の物理同期ルートはRepository相対の`DriveLog/DriveLog`であり、`DriveLogApp.swift`と`ContentView.swift`が存在するアプリTargetのソースルートと一致している。

この同期ルート配下へ同名の`.gitkeep`を複数配置すると、XcodeがそれらをApp Resourceとして扱い、同一出力名のコピー処理が競合してBuildできない。そのため、このIssueでは空ディレクトリをGitへ保持せず、各レイヤーへ最初の実ファイルを追加するIssueで必要なディレクトリを作成する。

## Goal

`PBXFileSystemSynchronizedRootGroup`の物理同期ルートと、設計文書に従った今後のSwiftソース配置規則を確定する。

## Non-Goals

- Xcode初期テンプレートのSwiftソースの移動、削除、修正
- 空ディレクトリの作成またはGitでの保持
- Swift型、Protocol、Placeholder、実装コード、テストコードの追加
- SwiftData Model、View、App Entry Pointの変更
- Target MembershipまたはXcode Project設定の変更
- Signing、Bundle Identifier、Development Teamの変更
- 新しいArchitecture責務またはレイヤーの追加

## Required Documents

実装前に次を読むこと。

- [ ] `docs/project-rules.md`
- [ ] `docs/architecture.md`
- [ ] `docs/component-specs.md`
- [ ] `docs/coding-rules.md`
- [ ] `docs/test-plan.md`
- [ ] `docs/implementation-plan.md`

## Dependencies

- Issue 0-1 `[Foundation] プロジェクト設定を確認する`が完了していること
- `DriveLog/DriveLog`が`PBXFileSystemSynchronizedRootGroup`としてDriveLog Targetへ接続されていること

## Scope

### Allowed Changes

- `issues/0-2-folder-structure.md`
- 削除のみ: `DriveLog/DriveLog/Application/.gitkeep`
- 削除のみ: `DriveLog/DriveLog/Features/.gitkeep`
- 削除のみ: `DriveLog/DriveLog/Domain/.gitkeep`
- 削除のみ: `DriveLog/DriveLog/Data/.gitkeep`
- 削除のみ: `DriveLog/DriveLog/Platform/.gitkeep`
- 削除のみ: `DriveLog/DriveLog/Processing/.gitkeep`
- 削除のみ: `DriveLog/DriveLog/Shared/Errors/.gitkeep`
- 削除のみ: `DriveLog/DriveLog/Shared/Logging/.gitkeep`
- 削除のみ: `DriveLog/DriveLog/Shared/Time/.gitkeep`
- 削除のみ: `DriveLog/DriveLog/Shared/Formatting/.gitkeep`
- 削除のみ: `DriveLog/DriveLog/Shared/PreviewSupport/.gitkeep`

### Forbidden Changes

- Allowed Changesに記載されていないすべてのファイル
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- Xcode初期テンプレートのSwiftソース
- SwiftData Model、View、App Entry Point
- Target Membership、Target、Scheme、Build Configuration
- Signing、Bundle Identifier、Development Team
- Capability、Entitlements、CloudKit、iCloud同期
- Swift Packageまたはその他の外部依存
- Architecture文書または既存責務の変更
- 空フォルダ維持だけを目的とするSwift型やPlaceholder
- 関係のないファイルの整形

## Requirements

1. 追加済みの11個の`.gitkeep`をすべて削除する
2. `project.pbxproj`を変更しない
3. Swift Placeholderを作成しない
4. Swiftソースを移動、削除、変更しない
5. 各レイヤーディレクトリは、そのレイヤーへ最初の実ファイルを追加するIssueで作成する
6. `PBXFileSystemSynchronizedRootGroup`の物理同期ルートがRepository相対の`DriveLog/DriveLog`であることをIssue文書へ記録する
7. 設計上の配置先として、`Application/`、`Features/`、`Domain/`、`Data/`、`Platform/`、`Processing/`、`Shared/Errors/`、`Shared/Logging/`、`Shared/Time/`、`Shared/Formatting/`、`Shared/PreviewSupport/`をIssue文書へ残す

## Input

- 現在の`DriveLog/DriveLog`ディレクトリ
- 現在のXcode File System Synchronized Group設定

## Output

同期ルートはRepository相対の`DriveLog/DriveLog`とする。今後の設計上の配置先は次のとおりとし、各ディレクトリは最初の実ファイルを追加するIssueで作成する。

```text
DriveLog/DriveLog/
├── Application/
├── Features/
├── Domain/
├── Data/
├── Platform/
├── Processing/
└── Shared/
    ├── Errors/
    ├── Logging/
    ├── Time/
    ├── Formatting/
    └── PreviewSupport/
```

## State Changes

- Build競合を起こす11個の`.gitkeep`を削除する
- 同期ルートと今後の配置規則をIssue文書へ記録する
- Xcode Project、Target Membership、SwiftData、アプリ状態は変更しない

## Error Handling

- Runtime処理の追加はない
- 同期ルートが`DriveLog/DriveLog`と一致しない場合は`project.pbxproj`を独自変更せず、Blockerとして報告する
- BuildまたはTestが失敗した場合は完了扱いにせず、失敗内容を報告する

## Privacy Requirements

- ユーザーデータ、位置情報、メディアを追加しない
- 外部通信、CloudKit、iCloud同期、外部依存を追加しない

## UI Requirements

- なし

## Accessibility Requirements

- なし

## Processing Rules

- なし

## Data Model Rules

- なし

## Interface Contract

- なし

## Implementation Method

1. `project.pbxproj`の`PBXFileSystemSynchronizedRootGroup`を確認し、物理同期ルートがRepository相対の`DriveLog/DriveLog`であることを記録する
2. 追加済みの11個の`.gitkeep`を削除し、空ディレクトリをGitへ保持しない
3. 設計上の配置先をIssue文書へ記録する
4. 各ディレクトリは、そのレイヤーへ最初の実ファイルを追加するIssueで作成する
5. `project.pbxproj`やTarget Membershipは変更しない
6. 既存Swiftファイルが移動、削除、変更されていないことを差分で確認する

## Implementation Constraints

- Allowed Changes以外を変更しない
- Swiftファイルを新規作成、移動、削除、修正しない
- 空フォルダ維持のためのSwift Placeholderを作成しない
- `project.pbxproj`を変更しない
- Target Membership、Target、Scheme、Build Configurationを変更しない
- Signing、Bundle Identifier、Development Teamを変更しない
- Capability、CloudKit、iCloud同期を追加しない
- 外部Packageまたは外部ライブラリを追加しない
- Architecture上の責務を追加または変更しない
- 新規Warningを増やさない

## Acceptance Criteria

- [ ] `PBXFileSystemSynchronizedRootGroup`の物理同期ルートがRepository相対の`DriveLog/DriveLog`であることがIssue文書に記録されている
- [ ] 設計上の配置先として11個のレイヤーディレクトリがIssue文書に記録されている
- [ ] 各ディレクトリは、そのレイヤーへ最初の実ファイルを追加するIssueで作成する方針が記録されている
- [ ] 追加済みの11個の`.gitkeep`がすべて削除されている
- [ ] 空ディレクトリをGitへ保持するためのファイルが存在しない
- [ ] Swift Placeholderが追加されていない
- [ ] Swiftファイルが新規作成、移動、削除、変更されていない
- [ ] `project.pbxproj`がこのIssueで変更されていない
- [ ] Target Membership、Signing、Bundle Identifier、Teamが変更されていない
- [ ] 外部Packageが追加されていない
- [ ] Buildが成功する
- [ ] Testが成功する
- [ ] SwiftLintが成功する
- [ ] SwiftFormat Checkが成功する
- [ ] `git diff --check`が成功する
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

- [ ] `project.pbxproj`の同期ルート指定と物理パスがRepository相対の`DriveLog/DriveLog`へ解決されることを確認する
- [ ] `DriveLogApp.swift`と`ContentView.swift`が同期ルート配下に存在することを確認する
- [ ] 11個の`.gitkeep`が存在しないことを確認する
- [ ] Xcode上で既存SwiftファイルのTarget Membershipが変わっていない

## Test Fixtures

- なし

## Commands

```bash
# Build
./scripts/build.sh

# Test
./scripts/test.sh

# SwiftLint
swiftlint lint --strict

# SwiftFormat check
swiftformat --lint .

# Diff check
git diff --check
```

## Files Expected to Change

- `issues/0-2-folder-structure.md`
- 削除: `DriveLog/DriveLog/Application/.gitkeep`
- 削除: `DriveLog/DriveLog/Features/.gitkeep`
- 削除: `DriveLog/DriveLog/Domain/.gitkeep`
- 削除: `DriveLog/DriveLog/Data/.gitkeep`
- 削除: `DriveLog/DriveLog/Platform/.gitkeep`
- 削除: `DriveLog/DriveLog/Processing/.gitkeep`
- 削除: `DriveLog/DriveLog/Shared/Errors/.gitkeep`
- 削除: `DriveLog/DriveLog/Shared/Logging/.gitkeep`
- 削除: `DriveLog/DriveLog/Shared/Time/.gitkeep`
- 削除: `DriveLog/DriveLog/Shared/Formatting/.gitkeep`
- 削除: `DriveLog/DriveLog/Shared/PreviewSupport/.gitkeep`

## Files That Must Not Change

- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- `DriveLog/DriveLog/**/*.swift`
- `DriveLog/DriveLogTests/**/*.swift`
- `DriveLog/DriveLogUITests/**/*.swift`
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
- [ ] `git diff --check`成功
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
- Diff Check:
- Manual Test:
- Warnings:

### Deviations

なし、またはIssueとの差異を記載する。

### Unresolved Issues

なし、または未解決事項を記載する。

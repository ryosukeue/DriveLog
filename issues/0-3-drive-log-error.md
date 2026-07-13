# [Foundation] DriveLogErrorとPermissionKindを実装する

## Summary

DriveLog全体で共通して使用できる、Apple FrameworkやUIへ依存しないエラー型と権限種別を定義する。

## Background

`docs/implementation-plan.md`のPhase 0 Issue 0-3では、後続のPlatform、Data、Application、Presentation各層が共通して扱う`DriveLogError`と`PermissionKind`を先に実装する。`docs/interfaces.md`には`DriveLogError`のCaseが定義されているが、関連値に使用する`PermissionKind`の具体的な宣言とCaseは定義されていない。

このIssueでは`PermissionKind`の推奨案を提示する。Case構成が承認されるまでSwiftコードの実装を開始しない。

## Goal

Apple FrameworkやUIへ依存せず、DriveLog全体で安全に受け渡せる`DriveLogError`と`PermissionKind`を実装し、全Caseの生成と等価性をUnit Testで保証する。

## Non-Goals

- ユーザー向けエラーメッセージまたはLocalizationの実装
- NSErrorやOS固有エラー型からの変換処理
- Logging、Logger、LogEventの実装
- SwiftUIまたはUIKitによるエラー表示
- Apple Frameworkの権限状態型との相互変換
- Xcode初期テンプレートのSwiftファイルの変更

## Required Documents

実装前に次を読むこと。

- [ ] `docs/project-rules.md`
- [ ] `docs/architecture.md`
- [ ] `docs/interfaces.md`
- [ ] `docs/coding-rules.md`
- [ ] `docs/test-plan.md`
- [ ] `docs/implementation-plan.md`

## Dependencies

- Issue 0-2 `[Foundation] レイヤー別フォルダ構成を作成する`が完了していること
- `PermissionKind`の推奨Case構成が承認されていること

## Specification Ambiguity

`docs/interfaces.md`では`DriveLogError.permissionDenied(PermissionKind)`と`permissionRestricted(PermissionKind)`が定義されているが、`PermissionKind`自体のCaseは定義されていない。

このIssueでの推奨案は次のとおり。

```swift
enum PermissionKind: Sendable, Equatable {
    case location
    case motion
    case photoLibrary
}
```

- `location`は位置情報およびVisit監視に必要なCore Location権限を表す
- `motion`はモーション権限を表す
- `photoLibrary`は写真・動画ライブラリへのアクセス権限を表す
- Apple Frameworkの型や認可状態の詳細値は保持しない

未確定事項はCase名、特に写真権限を`photoLibrary`とするか`photos`とするかである。責務名`PhotoLibraryProviding`との整合性から`photoLibrary`を推奨する。承認前に独自判断で実装を開始しない。

## Scope

### Allowed Changes

- `issues/0-3-drive-log-error.md`
- `DriveLog/DriveLog/Shared/Errors/DriveLogError.swift`
- `DriveLog/DriveLog/Shared/Errors/PermissionKind.swift`
- `DriveLog/DriveLogTests/Shared/Errors/DriveLogErrorTests.swift`

### Forbidden Changes

- Allowed Changesに記載されていないすべてのファイル
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- Xcode初期テンプレートのSwiftファイル
- SwiftData Model、View、App Entry Point
- Target Membership、Target、Scheme、Build Configuration
- Signing、Bundle Identifier、Development Team
- Capability、Entitlements、CloudKit、iCloud同期
- Swift Packageまたはその他の外部依存
- Architecture文書または既存Interfaceの変更
- ユーザー向けエラーメッセージまたはLocalization
- NSErrorやOS固有エラー型を保持するProperty
- 関係のないファイルの整形

## Requirements

1. `docs/interfaces.md`に定義されたすべての`DriveLogError` Caseを実装する
2. `DriveLogError`を`Error`、`Sendable`、`Equatable`へ準拠させる
3. `PermissionKind`をApple Frameworkの型を使用せずに定義する
4. `PermissionKind`で位置情報、モーション、写真権限を表現できるようにする
5. `PermissionKind`を`Sendable`、`Equatable`へ準拠させる
6. ユーザー向けエラーメッセージを実装しない
7. 元のNSErrorやOS固有エラー型をPropertyまたは関連値として保持しない
8. 緯度、経度、経路、PhotoKit localIdentifier、メディアファイル名をエラーへ含めない
9. `SwiftUI`、`UIKit`、`SwiftData`、`CoreLocation`、`CoreMotion`、`PhotoKit`をimportしない
10. `fatalError()`、`try!`、`as!`を使用しない
11. `DriveLogError`の各Caseと`PermissionKind`の各Caseを生成できることをUnit Testで確認する
12. 同じCaseと関連値が等価になり、Caseまたは関連値が異なる場合に非等価になることをUnit Testで確認する
13. Xcode初期テンプレートのSwiftファイルを変更しない
14. 外部Packageを追加しない

## Input

- 権限種別を表す`PermissionKind`
- 個人情報を含まない固定エラーコード
- `YYYY-MM-DD`形式の`localDateKey`

## Output

- Apple Framework非依存の`PermissionKind`
- Apple FrameworkおよびUI非依存の`DriveLogError`

## State Changes

- なし

SwiftData、UI State、権限状態、アプリ状態は変更しない。

## Error Handling

- このIssueではエラー型の定義だけを行い、NSErrorやOS固有エラーからの変換処理は追加しない
- エラー関連値には個人情報を含まない固定コードと`localDateKey`だけを使用する
- ユーザー向け文言への変換はPresentation層の後続Issueへ委ねる

## Privacy Requirements

- 緯度、経度、移動経路をエラーまたはTest Fixtureへ含めない
- PhotoKit localIdentifier、写真名、動画名をエラーまたはTest Fixtureへ含めない
- 元のNSErrorまたはOS固有エラーを保持しない
- 外部通信を追加しない

## UI Requirements

- なし

## Accessibility Requirements

- なし

## Processing Rules

- なし

## Data Model Rules

- なし

## Interface Contract

`DriveLogError`は`docs/interfaces.md`の定義と一致させる。

```swift
enum DriveLogError: Error, Sendable, Equatable {
    case permissionDenied(PermissionKind)
    case permissionRestricted(PermissionKind)
    case monitoringUnavailable
    case persistenceFailure(code: String)
    case processingFailure(localDateKey: String, code: String)
    case invalidData
    case mediaUnavailable
    case mediaAccessLimited
    case backgroundTaskUnavailable
    case deletionFailure(localDateKey: String)
    case cancelled
    case unknown(code: String)
}
```

`PermissionKind`は承認後、次の推奨案で実装する。

```swift
enum PermissionKind: Sendable, Equatable {
    case location
    case motion
    case photoLibrary
}
```

## Implementation Method

1. `Shared/Errors/`を最初の実ファイル追加時に作成する
2. `PermissionKind.swift`へ承認済みの権限種別を定義する
3. `DriveLogError.swift`へ`docs/interfaces.md`どおりの12 Caseを定義する
4. 1つのUnit Testファイルで両Enumの全Case生成とEquatableを確認する
5. FoundationおよびApple Framework固有型への依存がないことをimportとコードで確認する

## Implementation Constraints

- Allowed Changes以外を変更しない
- `DriveLogError`と`PermissionKind`へUI、永続化、Loggingの責務を追加しない
- `SwiftUI`、`UIKit`、`SwiftData`、`CoreLocation`、`CoreMotion`、`PhotoKit`をimportしない
- NSErrorやOS固有エラー型をPropertyまたは関連値として保持しない
- `fatalError()`、`try!`、`as!`を追加しない
- `print()`を追加しない
- 未完成TODOを残さない
- 新規Warningを増やさない
- 外部Packageを追加しない

## Acceptance Criteria

- [ ] `DriveLogError`が`Error`、`Sendable`、`Equatable`へ準拠している
- [ ] `DriveLogError`の12 Caseが`docs/interfaces.md`と一致している
- [ ] `PermissionKind`が位置情報、モーション、写真権限を表現できる
- [ ] `PermissionKind`が`Sendable`、`Equatable`へ準拠している
- [ ] 禁止されたApple Frameworkをimportしていない
- [ ] ユーザー向けエラーメッセージを実装していない
- [ ] NSErrorまたはOS固有エラー型を保持していない
- [ ] エラーとTest Fixtureに緯度、経度、経路、PhotoKit localIdentifier、メディアファイル名が含まれていない
- [ ] `fatalError()`、`try!`、`as!`が含まれていない
- [ ] 全Caseの生成とEquatableを確認するUnit Testが成功する
- [ ] Xcode初期テンプレートのSwiftファイルが変更されていない
- [ ] `project.pbxproj`が変更されていない
- [ ] 外部Packageが追加されていない
- [ ] Buildが成功する
- [ ] 既存Testを含むTestが成功する
- [ ] SwiftLintが成功する
- [ ] SwiftFormat Checkが成功する
- [ ] `git diff --check`が成功する
- [ ] 新規Warningがない
- [ ] 仕様外変更がない

## Test Requirements

### Unit Tests

- [ ] `PermissionKind`の承認済み全Caseを生成できる
- [ ] `DriveLogError`の12 Caseを生成できる
- [ ] 同一Caseかつ同一関連値の`DriveLogError`が等価になる
- [ ] 異なるCaseの`DriveLogError`が非等価になる
- [ ] 権限種別、code、localDateKeyのいずれかが異なる同一Caseが非等価になる
- [ ] `PermissionKind`の同一Caseが等価、異なるCaseが非等価になる

### Integration Tests

- なし

### UI Tests

- 新規UI Testは追加しない
- 既存UI Testが成功することを確認する

### Manual Tests

- なし

## Test Fixtures

- `PermissionKind`: 承認済みの固定Case
- `code`: 個人情報を含まない`TEST_CODE_A`、`TEST_CODE_B`
- `localDateKey`: 架空の固定値`2026-01-01`、`2026-01-02`
- Coordinates: 使用しない
- Media Identifier: 使用しない

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

- `DriveLog/DriveLog/Shared/Errors/DriveLogError.swift`
- `DriveLog/DriveLog/Shared/Errors/PermissionKind.swift`
- `DriveLog/DriveLogTests/Shared/Errors/DriveLogErrorTests.swift`

## Files That Must Not Change

- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Item.swift`
- `DriveLog/DriveLogTests/DriveLogTests.swift`
- `DriveLog/DriveLogUITests/**/*.swift`
- `docs/**/*.md`
- Allowed Changesに記載されていないすべてのファイル

## Migration Requirements

- なし

## Performance Constraints

- MainActorへ依存しない
- 同期的な値型の生成と比較だけを行う

## Cancellation Behavior

- `DriveLogError.cancelled`を通常の失敗と区別できること
- Cancellation処理自体は実装しない

## Logging Requirements

- Logging処理を追加しない
- 自由文字列ログを追加しない

## Definition of Done

- [ ] `PermissionKind`のCase構成が承認されている
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
- [ ] 個人情報をエラーまたはTest Fixtureへ含めていない
- [ ] 外部依存追加なし
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

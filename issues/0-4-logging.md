# [Foundation] Logging ProtocolとOSLog実装を追加する

## Summary

DriveLog全体で、個人情報を記録せず、定義済みの構造化イベントだけをAppleの`Logger`へ出力できるLogging基盤を追加する。

## Background

`docs/implementation-plan.md`のPhase 0 Issue 0-4では、後続のPlatform、Data、Application各層が共通して利用する`Logging`、`LogEvent`、`OSLogLogger`、Test Doubleを実装する。`docs/interfaces.md`には`Logging`のメソッドと`LogEvent`のCaseが定義されているが、`Logger`へ渡すsubsystem、category、具体的なメッセージ表現は定義されていない。

このIssueでは設計済みのイベント以外を受け取らないInterfaceを維持し、座標、経路、メディア識別子などの個人情報が自由文字列として混入しないLogging基盤を作る。

## Goal

DriveLog全体で、設計文書に定義された`LogEvent`だけを`debug`、`info`、`error`の各レベルでAppleの`Logger`へ安全に出力できるLogging基盤を実装する。

## Non-Goals

- 自由文字列を受け取るLogging APIの追加
- 座標、経路、メディア識別子、メディアファイル名の記録
- Crash Reporting、Analytics、外部ログ送信の追加
- ログの永続化、検索、表示UIの実装
- `DriveLogError`から`LogEvent`への変換Helperの実装
- 既存Feature、View、Repository、Platform ServiceへのLogger接続
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

- Issue 0-3 `[Foundation] DriveLogErrorとPermissionKindを実装する`が完了していること
- subsystem、category、ログ形式の方針が承認されていること

## Approved Logging Configuration

設計文書には`Logger`のsubsystemとcategoryの具体値が定義されていない。また、各`LogEvent`をOSLogへ出力するときの固定メッセージとprivacy指定も定義されていない。

### 承認済み方針

- subsystem: `Bundle.main.bundleIdentifier ?? "com.ryosukeue.DriveLog"`
- category: `"application"`
- メッセージ: `LogEvent`のCaseごとに実装内で定義した固定イベント名を使用する
- `localDateKey`、`reasonCode`、`code`は文字列補間時に`privacy: .private`を指定する
- `count`は数値として記録し、`privacy: .private`を指定してよい

subsystemは実行中のApp Bundle Identifierへ追従させ、取得不能時だけ固定値`com.ryosukeue.DriveLog`を使用する。categoryは共通Logging基盤であることを示す`application`とする。将来categoryを責務別に分割する変更はこのIssueに含めない。

外部から自由文字列を渡せるLogging APIは追加しない。

## Scope

### Allowed Changes

- `issues/0-4-logging.md`
- `DriveLog/DriveLog/Shared/Logging/Logging.swift`
- `DriveLog/DriveLog/Shared/Logging/LogEvent.swift`
- `DriveLog/DriveLog/Shared/Logging/OSLogLogger.swift`
- `DriveLog/DriveLogTests/Shared/Logging/LoggingTests.swift`

### Forbidden Changes

- Allowed Changesに記載されていないすべてのファイル
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- Xcode初期テンプレートのSwiftファイル
- `DriveLogError`と`PermissionKind`の既存実装およびTest
- Target Membership、Target、Scheme、Build Configuration
- Signing、Bundle Identifier、Development Team
- Capability、Entitlements、CloudKit、iCloud同期
- Swift Packageまたはその他の外部依存
- Architecture文書または既存Interfaceの変更
- Crash ReportingまたはAnalytics SDK
- 関係のないファイルの整形

## Requirements

1. `docs/interfaces.md`に定義された`Logging`と`LogEvent`を実装する
2. `Logging`を`Sendable`へ準拠させる
3. `Logging`へ`debug(_:)`、`info(_:)`、`error(_:)`の3メソッドだけを定義する
4. 各メソッドは自由文字列ではなく`LogEvent`を受け取る
5. `OSLogLogger`はAppleの`Logger`を使用して`Logging`へ準拠する
6. `print()`、`debugPrint()`、`NSLog()`を使用しない
7. 緯度、経度、経路、PhotoKit localIdentifier、写真名、動画名、ユーザー分類内容をログへ含めない
8. `LogEvent`は`docs/interfaces.md`に定義された13 Caseだけを持つ
9. `LogEvent`を`Sendable`、`Equatable`へ準拠させる
10. 関連値には日付キー、件数、固定のreason codeまたはerror codeだけを許可する
11. 任意の自由文字列、NSError、OS固有Errorを`LogEvent`の関連値として追加しない
12. `SpyLogger`または同等のTest DoubleをTest Target内だけに実装する
13. Test Doubleはログレベルと`LogEvent`を発生順に保持できるようにする
14. `LogEvent`の全Case生成、Equatable、`debug`、`info`、`error`をまたぐ受信順序をSwift Testingで確認する
15. Xcode初期テンプレートのSwiftファイルを変更しない
16. 外部Packageを追加しない
17. `DriveLogError`と`PermissionKind`の既存実装を変更しない

## Input

- `docs/interfaces.md`に定義された`LogEvent`
- `debug`、`info`、`error`のログレベル
- 個人情報を含まない固定code
- `YYYY-MM-DD`形式の`localDateKey`
- 0以上の処理件数

## Output

- `OSLogLogger`からAppleの`Logger`へ出力される構造化ログ
- Test Target内のSpyへ発生順に記録されるログレベルと`LogEvent`

## State Changes

- 本番コードではSwiftData、UI State、アプリ状態を変更しない
- Test DoubleだけがTest内で受信記録を保持する

## Error Handling

- Loggingメソッドは`throws`を追加せず、`docs/interfaces.md`の同期Interfaceを維持する
- Logging失敗をクラッシュ条件にしない
- `fatalError()`、`try!`、`as!`で処理しない
- 元のNSErrorまたはOS固有Errorを保持、出力しない

## Privacy Requirements

- 正確な緯度、経度、移動経路をLoggerまたはTest Fixtureへ含めない
- PhotoKit localIdentifier、写真名、動画名をLoggerまたはTest Fixtureへ含めない
- ユーザー分類内容をLoggerまたはTest Fixtureへ含めない
- 許可する関連値を`localDateKey`、件数、固定codeに限定する
- 自由文字列を受け取るLogging APIを追加しない
- 外部通信、Crash Reporting、Analyticsを追加しない

## UI Requirements

- なし

## Accessibility Requirements

- なし

## Processing Rules

- なし

## Data Model Rules

- なし

## Interface Contract

`Logging`と`LogEvent`は`docs/interfaces.md`の定義と一致させる。

```swift
protocol Logging: Sendable {
    func debug(_ event: LogEvent)
    func info(_ event: LogEvent)
    func error(_ event: LogEvent)
}
```

```swift
enum LogEvent: Sendable, Equatable {
    case locationMonitoringStarted
    case locationMonitoringStopped
    case locationEventSaved(localDateKey: String)
    case locationEventRejected(reasonCode: String)
    case motionEventSaved(localDateKey: String)
    case visitEventSaved(localDateKey: String)
    case dayProcessingStarted(localDateKey: String)
    case dayProcessingCompleted(localDateKey: String)
    case dayProcessingFailed(localDateKey: String, code: String)
    case mediaCacheRefreshed(localDateKey: String, count: Int)
    case dayDeletionCompleted(localDateKey: String)
    case dayDeletionFailed(localDateKey: String, code: String)
    case permissionStateChanged
}
```

`OSLogLogger`は`Logging`へ準拠し、`debug`、`info`、`error`をそれぞれApple `Logger`の同名レベルへ対応させる。

## Implementation Method

1. `Shared/Logging/`を最初の実ファイル追加時に作成する
2. `Logging.swift`へ設計文書どおりのProtocolを定義する
3. `LogEvent.swift`へ設計文書どおりの13 Caseを定義する
4. `OSLogLogger.swift`へAppleの`Logger`を使用する具体実装を追加する
5. Caseごとの固定イベント名と許可された関連値だけをprivateな変換処理でLoggerへ渡す
6. Test Target内にログレベルとイベントの記録型、および発生順を安全に保持するSpyを実装する
7. Swift Testingで全Caseの生成、Equatable、ログレベルをまたぐ受信順序を確認する

## Implementation Constraints

- Allowed Changes以外を変更しない
- `Logging`のメソッドまたは`LogEvent`のCaseを独自追加しない
- 自由文字列Logging APIを追加しない
- `OSLogLogger.swift`以外の本番ファイルへApple Frameworkをimportしない
- `Logger`とOSLog以外のログ手段を追加しない
- `print()`、`debugPrint()`、`NSLog()`を追加しない
- `fatalError()`、`try!`、`as!`を追加しない
- `@unchecked Sendable`、`nonisolated(unsafe)`を追加しない
- Test Doubleを本番Targetへ追加しない
- 未完成TODOを残さない
- 新規Warningを増やさない
- 外部Packageを追加しない

## Acceptance Criteria

- [ ] `Logging`が`Sendable`へ準拠している
- [ ] `Logging`が`debug`、`info`、`error`の3メソッドだけを持つ
- [ ] 各Loggingメソッドが`LogEvent`だけを受け取る
- [ ] `LogEvent`が`Sendable`、`Equatable`へ準拠している
- [ ] `LogEvent`の13 Caseが`docs/interfaces.md`と一致している
- [ ] `OSLogLogger`がAppleの`Logger`を使用している
- [ ] `debug`、`info`、`error`が対応するLoggerレベルへ出力される
- [ ] 固定イベント名と許可された関連値だけが出力される
- [ ] 自由文字列を受け取るAPIが存在しない
- [ ] `print()`、`debugPrint()`、`NSLog()`が含まれていない
- [ ] 禁止された個人情報が本番コードとTest Fixtureに含まれていない
- [ ] Test DoubleがTest Target内だけに存在する
- [ ] 全`LogEvent` Caseの生成とEquatableを確認するSwift Testingが成功する
- [ ] `debug`、`info`、`error`の受信順序を確認するSwift Testingが成功する
- [ ] `DriveLogError`と`PermissionKind`が変更されていない
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

- [ ] `LogEvent`の13 Caseを生成できる
- [ ] 同じCaseと関連値を持つ`LogEvent`が等価になる
- [ ] 異なるCaseの`LogEvent`が非等価になる
- [ ] `localDateKey`、`reasonCode`、`code`、`count`が異なる同一Caseが非等価になる
- [ ] Test Doubleが`debug`、`info`、`error`を呼び出し順に記録する
- [ ] 記録からログレベルと`LogEvent`の両方を検証できる

### Integration Tests

- なし

### UI Tests

- 新規UI Testは追加しない
- 既存UI Testが成功することを確認する

### Manual Tests

- [ ] Simulatorで`OSLogLogger`を使用してもクラッシュしないことを確認する
- OSLog Consoleの文字列内容確認は自動Test対象外とし、実施した場合だけ結果を報告する

## Test Fixtures

- `localDateKey`: `2026-01-01`、`2026-01-02`
- `reasonCode`: `TEST_REASON_A`、`TEST_REASON_B`
- `code`: `TEST_CODE_A`、`TEST_CODE_B`
- `count`: `0`、`1`、`2`
- Coordinates: 使用しない
- Media Identifier: 使用しない
- Media Filename: 使用しない

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

- `DriveLog/DriveLog/Shared/Logging/Logging.swift`
- `DriveLog/DriveLog/Shared/Logging/LogEvent.swift`
- `DriveLog/DriveLog/Shared/Logging/OSLogLogger.swift`
- `DriveLog/DriveLogTests/Shared/Logging/LoggingTests.swift`

## Files That Must Not Change

- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Item.swift`
- `DriveLog/DriveLog/Shared/Errors/DriveLogError.swift`
- `DriveLog/DriveLog/Shared/Errors/PermissionKind.swift`
- `DriveLog/DriveLogTests/Shared/Errors/DriveLogErrorTests.swift`
- `DriveLog/DriveLogTests/DriveLogTests.swift`
- `DriveLog/DriveLogUITests/**/*.swift`
- `docs/**/*.md`
- Allowed Changesに記載されていないすべてのファイル

## Migration Requirements

- なし

## Performance Constraints

- MainActorへ依存しない
- Logging呼び出しで重い処理または外部通信を行わない
- LogEvent以外の大きなPayloadを保持しない

## Cancellation Behavior

- なし

## Logging Requirements

- `LogEvent`の13 Caseだけを出力する
- `debug`、`info`、`error`を対応するApple `Logger`レベルへ出力する
- 固定イベント名と許可された関連値だけを使用する
- 個人情報と自由文字列を出力しない

## Definition of Done

- [ ] subsystemとcategoryの具体値が承認されている
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
- [ ] 個人情報をログまたはTest Fixtureへ含めていない
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

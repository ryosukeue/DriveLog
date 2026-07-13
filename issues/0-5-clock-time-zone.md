# [Foundation] ClockとTimeZone依存を抽象化する

## Summary

DriveLog内で現在時刻と現在のシステムタイムゾーンを直接参照せず、呼び出し側から差し替え可能にするFoundation層のProtocolとProduction実装を追加する。

## Background

`docs/implementation-plan.md`のPhase 0 Issue 0-5では、後続の時刻依存処理を決定的にテストできるよう、`Clock`と`TimeZoneProviding`を先に実装する。`docs/interfaces.md`では両ProtocolのProperty APIと`SystemClock`が定義され、`docs/architecture.md`と`docs/coding-rules.md`では現在時刻および現在のタイムゾーンへの直接依存を避けることが求められている。

このIssueでは現在値の取得だけを抽象化する。記録時のタイムゾーン情報、UTC Offset、`localDateKey`を組み立てる`LocalTimeContext`関連処理はIssue 0-6で実装する。

## Goal

現在時刻と現在のシステムタイムゾーンを、`Sendable`なProtocolを介してProduction実装またはTest Doubleへ差し替えられるFoundation層を実装する。

## Non-Goals

- `localDateKey`の生成
- 日付境界、Calendar、UTC Offsetの計算
- `RecordedTimeContext`、`LocalTimeContextProviding`、`DefaultLocalTimeContextProvider`の実装
- 既存コードにある`Date()`または`TimeZone.current`の置換
- AppContainerまたは既存Featureへの依存注入
- UI、SwiftData、Platform Service、Loggingの変更
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

- Issue 0-4 `[Foundation] Logging ProtocolとOSLog実装を追加する`が完了していること
- Xcode Projectの同期ルートが`DriveLog/DriveLog`であること

## Approved API and Design Decisions

### 設計文書で確定しているAPI

`docs/interfaces.md`に次の宣言が明記されているため、このIssueでは別案を採用しない。

- `Clock`は`func now() -> Date`ではなく、`var now: Date { get }`を使用する
- `TimeZoneProviding`は`var current: TimeZone { get }`を使用する
- 現在時刻のProduction実装名は`SystemClock`とする

### 承認済み方針

- タイムゾーンのProduction実装名は`docs/implementation-plan.md`のIssue 0-5に従い、`SystemTimeZoneProvider`とする
- `SystemTimeZoneProvider.current`は参照時点の`TimeZone.current`を返す計算Propertyとする
- Test Target内のTest Double名は`docs/test-plan.md`に合わせて`FakeClock`、`FakeTimeZoneProvider`とする
- `FakeClock`は注入された固定`Date`を返す
- `FakeTimeZoneProvider`は注入された固定`TimeZone`を返す
- 異なる固定値へ差し替える場合は、未同期の可変状態を持たせず値型のFakeを再生成する
- Test Doubleは本番Targetへ追加せず、Testファイル内に限定する

## Resolved Design Decisions

- `SystemTimeZoneProvider`の型名は`docs/implementation-plan.md`に記載されているが、`docs/interfaces.md`にはProduction実装の具体宣言がない
- `FakeClock`と`FakeTimeZoneProvider`はTestファイル内だけで使用するprivateな値型とし、固定値をInitializerで受け取る
- `FakeTimeZoneProvider`は可変状態を持たず、異なるタイムゾーンが必要な場合は新しい値を注入したFakeを再生成する

上記方針は実装開始前に承認済みである。

## Scope

### Allowed Changes

- `issues/0-5-clock-time-zone.md`
- `DriveLog/DriveLog/Shared/Time/Clock.swift`
- `DriveLog/DriveLog/Shared/Time/SystemClock.swift`
- `DriveLog/DriveLog/Shared/Time/TimeZoneProviding.swift`
- `DriveLog/DriveLog/Shared/Time/SystemTimeZoneProvider.swift`
- `DriveLog/DriveLogTests/Shared/Time/ClockTimeZoneTests.swift`

### Forbidden Changes

- Allowed Changesに記載されていないすべてのファイル
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- Xcode初期テンプレートのSwiftファイル
- `DriveLogError`と`PermissionKind`の既存実装およびTest
- `Logging`、`LogEvent`、`OSLogLogger`とLogging Test
- Target Membership、Target、Scheme、Build Configuration
- Signing、Bundle Identifier、Development Team
- Capability、Entitlements、CloudKit、iCloud同期
- Swift Packageまたはその他の外部依存
- Architecture文書または既存Interfaceの変更
- 関係のないファイルの整形

## Requirements

1. `docs/interfaces.md`に定義された`Clock`と`TimeZoneProviding`を実装する
2. `Clock`は`Sendable`へ準拠し、`var now: Date { get }`だけを現在時刻取得APIとして持つ
3. `TimeZoneProviding`は`Sendable`へ準拠し、`var current: TimeZone { get }`だけを現在タイムゾーン取得APIとして持つ
4. `SystemClock`は`Clock`へ準拠し、Property参照時点のFoundationの現在時刻を返す
5. `SystemTimeZoneProvider`は`TimeZoneProviding`へ準拠し、Property参照時点のFoundationのシステムタイムゾーンを返す
6. ProtocolとProduction実装は`Sendable`要件を満たす
7. Test Target内に固定時刻を返す`FakeClock`または同等のTest Doubleを実装する
8. Test Target内に任意の固定タイムゾーンを返す`FakeTimeZoneProvider`または同等のTest Doubleを実装する
9. Swift Testingで固定時刻と固定タイムゾーンを注入して取得できることを確認する
10. Swift Testingで異なる固定値を注入したTest Doubleへ差し替えられることを確認する
11. Swift Testingで`SystemClock`が呼出時点の現在時刻を返す基本動作を確認する
12. Swift Testingで`SystemTimeZoneProvider`が呼出時点の`TimeZone.current`と一致する基本動作を確認する
13. `localDateKey`生成、日付境界計算、UTC Offset計算を実装しない
14. `RecordedTimeContext`、`LocalTimeContextProviding`、`DefaultLocalTimeContextProvider`を追加しない
15. SwiftUI、UIKit、SwiftData、CoreLocation、CoreMotion、PhotoKitをimportしない
16. 既存ファイルの`Date()`または`TimeZone.current`を置換しない
17. Xcode初期テンプレート、共通Error、Logging、Project設定、外部Packageを変更しない
18. `fatalError()`、`try!`、`as!`を使用しない

## Input

- Foundationの現在時刻
- Foundationの現在のシステムタイムゾーン
- Testから注入する固定`Date`
- Testから注入する固定`TimeZone`

## Output

- `Clock.now`から取得できる`Date`
- `TimeZoneProviding.current`から取得できる`TimeZone`
- Test Doubleから決定的に取得できる固定値

## State Changes

- Production実装は状態を保持または変更しない
- Test Doubleは状態を変更せず、異なる固定値が必要な場合は再生成する
- SwiftData、UI State、アプリ状態の変更なし

## Error Handling

- 現在値取得APIは`throws`を追加せず、`docs/interfaces.md`の同期Interfaceを維持する
- 無効なTimeZone identifierを強制アンラップで処理しない
- `fatalError()`、`try!`、`as!`を使用しない

## Privacy Requirements

- 座標、経路、メディア識別子、メディアファイル名を扱わない
- Logger出力を追加しない
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

`Clock`と`TimeZoneProviding`は`docs/interfaces.md`の定義と一致させる。

```swift
import Foundation

protocol Clock: Sendable {
    var now: Date { get }
}
```

```swift
import Foundation

protocol TimeZoneProviding: Sendable {
    var current: TimeZone { get }
}
```

Production実装は次の責務を持つ。

```swift
struct SystemClock: Clock {
    var now: Date { Date() }
}
```

```swift
struct SystemTimeZoneProvider: TimeZoneProviding {
    var current: TimeZone { TimeZone.current }
}
```

## Implementation Method

1. `Shared/Time/`を最初の実ファイル追加時に作成する
2. `Clock.swift`へ設計文書どおりのProtocolを定義する
3. `SystemClock.swift`へFoundationの現在時刻を返す値型のProduction実装を追加する
4. `TimeZoneProviding.swift`へ設計文書どおりのProtocolを定義する
5. `SystemTimeZoneProvider.swift`へFoundationの現在のシステムタイムゾーンを返す値型のProduction実装を追加する
6. Test Target内へ固定値を注入できるTest Doubleを実装する
7. Swift TestingでTest DoubleとProduction実装の基本動作を確認する

## Implementation Constraints

- Allowed Changes以外を変更しない
- `Clock`と`TimeZoneProviding`へIssueにないAPIを追加しない
- Production実装を値型とし、Custom SingletonまたはService Locatorを作らない
- Test Doubleを本番Targetへ追加しない
- `Date()`は`SystemClock`のProduction実装以外の新規本番コードへ追加しない
- `TimeZone.current`は`SystemTimeZoneProvider`のProduction実装以外の新規本番コードへ追加しない
- Foundation以外のFrameworkをimportしない
- `@unchecked Sendable`、`nonisolated(unsafe)`を追加しない
- `fatalError()`、`try!`、`as!`、不要なForce Unwrapを追加しない
- `print()`を追加しない
- 未完成TODOを残さない
- 新規Warningを増やさない
- 外部Packageを追加しない

## Acceptance Criteria

- [ ] `Clock`が`Sendable`へ準拠している
- [ ] `Clock`が`var now: Date { get }`だけを現在時刻取得APIとして持つ
- [ ] `SystemClock.now`がFoundationの現在時刻を返す
- [ ] `TimeZoneProviding`が`Sendable`へ準拠している
- [ ] `TimeZoneProviding`が`var current: TimeZone { get }`だけを現在タイムゾーン取得APIとして持つ
- [ ] `SystemTimeZoneProvider.current`がFoundationの現在のシステムタイムゾーンを返す
- [ ] Test Target内のTest Doubleから固定時刻と固定タイムゾーンを取得できる
- [ ] 異なる固定値を注入したFakeへ差し替えられる
- [ ] `LocalTimeContext`関連型または日付計算が追加されていない
- [ ] 禁止Frameworkがimportされていない
- [ ] 既存ファイルの`Date()`と`TimeZone.current`が置換されていない
- [ ] Xcode初期テンプレート、共通Error、Logging、`project.pbxproj`が変更されていない
- [ ] 外部Packageが追加されていない
- [ ] Buildが成功する
- [ ] 対象Unit Testと既存Testが成功する
- [ ] SwiftLintが成功する
- [ ] SwiftFormat Checkが成功する
- [ ] `git diff --check`が成功する
- [ ] 新規Warningがない
- [ ] 仕様外変更がない

## Test Requirements

### Unit Tests

- [ ] `FakeClock`へ固定`Date`を注入すると同じ値を返す
- [ ] `FakeTimeZoneProvider`へ固定`TimeZone`を注入すると同じ値を返す
- [ ] 異なる固定値を注入した`FakeClock`と`FakeTimeZoneProvider`へ差し替えられる
- [ ] `SystemClock.now`が取得直前と直後のFoundation時刻の範囲内になる
- [ ] `SystemTimeZoneProvider.current`がFoundationの`TimeZone.current`と一致する
- [ ] Testは実行順、端末の固定日時、固定タイムゾーンへ依存しない

### Integration Tests

- なし

### UI Tests

- 新規UI Testは追加しない
- 既存UI Testが成功することを確認する

### Manual Tests

- なし

## Test Fixtures

- Clock: `Date(timeIntervalSince1970: 1_700_000_000)`
- TimeZone: `Asia/Tokyo`、変更確認用に`Asia/Taipei`
- Coordinates: 使用しない
- Repository: 使用しない
- Provider: `FakeTimeZoneProvider`
- Other: 実ユーザーデータを使用しない

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

- `issues/0-5-clock-time-zone.md`
- `DriveLog/DriveLog/Shared/Time/Clock.swift`
- `DriveLog/DriveLog/Shared/Time/SystemClock.swift`
- `DriveLog/DriveLog/Shared/Time/TimeZoneProviding.swift`
- `DriveLog/DriveLog/Shared/Time/SystemTimeZoneProvider.swift`
- `DriveLog/DriveLogTests/Shared/Time/ClockTimeZoneTests.swift`

## Files That Must Not Change

- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Item.swift`
- `DriveLog/DriveLog/Shared/Errors/**/*.swift`
- `DriveLog/DriveLog/Shared/Logging/**/*.swift`
- `DriveLog/DriveLogTests/Shared/Errors/**/*.swift`
- `DriveLog/DriveLogTests/Shared/Logging/**/*.swift`
- `DriveLog/DriveLogTests/DriveLogTests.swift`
- `DriveLog/DriveLogUITests/**/*.swift`
- `docs/**/*.md`
- Allowed Changesに記載されていないすべてのファイル

## Migration Requirements

- なし

## Performance Constraints

- MainActorへ依存しない
- Property取得時に重い処理、永続化、外部通信を行わない
- DateFormatterまたはCalendarを生成しない

## Cancellation Behavior

- なし

## Logging Requirements

- 新規LogEventまたはLogger出力を追加しない

## Definition of Done

- [ ] API候補の設計判断が承認されている
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

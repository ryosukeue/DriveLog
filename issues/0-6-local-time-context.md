# [Foundation] LocalTimeContextProviderを実装する

## Summary

イベント取得時のTimeZone identifier、UTC offset、`YYYY-MM-DD`形式の`localDateKey`を一度に生成するFoundation層を追加する。

## Background

生イベントは記録時の現地日付へ固定し、端末のTimeZone変更後に所属日を再計算してはならない。Issue 0-5で追加した`TimeZoneProviding`を利用し、後続のLocation、Motion、Visit Providerが共通して利用できる時刻Contextを実装する。

## Goal

任意のイベント時刻と注入された現在TimeZoneから、記録時のTimeZone identifier、イベント時点のUTC offset、現地日付キーを決定的に生成できる。

## Non-Goals

- 生イベントまたはSwiftData Modelの追加
- 日付境界でのイベント分割
- Calendar UI用の月計算
- 既存イベントの`localDateKey`再計算
- Location、Motion、Visit Providerへの接続

## Required Documents

- [ ] `docs/project-rules.md`
- [ ] `docs/architecture.md`
- [ ] `docs/component-specs.md`
- [ ] `docs/data-model.md`
- [ ] `docs/interfaces.md`
- [ ] `docs/coding-rules.md`
- [ ] `docs/test-plan.md`

## Dependencies

- Issue 0-5の`TimeZoneProviding`が実装済みであること

## Decisions

- `RecordedTimeContext`と`LocalTimeContextProviding`は`docs/interfaces.md`の宣言をそのまま使用する
- Production実装名は`DefaultLocalTimeContextProvider`とする
- Calendar identifierはGregorianを使用し、注入されたTimeZoneをイベント時刻へ適用する
- UTC offsetは`TimeZone.secondsFromGMT(for:)`でイベント時点のDSTを反映する
- `localDateKey`はCalendar componentsをPOSIX固定書式`%04d-%02d-%02d`へ変換する
- Formatterの共有可変状態を持たず、Providerを`Sendable`な値型に保つ

## Scope

### Allowed Changes

- `issues/0-6-local-time-context.md`
- `DriveLog/DriveLog/Shared/Time/RecordedTimeContext.swift`
- `DriveLog/DriveLog/Shared/Time/LocalTimeContextProviding.swift`
- `DriveLog/DriveLog/Shared/Time/DefaultLocalTimeContextProvider.swift`
- `DriveLog/DriveLogTests/Shared/Time/LocalTimeContextProviderTests.swift`

### Forbidden Changes

- Allowed Changes外のすべてのファイル
- `project.pbxproj`、Signing、Bundle Identifier、Team、Capability
- Xcode初期テンプレート
- 既存Errors、Logging、Clock、TimeZone実装
- SwiftData、Platform Provider、UI
- 外部Package

## Requirements

1. `RecordedTimeContext`を`Sendable, Equatable`準拠で実装する
2. `timeZoneIdentifier`、`utcOffsetSeconds`、`localDateKey`を保持する
3. `LocalTimeContextProviding`を`Sendable`準拠で実装する
4. APIを`func makeContext(for date: Date) -> RecordedTimeContext`とする
5. `DefaultLocalTimeContextProvider`を状態を持たない値型として実装する
6. `TimeZoneProviding`をInitializer Injectionする
7. イベント時点のDSTをUTC offsetへ反映する
8. `localDateKey`を`YYYY-MM-DD`形式で生成する
9. 現在TimeZoneを過去Contextへ再適用しない
10. SwiftUI、UIKit、SwiftData、CoreLocation、CoreMotion、PhotoKitをimportしない
11. `fatalError()`、`try!`、`as!`、Force Unwrapを使用しない

## Interface Contract

```swift
struct RecordedTimeContext: Sendable, Equatable {
    let timeZoneIdentifier: String
    let utcOffsetSeconds: Int
    let localDateKey: String
}

protocol LocalTimeContextProviding: Sendable {
    func makeContext(for date: Date) -> RecordedTimeContext
}
```

## Acceptance Criteria

- [ ] Asia/TokyoとAsia/Taipeiで正しいidentifier、offset、日付キーを生成できる
- [ ] UTC日付と現地日付が異なる時刻を正しく処理できる
- [ ] 23:59から翌日へ正しく切り替わる
- [ ] TimeZone変更前に生成したContextが変化しない
- [ ] DST開始・終了境界でイベント時点のoffsetを返す
- [ ] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する
- [ ] 新規Warningと仕様外変更がない

## Test Requirements

### Unit Tests

- [ ] Asia/Tokyo
- [ ] Asia/Taipei
- [ ] UTCと現地日付の差
- [ ] 現地23:59と翌日00:01
- [ ] ProviderのTimeZone変更後も既存Contextが不変
- [ ] America/Los_AngelesのDST開始
- [ ] America/Los_AngelesのDST終了

### Integration Tests

- なし

### UI Tests

- 新規追加なし。既存UI Testを実行する

### Manual Tests

- なし

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- `issues/0-6-local-time-context.md`
- `DriveLog/DriveLog/Shared/Time/RecordedTimeContext.swift`
- `DriveLog/DriveLog/Shared/Time/LocalTimeContextProviding.swift`
- `DriveLog/DriveLog/Shared/Time/DefaultLocalTimeContextProvider.swift`
- `DriveLog/DriveLogTests/Shared/Time/LocalTimeContextProviderTests.swift`

## Migration Requirements

- なし

## Performance Constraints

- MainActorへ依存しない
- 共有可変Formatterを作らない

## Logging Requirements

- 新規ログなし

## Definition of Done

- [ ] Goal、Acceptance Criteria、Test Requirementsを満たす
- [ ] Allowed Changes内の変更だけである
- [ ] Build、Test、SwiftLint、SwiftFormat、Diff Check成功
- [ ] 新規Warning、TODO、外部依存、Privacy違反なし

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
- Warnings:

### Deviations

### Unresolved Issues

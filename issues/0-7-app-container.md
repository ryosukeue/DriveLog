# [Foundation] AppContainerの骨格を作成する

## Summary

DriveLogのComposition Rootとなる`AppContainer`を追加し、実装済みのFoundation依存を生成・差し替えできるようにする。

## Background

Issue 0-3から0-6で、Logging、Clock、TimeZone、LocalTimeContextの抽象とProduction実装が揃った。今後のFeatureが依存をInitializer Injectionで受け取れるよう、未実装依存のPlaceholderを作らずComposition Rootの骨格を先に確立する。

## Goal

実装済みFoundation依存をProduction生成またはInitializer Injectionできる`AppContainer`を作る。

## Non-Goals

- 未実装のService、Repository、Processing、UseCase、Coordinatorの追加
- `DriveLogApp`やFeatureへの依存注入
- Xcode初期テンプレートの置換

## Required Documents

実装前に次を読むこと。

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 0-3 `DriveLogError`と`PermissionKind`
- Issue 0-4 Logging基盤
- Issue 0-5 ClockとTimeZone依存
- Issue 0-6 LocalTimeContextProvider

## Scope

### Allowed Changes

- `issues/0-7-app-container.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLogTests/Application/AppContainerTests.swift`

### Forbidden Changes

- Xcode初期テンプレートのSwiftファイル
- 既存Foundation実装とTest
- Project設定、Target、Scheme、Build Configuration
- Signing、Bundle Identifier、Development Team、Capability
- 外部Package
- 未実装依存のProtocol Placeholder

## Requirements

1. `AppContainer`をComposition Rootとして追加する。
2. `Logging`、`Clock`、`TimeZoneProviding`、`LocalTimeContextProviding`を保持する。
3. すべての依存をInitializer Injectionで差し替え可能にする。
4. Production initializerは`OSLogLogger`、`SystemClock`、`SystemTimeZoneProvider`、`DefaultLocalTimeContextProvider`を生成する。
5. `DefaultLocalTimeContextProvider`にはContainerと同じ`TimeZoneProviding`実装を注入する。
6. 未実装のService、Repository、UseCaseを追加しない。
7. Custom Singleton、Service Locator、共有可変状態を作らない。
8. Featureへ`AppContainer`全体を渡すAPIを追加しない。
9. 外部Packageを追加しない。

## Input

- Production initializer、または4つのFoundation依存

## Output

- 生成済みのFoundation依存を保持する`AppContainer`

## State Changes

- なし

## Error Handling

- Container生成時に失敗する処理を追加しない。
- 強制終了APIを使用しない。

## Privacy Requirements

- 座標、経路、メディア識別子、ファイル名を扱わない。
- 外部通信を追加しない。

## UI Requirements

- なし

## Accessibility Requirements

- なし

## Processing Rules

- なし

## Data Model Rules

- なし

## Interface Contract

```swift
final class AppContainer {
    let logger: any Logging
    let clock: any Clock
    let timeZoneProvider: any TimeZoneProviding
    let localTimeContextProvider: any LocalTimeContextProviding
}
```

Production生成用initializerと、4依存を受け取るinitializerを提供する。

## Implementation Constraints

- Initializer Injectionを使用する。
- FeatureへContainer全体を渡さない。
- Custom SingletonやService Locatorを作らない。
- `fatalError()`、`try!`、`as!`、`print()`を追加しない。
- 未完成TODOや新規Warningを残さない。

## Acceptance Criteria

- [ ] `AppContainer`がComposition Rootとして存在する。
- [ ] 4つのFoundation依存をInitializer Injectionで差し替えられる。
- [ ] Production initializerが4つのProduction実装を生成する。
- [ ] 未実装依存のPlaceholderがない。
- [ ] Container全体をFeatureへ渡すAPIがない。
- [ ] Buildと全Testが成功する。
- [ ] SwiftLintとSwiftFormat Checkが成功する。
- [ ] `git diff --check`が成功する。
- [ ] 新規Warningと仕様外変更がない。

## Test Requirements

### Unit Tests

- [ ] 注入したLoggerがContainer経由で利用される。
- [ ] 注入したClockが固定時刻を返す。
- [ ] 注入したTimeZone Providerが固定タイムゾーンを返す。
- [ ] 注入したLocalTimeContext Providerが固定Contextを返す。
- [ ] Production initializerが基本動作する。

### Integration Tests

- なし

### UI Tests

- 既存UI Testが成功すること。

### Manual Tests

- なし

## Test Fixtures

- SpyLogger
- FixedClock
- FixedTimeZoneProvider
- FixedLocalTimeContextProvider

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- `issues/0-7-app-container.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLogTests/Application/AppContainerTests.swift`

## Files That Must Not Change

- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Item.swift`
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`

## Migration Requirements

- なし

## Performance Constraints

- MainActor上で重い処理をしない。

## Cancellation Behavior

- なし

## Logging Requirements

- このIssue固有のLogEventは追加しない。

## Decisions

- Production initializerは未実装依存を先取りせず、現時点で利用できる4つのFoundation依存だけを生成する。
- Containerは将来MainActor依存を保持する可能性があるため、このIssueでは`Sendable`準拠を追加しない。

## Definition of Done

- [ ] Goal、Requirements、Acceptance Criteriaを満たす。
- [ ] Required DocumentsとAllowed Changesに従う。
- [ ] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [ ] 個人情報をログへ出していない。
- [ ] 未解決のTODOや仕様外変更がない。

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

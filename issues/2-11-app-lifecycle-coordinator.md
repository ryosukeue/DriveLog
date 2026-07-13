# [Application] AppLifecycleCoordinator基礎を実装する

## Summary

アプリのLaunch、Foreground復帰、Background移行を受け取るライフサイクルCoordinatorの基礎を追加する。

## Goal

LaunchとForeground復帰で権限状態を更新して監視開始状態を再評価し、通常のBackground移行でSLCを停止しない調整層を実装する。

## Non-Goals

- 未処理日の検出・Foreground fallback処理
- Photo Library変更の反映
- BGTask登録・予約とApp Entry Pointへの接続

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 2-8 PermissionManaging
- Issue 2-10 StartMonitoringUseCase

## Scope

### Allowed Changes

- `issues/2-11-app-lifecycle-coordinator.md`
- `DriveLog/DriveLog/Application/AppLifecycleCoordinator.swift`
- `DriveLog/DriveLogTests/Application/AppLifecycleCoordinatorTests.swift`

### Forbidden Changes

- Provider、Repository、PermissionCoordinator、StartMonitoringUseCase
- AppContainer、App Entry Point、UI、Project設定
- Signing、Capability、外部Package

## Requirements

1. `AppLifecycleCoordinating`を`@MainActor`のclass-only Protocolとして定義する。
2. Protocolは`handleLaunch()`、`handleForeground()`、`handleBackground()`の3つのasync APIを持つ。
3. 具体Coordinatorは`PermissionManaging`と`StartMonitoringUseCase`をInitializer Injectionする。
4. Launch時は権限状態を更新してから監視開始UseCaseを実行する。
5. Foreground復帰時も権限状態を更新してから監視開始UseCaseを実行する。
6. 監視開始失敗でアプリのライフサイクル処理をクラッシュさせず、次回のLaunch／Foregroundで再試行可能にする。
7. Background移行ではSLC、Motion、Visit、生イベント購読を停止しない。
8. Background移行時の停止UseCaseや高精度GPSを追加しない。

## Acceptance Criteria

- [x] `AppLifecycleCoordinating`が設計どおり定義されている。
- [x] LaunchとForegroundで権限更新後に監視開始を試行する。
- [x] 監視開始失敗がLifecycle APIから伝播せず、次回に再試行できる。
- [x] BackgroundでProviderのstopが呼ばれない。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規ソースWarningと仕様外変更がない。

## Decisions

- `StartMonitoringUseCase.execute()`のLocation開始ErrorはLifecycle境界で吸収する。固定13件の`LogEvent`にLifecycle開始失敗専用caseがないため、意味の異なるEventは流用しない。
- 未処理日確認はIssue 4-8、Media変更反映はPhase 8、BGTask予約はPhase 11で依存が揃った時点に接続する。
- Backgroundの基礎実装は意図的なno-opとし、SLC継続をUnit Testで保証する。

## Interface Contract

```swift
@MainActor
protocol AppLifecycleCoordinating: AnyObject {
    func handleLaunch() async
    func handleForeground() async
    func handleBackground() async
}
```

## Test Requirements

### Unit Tests

- [x] Launchで権限更新と監視開始が行われる。
- [x] Foregroundで権限更新と監視状態再確認が行われる。
- [x] Location開始失敗後のForegroundで再試行できる。
- [x] Backgroundで各Providerが停止されない。

### Integration Tests

- なし。

### UI Tests

- なし。

### Manual Tests

- SLCのBackground継続は実機確認Issueで確認する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- `issues/2-11-app-lifecycle-coordinator.md`
- `DriveLog/DriveLog/Application/AppLifecycleCoordinator.swift`
- `DriveLog/DriveLogTests/Application/AppLifecycleCoordinatorTests.swift`

## Definition of Done

- [x] GoalとAcceptance Criteriaを満たす。
- [x] Allowed Changes内だけを変更する。
- [x] 全検証が成功する。

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
### Manual Verification
### Deviations
### Unresolved Issues

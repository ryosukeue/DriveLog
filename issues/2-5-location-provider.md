# [Platform] LocationProvidingを実装する

## Summary

Significant Location Change監視をSwift Concurrency境界へ変換し、Core Locationの位置をDomain Dataとして配信するProviderを追加する。

## Goal

高精度GPSを開始せず、SLCの状態・位置・固定化した現地時間情報・エラーをApplication層から利用可能にする。

## Non-Goals

- 位置権限要求UIと設定アプリ導線
- RawEventRepositoryへの保存、日次処理
- Visit監視、連続高精度GPS、Background Capability設定

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 0-3 DriveLogError／PermissionKind
- Issue 0-6 LocalTimeContextProviding
- Issue 1-1 LocationEventData

## Scope

### Allowed Changes

- `issues/2-5-location-provider.md`
- `DriveLog/DriveLog/Platform/Location/LocationProviding.swift`
- `DriveLog/DriveLog/Platform/Location/CoreLocationProvider.swift`
- `DriveLog/DriveLogTests/TestSupport/FakeLocationProvider.swift`
- `DriveLog/DriveLogTests/Platform/CoreLocationProviderTests.swift`

### Forbidden Changes

- Domain型、Repository、SwiftData、Application、UI
- Info.plist、Capability、Signing、Deployment Target
- 高精度GPS、Region Monitoring、外部Package

## Requirements

1. `LocationProviding: Sendable`を`docs/interfaces.md`のsignatureどおり定義する。
2. stopped／starting／running／unavailable／failed状態を公開する。
3. 位置、状態変更、DriveLogErrorを単一の`AsyncStream`へ配信する。
4. Production実装は`CLLocationManager.startMonitoringSignificantLocationChanges()`だけを使用する。
5. `startUpdatingLocation()`を使用しない。
6. CLLocationの座標、timestamp、horizontalAccuracy、有効なspeedをLocationEventDataへ変換する。
7. createdAtはClock、記録時のtimeZone／offset／localDateKeyはLocalTimeContextProvidingから取得する。
8. 不正座標、負の水平精度、5分を超える未来timestampは位置eventとして配信しない。
9. Core Locationエラーを座標等を含まない固定codeのDriveLogErrorへ変換する。
10. SLC利用不可時は`.unavailable`へ遷移して`monitoringUnavailable`を返す。
11. Test Targetに任意event、state、start／stop回数を扱えるFakeを追加する。
12. Conversion、Stream、error変換、FakeをSwift Testingで検証する。

## Acceptance Criteria

- [x] Protocol、状態、eventが設計文書と一致する。
- [x] SLC以外の位置監視APIを開始しない。
- [x] CLLocationを記録時time context付きDomain Dataへ変換できる。
- [x] 無効値とOS errorを安全に変換できる。
- [x] Fakeでevent、error、state、start／stop回数を検証できる。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規ソースWarningと仕様外変更がない。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Decisions

- 「大幅に未来」は公開APIへ影響しない受信検証値として5分を採用する。
- CLLocationの負speedはCore Locationの無効値としてnilへ変換する。
- Usage Descriptionと権限要求はPermission Issueで追加し、このIssueは監視境界と変換に限定する。

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

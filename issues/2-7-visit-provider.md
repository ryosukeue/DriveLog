# [Platform] VisitProvidingを実装する

## Summary

CLVisit監視をarrival-only／departure確定のDomain Eventへ変換し、AsyncStreamで配信するProviderを追加する。

## Goal

Visit監視を独立したPlatform境界として提供し、記録時の現地日付情報を固定したVisitEventDataを生成する。

## Non-Goals

- 同一Visitの永続化判定と更新
- Stay判定、位置／Motion監視
- 権限要求UIとApplication配線

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
- Issue 1-1 VisitEventData

## Scope

### Allowed Changes

- `issues/2-7-visit-provider.md`
- `DriveLog/DriveLog/Platform/Visit/VisitProviding.swift`
- `DriveLog/DriveLog/Platform/Visit/CoreLocationVisitProvider.swift`
- `DriveLog/DriveLogTests/TestSupport/FakeVisitProvider.swift`
- `DriveLog/DriveLogTests/Platform/CoreLocationVisitProviderTests.swift`

### Forbidden Changes

- Domain型、Repository、SwiftData、Application、UI
- Location／Motion Provider、Project設定、Signing、外部Package

## Requirements

1. `VisitProviding: Sendable`を設計signatureどおり定義する。
2. stopped／starting／running／unavailable／failed状態を公開する。
3. visit、状態変更、DriveLogErrorを単一AsyncStreamへ配信する。
4. Production実装は`startMonitoringVisits()`／`stopMonitoringVisits()`を使用する。
5. CLVisitの座標、水平精度、arrivalDate、departureDateを変換する。
6. `Date.distantPast`のarrivalと`Date.distantFuture`のdepartureをnilへ正規化する。
7. time contextはarrival、departure、Clock.nowの順で利用可能な時刻を使用する。
8. 位置サービス利用不可／拒否／delegate errorをDriveLogErrorへ変換する。
9. 同一Visit判定をProviderへ追加しない。
10. Test Targetに未完了Visit、出発更新、無event、error、呼出回数を扱えるFakeを追加する。
11. Conversion、sentinel、time context、Stream、FakeをSwift Testingで検証する。

## Acceptance Criteria

- [x] Protocol、state、eventが設計文書と一致する。
- [x] arrival-onlyとdeparture確定Visitを変換できる。
- [x] Apple sentinel Dateをnilとして扱える。
- [x] 記録時time contextを固定できる。
- [x] Fakeで未完了／更新／無event／error／呼出回数を検証できる。
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

- 設計文書にVisitMonitoringStateのcase列挙がないため、Locationと対称な5状態を採用する。
- 両日時が未確定の場合だけClock.nowをtime context基準とし、推測arrival／departureは作らない。
- CLVisitは公開initializerがないため、OS型から作る内部SnapshotをConversion Test対象にする。

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

# [Platform] MotionProvidingを実装する

## Summary

Core MotionのActivity更新を全flagとconfidenceを保持したDomain Eventへ変換し、AsyncStreamで配信するProviderを追加する。

## Goal

Motion監視を位置監視から独立した失敗境界として抽象化し、記録時の現地日付情報付きで利用可能にする。

## Non-Goals

- MotionEventの永続化と日次分類
- 権限要求UI、位置／Visit監視
- 過去期間のMotion query

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
- Issue 1-1 MotionEventData／MotionConfidence

## Scope

### Allowed Changes

- `issues/2-6-motion-provider.md`
- `DriveLog/DriveLog/Platform/Motion/MotionProviding.swift`
- `DriveLog/DriveLog/Platform/Motion/CoreMotionProvider.swift`
- `DriveLog/DriveLogTests/TestSupport/FakeMotionProvider.swift`
- `DriveLog/DriveLogTests/Platform/CoreMotionProviderTests.swift`

### Forbidden Changes

- Domain型、Repository、SwiftData、Application、UI
- Location／Visit Provider、Project設定、Signing、外部Package

## Requirements

1. `MotionProviding: Sendable`を設計signatureどおり定義する。
2. stopped／starting／running／unavailable／failed状態を公開する。
3. motion、状態変更、DriveLogErrorを単一AsyncStreamへ配信する。
4. Core Motionのautomotive／walking／running／cycling／stationary／unknownを個別Boolのまま保持する。
5. low／medium／high confidenceをDomain型へ変換する。
6. startDateと記録時のtimeZone／offset／localDateKeyを保持し、endDateは未確定としてnilにする。
7. Activity利用不可はmonitoringUnavailable、拒否はpermissionDenied(.motion)へ変換する。
8. callback errorはOS error詳細を露出しない固定codeへ変換する。
9. stop後も再start可能とし、明示的終了時だけStreamをfinishできる。
10. Test Targetに任意event、拒否、状態、start／stop回数を扱えるFakeを追加する。
11. 全flag、複数flag、confidence、time context、error、FakeをSwift Testingで検証する。

## Acceptance Criteria

- [x] Protocol、state、eventが設計文書と一致する。
- [x] 全flagと3段階confidenceを欠落なく変換できる。
- [x] 記録時time contextを付与できる。
- [x] 利用不可／拒否／callback errorがDriveLogErrorになる。
- [x] Fakeでevent、error、state、呼出回数、Stream終了を検証できる。
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

- 設計文書にMotionMonitoringStateのcase列挙がないため、Locationと対称な5状態を採用する。
- Live callback時点ではactivity終了時刻が不明なためendDateはnilとし、推測値を作らない。
- stopは再開可能性を保つためStreamをfinishせず、Fakeのfinishで終了挙動を検証する。

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

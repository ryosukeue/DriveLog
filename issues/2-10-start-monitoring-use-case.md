# [Application] StartMonitoringUseCaseを実装する

## Summary

生イベント保存購読を準備してからLocation、Motion、Visit監視を開始し、補助Providerの失敗をLocation監視から分離するUseCaseを追加する。

## Goal

Locationを必須の監視として開始しつつ、Motion拒否やVisit失敗でも位置記録を継続できる冪等な監視開始処理を実装する。

## Non-Goals

- 権限要求UI
- Provider監視停止
- App lifecycle／Background処理

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

- Issues 2-5〜2-7 Provider
- Issue 2-9 RawEventStorageCoordinator
- Issue 0-4 Logging

## Scope

### Allowed Changes

- `issues/2-10-start-monitoring-use-case.md`
- `DriveLog/DriveLog/Application/Monitoring/StartMonitoringUseCase.swift`
- `DriveLog/DriveLogTests/Application/StartMonitoringUseCaseTests.swift`

### Forbidden Changes

- Provider、Repository、RawEventStorageCoordinator、Domain、UI、App Entry Point
- Project設定、Signing、外部Package

## Requirements

1. RawEventStorageCoordinatorの購読をProvider開始前に準備する。
2. Locationがstopped／unavailable／failedならSLC開始を試みる。
3. Locationがstarting／runningなら重複開始しない。
4. Location開始失敗は呼出元へthrowし、補助Providerを開始しない。
5. Location開始成功を固定LogEventで1回記録する。
6. MotionとVisitはLocation成功後、それぞれの状態に応じて独立して開始する。
7. Motion／Visitの開始失敗は互いとLocationへ伝播させない。
8. 同一UseCaseへの重複／再入executeでProvider開始回数を増やさない。
9. 高精度GPSや権限要求を追加しない。

## Acceptance Criteria

- [x] Location、Motion、Visitを開始できる。
- [x] Motion拒否でもLocationとVisitが継続する。
- [x] Visit失敗でもLocationとMotionが継続する。
- [x] Location失敗だけがexecuteのErrorになる。
- [x] starting／running Providerを重複開始しない。
- [x] 保存Stream購読が監視開始前に有効になる。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規ソースWarningと仕様外変更がない。

## Decisions

- 設計上LocationがMVP記録の必須経路であり、MotionとVisitは精度向上用の補助入力であるため、Locationだけをthrow対象とする。
- 補助Providerの失敗LogEventは固定13 caseに存在しないため、意味の異なるcaseを流用せず、Provider state／後続Lifecycle確認に委ねる。
- 監視開始中の再入executeは追加要求を行わず即時returnする。Lifecycleからの次回executeで状態を再確認できる。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

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

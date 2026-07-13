# [UI Test] 日別詳細基礎導線を追加する

## Summary

Calendarの有効移動日からDay Detailへ遷移し、地図Preview、基本サマリー、詳細統計、戻る導線をUI Testで確認する。

## Goal

Phase 6の主要画面が実AppのComposition Rootから操作可能であることを保証する。

## Non-Goals

- Full Map、Media、Override、削除

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 6-1〜6-7

## Scope

### Allowed Changes

- `issues/6-8-day-detail-ui-test.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Features/Calendar/CalendarView.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

### Forbidden Changes

- Schema、Repository、Processing、Signing、Project設定、外部Package

## Requirements

1. Calendarの有効日TapをDay Detail Navigationへ接続する。
2. AppContainerでDay Detail Repository、UseCase、ViewModelを生成する。
3. UI Test専用起動はDEBUG、明示Launch Argument、in-memory V1 Containerへ隔離する。
4. FixtureはAggregateとProcessing Stateだけを実Modelで保存し、通常Storeを変更しない。
5. UI Testで有効日、遷移、Map Preview、Summary、Statistics、戻るを確認する。
6. Full Map未実装のためMap Tap後の遷移はPhase 7へ残す。

## Decisions

- 空Storeでは有効日導線を再現できないため、`-ui-testing-day-detail`指定時だけ固定Fixtureをin-memory Containerへ投入する。コードは`#if DEBUG`でReleaseから除外する。
- 日付は起動時のClockとTime Zoneから生成し、月境界でもCalendar表示月と一致させる。

## Acceptance Criteria

- [x] CalendarからDay Detailへ遷移できる。
- [x] Map Preview、Summary、Statisticsが表示される。
- [x] Navigation BackでCalendarへ戻れる。
- [x] 通常起動の永続StoreへFixtureを保存しない。
- [x] Build、Unit Test、UI Test、Lint、Format、Diff Checkが成功する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
### Manual Verification
### Deviations
### Unresolved Issues

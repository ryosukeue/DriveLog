# [UI Test] Calendar主要導線を追加する

## Summary

Calendarを実際のApp起動経路へ接続し、月表示、空月、無効日、左右SwipeをSimulator UI Testで検証する。

## Goal

Phase 5のCalendar画面がユーザー操作可能な状態で起動することを保証する。

## Non-Goals

- DayDetail遷移（Phase 6）、Onboarding（Phase 12）、UI Test用Production Mock／Seed

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/5-7-calendar-ui-test.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Features/Calendar/CalendarView.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

### Forbidden Changes

- Schema／Model、Repository実装、DayDetail、UI Test用Production Fake／Seed、Project設定

## Requirements

1. AppContainerをComposition RootとしてCalendar Repository、UseCase、ViewModelを生成する。
2. DriveLogAppはV1 ModelContainerを生成し、CalendarをRoot NavigationStackへ表示する。
3. ModelContainer生成失敗時はfatalErrorせず、固定の起動Error画面を表示する。
4. ContentViewからSwiftData直接操作と初期Template UIを除去する。
5. App内でDate()を直接使わずAppContainerのClockを使う。
6. Calendar Gridへ表示月のAccessibility Valueを付ける。
7. UI TestでGrid、空月文、無効日、左Swipe次月、右Swipe前月を確認する。
8. Test用Seed／MockをProduction Targetへ追加しない。

## Acceptance Criteria

- [x] App起動直後にCalendar Gridが表示される。
- [x] 空のV1 Containerで空月文が表示される。
- [x] 未移動日が無効である。
- [x] 左右Swipeで月が往復する。
- [x] 初期TemplateのList／Add／Edit UIが表示されない。
- [x] Build、Unit Test、UI Test、Lint、Formatが成功する。

## Deviations

有効移動日からDayDetailへの遷移は遷移先が未実装のためPhase 6のUI Testで追加する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Definition of Done

- [x] Acceptance Criteria、Allowed Changes、全検証を満たす。

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
### Manual Verification
### Deviations
### Unresolved Issues

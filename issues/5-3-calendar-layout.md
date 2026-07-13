# [UI] 月間Calendar Layoutを実装する

## Summary

端末のCalendar・Locale・週開始曜日に従う7列の月間Calendar Layoutと日付セルを実装する。

## Goal

iPhone Portraitで月の日付、今日、選択状態を欠けずに表示するCalendar画面の土台を作る。

## Non-Goals

- 距離表示、Swipe月移動、loading／empty／error表示、日別詳細View

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

- `issues/5-3-calendar-layout.md`
- `DriveLog/DriveLog/Features/Calendar/CalendarGridBuilder.swift`
- `DriveLog/DriveLog/Features/Calendar/CalendarView.swift`
- `DriveLog/DriveLogTests/Features/CalendarGridBuilderTests.swift`

### Forbidden Changes

- ViewModel／UseCase／Repository、App Entry、Project設定

## Requirements

1. Foundation Calendarを注入できるGrid Builderで月の日数と先頭空セルを生成する。
2. Calendar.firstWeekdayに合わせて曜日記号を回転する。
3. LocaleはCalendarに設定された端末相当値を使う。
4. 7列LazyVGridで曜日見出しと日付セルを表示する。
5. 今日を青い円、選択中をAccent Colorの塗りで表示し、選択を優先する。
6. 有効移動日だけButtonとして操作可能にし、無効日は遷移させない。
7. iPhone Portrait幅で各セルを均等配置し、最低44ptの操作領域を確保する。
8. Navigation TitleはLocaleに従う年月とする。
9. Date()を直接参照せず、View initializerでtodayを受け取る。
10. 初回表示は`.task`からViewModel.loadを呼ぶ。

## Acceptance Criteria

- [x] 月初の曜日、月の日数、Leap Yearが正しい。
- [x] 日曜始まりと月曜始まりで先頭位置と曜日順が正しい。
- [x] 今日、選択、通常日の見た目が区別される。
- [x] 無効日はButton操作されない。
- [x] Dynamic Typeと44pt操作領域を持つ。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

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

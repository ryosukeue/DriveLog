# [UI] 左右スワイプ月移動を実装する

## Summary

Calendar画面の左右Swipeだけで前月・次月へ移動できるようにする。

## Goal

iOS標準に沿った簡潔な月送り操作を提供する。

## Non-Goals

- 左右矢印Button、無限Page Cache、独自Bounce、日別詳細遷移

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/5-5-calendar-swipe.md`
- `DriveLog/DriveLog/Features/Calendar/CalendarSwipeInterpreter.swift`
- `DriveLog/DriveLog/Features/Calendar/CalendarView.swift`
- `DriveLog/DriveLogTests/Features/CalendarSwipeInterpreterTests.swift`

### Forbidden Changes

- ViewModel／UseCase／Repository、矢印Button、App Entry、Project設定

## Requirements

1. 左SwipeでshowNextMonthを呼ぶ。
2. 右SwipeでshowPreviousMonthを呼ぶ。
3. 水平移動量50pt以上かつ垂直移動量より大きい場合だけ月送りする。
4. 短いDragと縦Scroll相当のDragは無視する。
5. loading中は追加の月送りを開始しない。
6. GestureはCalendar領域へ付与し、矢印Buttonを追加しない。
7. 標準easeInOutの短いAnimationを月値変更へ適用する。
8. Accessibility actionとして「前の月」「次の月」を提供する。

## Acceptance Criteria

- [x] 左Swipeが次月、右Swipeが前月となる。
- [x] 短い／縦方向Dragを無視する。
- [x] 年境界はViewModelの既存処理で正しく移動する。
- [x] 矢印Buttonが存在しない。
- [x] VoiceOverから前月・次月操作を実行できる。
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

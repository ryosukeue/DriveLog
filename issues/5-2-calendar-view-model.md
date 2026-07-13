# [UI] CalendarViewModelを実装する

## Summary

月データ取得、月送り、表示状態、移動日選択と遷移先を管理するCalendarViewModelを実装する。

## Goal

Calendar ViewがUseCase呼出や遷移判定を持たず状態描画へ集中できるようにする。

## Non-Goals

- Calendar View／Layout、距離Format、NavigationStack、週開始曜日計算

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

- `issues/5-2-calendar-view-model.md`
- `DriveLog/DriveLog/Features/Calendar/CalendarViewModel.swift`
- `DriveLog/DriveLogTests/Features/CalendarViewModelTests.swift`

### Forbidden Changes

- View、UseCase／Repository、Domain計算、App Entry、Project設定

## Requirements

1. `@MainActor @Observable final class CalendarViewModel`とする。
2. LoadCalendarMonthUseCaseをinitializer injectionする。
3. 表示月、days、idle／loading／loaded／empty／errorを管理する。
4. 有効移動日が0件ならemptyとするがdaysは保持する。
5. Error時は既存daysを維持し、内部ErrorをUI状態へ公開しない。
6. 前月・次月を年境界込みで計算し、選択と遷移先を解除して再取得する。
7. `hasValidMovement == true`の日だけ選択し、localDateKeyを遷移先に設定する。
8. 無効日と存在しない日は選択・遷移しない。
9. 遷移完了後に遷移先を消費できる。
10. Request IDで古い非同期応答が新しい月を上書きしないようにする。

## Acceptance Criteria

- [x] load成功、空月、Errorと再試行状態が正しい。
- [x] 前月・次月と年境界が正しい。
- [x] 有効日だけ選択・遷移できる。
- [x] 月移動で選択状態が解除される。
- [x] 古い応答を無視できる。
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

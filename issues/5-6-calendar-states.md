# [UI] Calendar Empty・Error状態を実装する

## Summary

Calendar枠を維持したまま、読み込み中、移動記録なし、取得失敗と再試行を表示する。

## Goal

月データの状態と次に可能な操作をユーザーへ明確に伝える。

## Non-Goals

- Skeleton UI、内部Error code表示、Network向け文言、全画面Error

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/5-6-calendar-states.md`
- `DriveLog/DriveLog/Features/Calendar/CalendarView.swift`

### Forbidden Changes

- ViewModel／UseCase／Repository、App Entry、Project設定

## Requirements

1. loading時はCalendar領域中央へProgressViewを表示する。
2. 既存daysがある再読み込み中はCalendarを維持してProgressを重ねる。
3. empty時もCalendar日付を維持し「この月には移動記録がありません」を表示する。
4. error時もCalendar枠と既存daysを維持する。
5. Error説明は短い固定文言とし、内部codeを表示しない。
6. 「再試行」ButtonからViewModel.loadを呼ぶ。
7. Progress、Empty文、Error文、再試行へAccessibility Identifierを付ける。
8. Skeleton UIを追加しない。

## Acceptance Criteria

- [x] loadingでProgressViewが表示される。
- [x] emptyでCalendarと補助文が表示される。
- [x] errorでCalendar、説明、再試行が表示される。
- [x] 再試行でloadを実行できる。
- [x] 内部Error codeとSkeletonが存在しない。
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

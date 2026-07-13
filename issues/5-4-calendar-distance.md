# [UI] 日別距離表示を追加する

## Summary

Calendarの有効移動日に、日付と当日の総移動距離だけを表示する。

## Goal

月表示から各移動日の規模を一目で確認できるようにする。

## Non-Goals

- 速度、写真数、分類Icon、滞在数、日別詳細UI

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/5-4-calendar-distance.md`
- `DriveLog/DriveLog/Shared/Formatting/DistanceFormatter.swift`
- `DriveLog/DriveLog/Features/Calendar/CalendarView.swift`
- `DriveLog/DriveLogTests/Shared/Formatting/DistanceFormatterTests.swift`

### Forbidden Changes

- ViewModel／UseCase／Repository／Domain、App Entry、Project設定

## Requirements

1. UI専用DistanceFormatterでmeterをkilometerへ変換する。
2. 小数1桁、Locale準拠の数値に`km`を付ける。
3. NaN、Infinity、負数は表示文字列を返さない。
4. `hasValidMovement == true`かつdistanceが存在する日だけ距離を表示する。
5. 無効日、1km未満扱いの日は日付だけを表示する。
6. 距離は日付の下へCaption系Dynamic Typeで表示する。
7. VoiceOver Labelへ日付と移動距離を含める。
8. 写真枚数、分類、速度、滞在数を表示しない。

## Acceptance Criteria

- [x] 1000mを1.0km、18400mを18.4kmとして表示する。
- [x] Localeの小数記号へ従う。
- [x] 不正値は表示しない。
- [x] 有効移動日だけ距離を持つ。
- [x] Accessibility Labelに距離を含む。
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

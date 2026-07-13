# [UI] 再集計・空・エラー状態を実装する

## Summary

Day Detailへ初回Loading、再集計、空、Error、再試行の表示を追加する。

## Goal

取得状態を明確に伝え、既存データがある再集計や再読込失敗で閲覧を妨げないUIにする。

## Non-Goals

- 自動Polling、削除、Media Grid、Full Map

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 6-3、6-6

## Scope

### Allowed Changes

- `issues/6-7-day-detail-states.md`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`

### Forbidden Changes

- ViewModel、Domain、UseCase、Repository、SwiftData、Project設定、外部Package

## Requirements

1. データなしの初回読込中は中央Progressを表示する。
2. 既存データの再集計中は「再集計中…」バナーを地図直下へ表示する。
3. 再集計中も既存コンテンツを表示し操作不能にしない。
4. 空状態は「この日は移動記録がありません」と表示する。
5. 初回ErrorはError説明と再試行Buttonを表示する。
6. 既存データの再読込Errorはコンテンツを維持し、Inline Errorと再試行を表示する。
7. 各状態へAccessibility IdentifierとLabelを付ける。

## Acceptance Criteria

- [x] Loading、再集計、空、Error、再試行を表示できる。
- [x] 再集計と既存データErrorでコンテンツを維持する。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

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

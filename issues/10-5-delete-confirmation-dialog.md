# [UI] 削除確認Dialogを追加する

## Summary

日別詳細の削除Menu選択時に、削除対象、Photos資産が残ること、取消不能を明示する確認Dialogを表示する。

## Background

削除Menuは10-4で追加済みである。誤操作を防ぎ、Apple Photos内の資産を削除しない仕様を実行前に伝える必要がある。

## Goal

削除要求が必ずCancelまたはDestructiveな確定操作を持つ確認Dialogを経由するようにする。

## Non-Goals

- DeleteDayLogUseCaseの実行
- 削除中Progress、成功・失敗遷移、Haptic
- 文言の外部Localization

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 10-4 日別詳細Delete Menu

## Scope

### Allowed Changes

- `issues/10-5-delete-confirmation-dialog.md`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

### Forbidden Changes

- ViewModel、UseCase、Repository、AppContainer、SwiftData変更
- 削除実行、Navigation、Haptic変更
- Project設定、外部Package、Signing変更

## Requirements

1. Menu項目選択で確認Dialogを表示する。
2. タイトルは「この日の記録を削除しますか？」とする。
3. 位置情報、移動区間、滞在地点、分類修正が削除されると説明する。
4. 写真アプリ内の写真や動画は削除されないと説明する。
5. 操作は取り消せないと説明する。
6. 「キャンセル」はcancel roleとする。
7. 「削除」はdestructive roleとする。
8. キャンセル時はCallbackを呼ばない。
9. 削除確定時だけ`onRequestDeletion`を1回呼ぶ。

## Privacy Requirements

- 座標、経路、メディア識別子を表示・記録しない。
- Apple Photosの削除APIを呼ばない。

## UI Requirements

- SwiftUI `confirmationDialog`を使用する。
- 説明文はDialog messageとして表示する。

## Accessibility Requirements

- Cancel identifier: `dayDetail.delete.cancel`
- Confirm identifier: `dayDetail.delete.confirm`
- 標準DialogのVoiceOver順序とDynamic Typeを維持する。

## Interface Contract

```swift
onRequestDeletion: () -> Void
```

## Implementation Constraints

- View内の一時的なDialog表示状態だけを追加する。
- ViewからRepository、UseCaseを呼ばない。
- 未完成TODO、新規Warningを追加しない。

## Acceptance Criteria

- [x] 削除Menuから確認Dialogが表示される。
- [x] 必須の3説明事項が表示される。
- [x] Cancel/Destructive roleを持つ2操作が表示される。
- [x] キャンセルでDialogが閉じ、詳細を維持する。
- [x] 確定時だけCallbackを呼ぶ。
- [x] UI Testが成功する。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- MenuからDialogを開き、タイトル・説明・ボタンを確認する。
- キャンセル後も日別詳細が表示されることを確認する。

## Decision / Deviations

- 仕様の3行説明を1つのmessageへ改行区切りで表示する。
- iOS 26.5 Simulatorではcancel-roleが独立ButtonではなくPopover外側のdismiss操作として描画されたため、UI Testは外側タップでキャンセルを確認する。SwiftUI宣言にはcancel-role Buttonを保持する。
- 2026-07-14にiPhone 17 Simulatorで検証し、Unit Test 364件、UI Test 9件が成功した。
- LLDB version store等の既存Simulator環境Warning以外に新規Warningはない。

## Files Expected to Change

- Allowed Changes記載の3ファイルのみ。

## Completion Report Format

- Summary
- Changed files and reasons
- Tests added
- Build result
- Test result
- SwiftLint result
- SwiftFormat result
- Manual verification
- Deviations
- Unresolved issues

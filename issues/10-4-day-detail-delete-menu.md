# [UI] 日別詳細右上Delete Menuを追加する

## Summary

日別詳細画面の右上にMenuを配置し、Destructive roleの「この日の記録を削除」操作を提供する。

## Background

完全削除RepositoryとUseCaseは実装済みである。確認Dialogや削除実行を接続する前に、仕様で定められた削除導線を独立して追加する。

## Goal

日別詳細から削除要求を型安全なCallbackとして上位へ通知できるMenuを追加する。

## Non-Goals

- 削除確認Dialog
- DeleteDayLogUseCaseの実行
- 成功・失敗遷移、Progress、Haptic

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 10-3 DeleteDayLogUseCase

## Scope

### Allowed Changes

- `issues/10-4-day-detail-delete-menu.md`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

### Forbidden Changes

- ViewModel、UseCase、Repository、SwiftData Schema変更
- ContentView、AppContainer変更
- 確認Dialog、削除処理、画面遷移追加
- Project設定、外部Package、Signing変更

## Requirements

1. 日別詳細Navigation Bar右上にMenuを表示する。
2. Menu項目は「この日の記録を削除」とする。
3. Menu項目へ`destructive` roleを設定する。
4. 選択時に`onRequestDeletion` Callbackを1回呼ぶ。
5. CallbackはInitializer Injectionし、既定値はno-opとする。
6. Menuと項目へ安定したAccessibility Identifierを付ける。
7. 本Issueでは確認なしに削除を実行しない。

## Privacy Requirements

- ログ、座標、経路、メディア識別子を追加しない。
- 外部通信を追加しない。

## UI Requirements

- Navigation Bar右上に省スペースなMenuを配置する。
- Menu項目はDestructive表示とする。

## Accessibility Requirements

- Menu label: 「その他の操作」
- Menu identifier: `dayDetail.menu`
- Delete item identifier: `dayDetail.delete`
- SF Symbolだけに依存せずVoiceOver labelを提供する。

## Interface Contract

```swift
init(..., onRequestDeletion: @escaping () -> Void = { })
```

## Implementation Constraints

- SwiftUI標準MenuとToolbarを使用する。
- ViewからRepository、UseCaseを呼ばない。
- 新規Warning、未完成TODOを追加しない。

## Acceptance Criteria

- [x] Menuが日別詳細右上に表示される。
- [x] 削除項目の表示文言とDestructive roleが正しい。
- [x] UI TestでMenuと削除項目を確認する。
- [x] 選択しても確認なしの削除は発生しない。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- 日別詳細へ遷移しMenuを開く。
- 「この日の記録を削除」が存在することを確認する。

## Decision / Deviations

- 実削除接続は10-5/10-6で行うため、Callbackの既定値はno-opとする。
- 2026-07-14にiPhone 17 / iOS 26.5 Simulatorで検証し、Unit Test 364件、UI Test 9件が成功した。
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

# [UI] 削除成功・失敗遷移を実装する

## Summary

日別詳細の確認済み削除をDeleteDayLogUseCaseへ接続し、削除中、成功、失敗のPresentation状態とNavigationを完成させる。

## Background

完全削除UseCaseと確認Dialogまで実装済みである。MVPの削除導線を安全に完結させ、成功後のCalendar表示を永続化結果へ同期する必要がある。

## Goal

削除成功時にHaptic後Calendarへ戻って再取得し、失敗時は詳細を維持して再試行可能なAlertを表示する。

## Non-Goals

- Repository、Schema、削除対象の変更
- Apple Photos資産の操作
- Undo、Trash、復元機能

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 10-3 DeleteDayLogUseCase
- Issue 10-5 削除確認Dialog

## Scope

### Allowed Changes

- `issues/10-6-delete-transitions.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailViewModel.swift`
- `DriveLog/DriveLogTests/Features/DayDetailViewModelTests.swift`
- `DriveLog/DriveLogTests/Features/DayDetailDeletionViewModelTests.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

### Forbidden Changes

- DeleteDayLogUseCase、Repository、Schema、LogEvent変更
- Photos APIによる削除
- Project設定、外部Package、Signing変更

## Requirements

1. DayDetailViewModelからDeleteDayLogUseCaseを呼ぶ。
2. 削除中はProgressViewを表示し、Menuと重複実行を無効にする。
3. 成功時だけ軽い成功Hapticを1回実行する。
4. 成功時に日別詳細を閉じCalendarへ戻る。
5. Calendarを再取得し、削除日の距離・遷移可能状態を消す。
6. 失敗時は日別詳細と既存データを維持する。
7. 失敗時に短いAlertを表示する。
8. Alertを閉じた後、確認Dialogから再試行できる。
9. Photos資産を操作しない。

## Privacy Requirements

- 座標、経路、メディア識別子をログへ追加しない。
- Apple Photos資産を削除しない。
- 外部通信を追加しない。

## UI Requirements

- 削除中表示: `ProgressView`と「削除中…」
- 失敗Alert: 「削除できませんでした」「時間をおいて、もう一度お試しください」
- 失敗時のDismiss操作: 「OK」

## Accessibility Requirements

- Progress identifier: `dayDetail.deleting`
- Failure alert identifier: system alert titleを使用する。
- Dynamic Typeと標準VoiceOver順序を維持する。

## Interface Contract

```swift
func deleteDay() async -> Bool
func dismissDeletionError()
```

## Implementation Constraints

- Initializer Injectionを使用する。
- ViewModelからRepository、SwiftDataを直接呼ばない。
- 成功後NavigationはContentViewが担当する。
- 未完成TODO、新規Warningを追加しない。

## Acceptance Criteria

- [x] UseCase呼出、重複防止、状態遷移が正しい。
- [x] 成功時だけHapticとCalendar復帰が発生する。
- [x] Calendar再取得後に削除日の距離が消える。
- [x] 失敗時にAlertを表示し詳細を維持する。
- [x] Unit TestとUI Testが成功する。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- ViewModel成功、失敗、重複実行防止、Haptic条件。
- UIで削除確定後Calendarへ戻り、対象日が遷移不能になること。

## Decision / Deviations

- ViewModelの`deleteDay()`は成功Boolを返し、NavigationはContentViewのCallbackで行う。永続化責務とNavigation責務を分離する。
- SwiftLintの400行制限を守るため、削除状態Testは専用`DayDetailDeletionViewModelTests.swift`へ分離した。
- 2026-07-14にiPhone 17 / iOS 26.5 Simulatorで検証し、Unit Test 367件、UI Test 10件が成功した。
- AppIntents metadata extraction、LLDB version store等の既存環境Warning以外に新規Warningはない。

## Files Expected to Change

- Allowed Changes記載の8ファイルのみ。

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

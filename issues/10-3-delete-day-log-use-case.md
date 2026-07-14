# [Application] DeleteDayLogUseCaseを実装する

## Summary

指定日の完全削除をDayDeletionRepositoryへ1回だけ委譲し、成功・失敗を固定LogEventで通知するApplication UseCaseを実装する。

## Background

Data層の一括削除と完全性Testは完了した。Presentation層が個別RepositoryやPhotos APIへ触れず、安全な1操作として削除を実行するApplication境界が必要である。

## Goal

`DeleteDayLogUseCase.execute(localDateKey:)`で指定日の一括削除を実行し、成功または正規化した失敗を呼出元へ返す。

## Non-Goals

- 削除Menu、確認Dialog、成功・失敗画面遷移
- Calendar再取得、Haptic
- Repository、Schema、Photos資産変更

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 10-1 DayDeletionRepository
- Issue 10-2 完全削除Integration Test

## Scope

### Allowed Changes

- `issues/10-3-delete-day-log-use-case.md`
- `DriveLog/DriveLog/Application/Deletion/DeleteDayLogUseCase.swift`
- `DriveLog/DriveLogTests/Application/DeleteDayLogUseCaseTests.swift`

### Forbidden Changes

- Repository、SwiftData Schema、既存LogEvent変更
- PhotoLibraryProviding／PhotoKit利用
- UI、AppContainer、Haptic変更
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. `DeleteDayLogUseCase: Sendable`を設計Signatureで定義する。
2. DayDeletionRepositoryとLoggingをInitializer Injectionする。
3. 空のlocalDateKeyを`DriveLogError.invalidData`としてRepository呼出前に拒否する。
4. 有効入力ではRepositoryの`deleteDay`を1回だけ呼ぶ。
5. 成功時に`.dayDeletionCompleted(localDateKey:)`をinfoで1回記録する。
6. DriveLogErrorは同じ値を保持してthrowする。
7. 未知Errorは`.persistenceFailure(code: "delete_day")`へ正規化する。
8. 失敗時に`.dayDeletionFailed(localDateKey:code:)`をerrorで1回記録する。
9. 失敗時に成功Logを記録しない。
10. Photos APIを依存・呼出しない。

## Privacy Requirements

- localDateKeyと固定Error codeだけを既存構造化Loggerへ渡す。
- 座標、経路、メディア識別子を扱わない。
- 外部通信を追加しない。

## Interface Contract

```swift
protocol DeleteDayLogUseCase: Sendable {
    func execute(localDateKey: String) async throws
}
```

## Implementation Constraints

- Initializer Injectionを使用する
- SwiftUI、SwiftData、UIKit、PhotoKitをimportしない
- `fatalError()`、`try!`、`as!`、`print()`を追加しない
- 新規Warning、未完成TODOを残さない

## Acceptance Criteria

- [x] Repositoryを有効操作ごとに1回だけ呼ぶ
- [x] 成功Logが正しい
- [x] DriveLogError保持と未知Error正規化が正しい
- [x] 失敗Logだけが記録される
- [x] 空入力では削除しない
- [x] Photos APIを使用しない
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する
- [x] 新規Warningと仕様外変更がない

## Test Requirements

- 成功時の1回呼出とLog
- DriveLogError失敗時の保持とLog
- 未知Errorの正規化とLog
- 空入力の事前拒否

## Decision / Deviations

- UIから渡される日付は既存localDateKey生成経路で正規化済みのため、本UseCaseは空入力だけを防ぎ、Calendar解析責務を重複させない。
- 2026-07-14にiPhone 17 / iOS 26.5 Simulatorで全検証を実施した。Unit Test 364件、UI Test 8件が成功した。
- AppIntents metadata extractionのskip、LLDB version store、Simulator Accessibility重複classは既存の環境由来Warningであり、本Issueによる新規Warningではない。

## Files Expected to Change

- Allowed Changes記載のIssue、Application UseCase、Unit Testのみ。

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

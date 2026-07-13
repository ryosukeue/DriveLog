# [Application] ProcessDayUseCaseを実装する

## Summary

処理世代を固定してRaw Event、Override、メディア件数から日別派生データを生成し、状態更新まで完了するUseCaseを実装する。

## Goal

日付単位の処理フローをApplication層へ集約する。

## Non-Goals

- 同日二重実行防止、処理キュー、Media Cache永続化、UI

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/4-5-process-day-use-case.md`
- `DriveLog/DriveLog/Application/Processing/ProcessDayUseCase.swift`
- `DriveLog/DriveLog/Shared/Logging/Logging.swift`
- `DriveLog/DriveLog/Shared/Logging/LogEvent.swift`
- `DriveLog/DriveLog/Shared/Logging/OSLogLogger.swift`
- `DriveLog/DriveLogTests/Application/ProcessDayUseCaseTests.swift`

### Forbidden Changes

- Repository／Processing実装、Schema／Model、Platform、UI、Project設定

## Requirements

1. `ProcessDayUseCase: Sendable`を設計どおり定義する。
2. completedかつrawRevisionとprocessedRevisionが一致する日は保存済み結果を返す。
3. 処理開始時のrawRevisionを固定し、Raw、2種のOverride、メディア件数を取得する。
4. OverrideをRawDayEventsへ統合してDayProcessingへ渡す。
5. 生成結果を同じRevisionで一括置換した後にmarkCompletedする。
6. 処理中にRawが増えた場合はProcessingStateRepositoryの世代規則によりpendingへ残す。
7. 失敗とキャンセルはmarkFailedし、固定コードのLogEventを出力する。
8. MediaCacheRepository実装前のため、件数取得はSendable closureで注入し、既定値を0とする。
9. 二重実行防止はIssue 4-6で追加する。
10. Logging境界はApplicationの非MainActor処理から安全に利用できるよう`nonisolated`とする。

## Acceptance Criteria

- [x] 未処理日を正しい依存呼出順で処理できる。
- [x] 同世代の完了日は再処理しない。
- [x] Overrideとメディア件数がProcessorへ渡る。
- [x] 置換後に同じRevisionで完了する。
- [x] 処理失敗、保存失敗、キャンセルを失敗状態とログへ反映する。
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

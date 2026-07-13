# [Data] ProcessingStateRepositoryを実装する

## Summary

日付単位のRaw／Processed revisionとpending、processing、completed、failed状態をSwiftData上で一貫して管理する。

## Goal

新規Raw追加、処理開始、成功、失敗、処理中Raw更新を安全に表現し、未処理日を列挙できるRepositoryを実装する。

## Non-Goals

- 派生データ保存
- 日別Processing実行・二重実行防止
- UI、BGTask

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Phase 1 SwiftData V1 Schema、PersistenceActor、Mapper

## Scope

### Allowed Changes

- `issues/4-1-processing-state-repository.md`
- `DriveLog/DriveLog/Domain/Entities/DayProcessingRevision.swift`
- `DriveLog/DriveLog/Domain/Entities/DayProcessingStateData.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/ProcessingStatus.swift`
- `DriveLog/DriveLog/Data/Mappers/RawValueMapper.swift`
- `DriveLog/DriveLog/Data/Repositories/ProcessingStateRepository.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+ProcessingState.swift`
- `DriveLog/DriveLogTests/Data/ProcessingStateRepositoryIntegrationTests.swift`

### Forbidden Changes

- V1 Schema／Model、Raw／Derived Repository、Processing、Application、UI、Project設定、外部Package

## Requirements

1. `ProcessingStateRepository: Sendable`をinterfaces.mdどおり実装する。
2. 未作成日のstateはpending、raw 0、processed 0で作成して返す。
3. markDirtyはrawRevisionを1増やしpendingへする。
4. markProcessingは状態をprocessingへし、その時点のrevision snapshotを返す。
5. markCompletedは指定processedRevision、成功日時を保存し、rawが追いついていればcompleted、より新しければpendingへする。
6. markFailedはprocessedRevisionを変えずfailed、固定code、失敗日時を保存する。
7. pendingDateKeysはpending／failedかつrawRevision > processedRevisionの日を日付昇順で返す。
8. deleteStateは対象日だけを削除し、不存在時も成功する。
9. 全更新をPersistenceActor内で実行し、各操作を1回のsaveで確定する。
10. Data層の失敗を固定codeのDriveLogError.persistenceFailureへ変換する。
11. 状態Domain値と純粋Raw Value Mapperをnonisolatedにし、PersistenceActorから安全に使用する。

## Decisions

- state未作成時はRepositoryのClock.nowで初期行を作る。raw 0とprocessed 0は処理不要だが、状態遷移前の既定statusとしてpendingを保持する。
- pendingDateKeysはrawRevisionが進んでいるpending／failedだけを返し、処理中と処理不要な0/0初期行を除外する。
- markCompleted時点でrawRevisionがsnapshotを超えていれば成功世代だけ記録し、statusをpendingへ戻す。

## Acceptance Criteria

- [x] 初期stateと全状態遷移が正しい。
- [x] rawRevision／processedRevisionと処理中Raw更新が正しい。
- [x] pendingDateKeysが決定的である。
- [x] 日付単位削除と不存在削除が成功する。
- [x] In-memory SwiftData Integration Testが成功する。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Test Requirements

### Integration Tests

- [x] 初期state、markDirty、markProcessing、markCompleted、markFailed。
- [x] 処理中markDirty後のmarkCompletedがpendingを維持。
- [x] pendingDateKeysの状態・revision filterと順序。
- [x] deleteState、別日非干渉。

### UI Tests

- なし。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- Allowed Changes記載の8ファイル。

## Definition of Done

- [x] GoalとAcceptance Criteriaを満たす。
- [x] Allowed Changes内だけを変更する。
- [x] 全検証が成功する。

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
- Build:
- Unit Tests:
- Integration Tests:
- UI Tests:
- SwiftLint:
- SwiftFormat:
- Diff Check:
### Manual Verification
### Deviations
### Unresolved Issues

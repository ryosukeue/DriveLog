# [Data] LocationEvent保存Repositoryを実装する

## Summary

SwiftDataへLocationEventを保存し、近似重複を判定して日付別に取得できるRepository実装を追加する。

## Goal

LocationEventのinsert／更新とDayProcessingStateのrawRevision更新を同一PersistenceActor内で安全に実行する。

## Non-Goals

- MotionEvent、VisitEventの保存
- Raw Eventの完全削除
- Location Provider、位置品質判定、Processing Pipeline

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

## Dependencies

- Issue 1-6 SwiftData V1 Models
- Issue 1-8 Data Mappers
- Issue 1-9 PersistenceActor
- Issue 2-1 RawEventRepository Protocol

## Scope

### Allowed Changes

- `issues/2-2-location-event-repository.md`
- `DriveLog/DriveLog/Data/Repositories/SwiftDataRawEventRepository.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+LocationEvents.swift`
- `DriveLog/DriveLogTests/Data/LocationEventRepositoryIntegrationTests.swift`

### Forbidden Changes

- Domain Repository契約、SwiftData Model、Schema、Migration
- Motion／Visit／Override保存、Raw Event削除
- Provider、Processing、Application、UI
- Project設定、Signing、CloudKit、外部Package

## Requirements

1. `SwiftDataRawEventRepository`からLocationEventを`PersistenceActor`へ保存する。
2. 同一`localDateKey`で時刻差30秒以内かつ地表距離10m以内の既存点を近似重複とする。
3. `deduplicationKey`を保存するが、最終重複判定は時刻差と実距離で行う。
4. 重複時は水平精度、timestamp、createdAtの優先順で保持する点を決める。
5. 新規点を保持する場合は既存Modelを更新して`.updated`、既存点を保持する場合は`.duplicateIgnored`を返す。
6. insert／update時だけ該当日の`rawRevision`を1増やし、状態を`pending`にする。
7. 初回保存時は`processedRevision = 0`のDayProcessingStateを作成する。
8. 指定`localDateKey`のLocationEventをtimestamp昇順で取得する。
9. SwiftDataエラーは機密情報を含まない固定codeの`DriveLogError.persistenceFailure`へ変換する。
10. In-memory SwiftData Integration Testで境界、保持優先、revision、日付別取得を検証する。

## Acceptance Criteria

- [x] LocationEventをinsertして日付別に取得できる。
- [x] 30秒以内かつ10m以内だけが近似重複になる。
- [x] より良い点への更新と重複無視を区別できる。
- [x] duplicateIgnoredではrawRevisionが増えない。
- [x] insert／updateではrawRevisionが増える。
- [x] 他の日付のLocationEventを返さない。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規ソースWarningと仕様外変更がない。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Decisions

- 30秒bucketと緯度経度小数4桁相当から`deduplicationKey`を生成する。
- bucket／丸め境界で真の重複を見逃さないため、候補取得は同一日付の時刻窓で行い、key単独では除外しない。
- `SwiftDataRawEventRepository`の`RawEventRepository`完全準拠はMotion／Visit／削除実装後に行い、このIssueではLocation APIだけを公開する。

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
### Deviations
### Unresolved Issues

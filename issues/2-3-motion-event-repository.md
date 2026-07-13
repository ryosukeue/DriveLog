# [Data] MotionEvent保存Repositoryを実装する

## Summary

Core Motion由来の全Activity flagとconfidenceを保持したMotionEventをSwiftDataへ保存し、日付別に取得できるようにする。

## Goal

MotionEventのinsertと該当日のrawRevision更新を同一PersistenceActor内で安全に実行する。

## Non-Goals

- CoreMotion Providerと権限処理
- Motionの主分類への変換、重複除外、日次集計
- Location／Visitの保存規則変更、Raw Event削除

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

- Issue 1-6 SwiftData V1 Models
- Issue 1-9 PersistenceActor
- Issue 2-1 RawEventRepository Protocol
- Issue 2-2 SwiftDataRawEventRepository

## Scope

### Allowed Changes

- `issues/2-3-motion-event-repository.md`
- `DriveLog/DriveLog/Data/Repositories/SwiftDataRawEventRepository.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+LocationEvents.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+MotionEvents.swift`
- `DriveLog/DriveLogTests/Data/MotionEventRepositoryIntegrationTests.swift`

### Forbidden Changes

- Domain Repository契約、SwiftData Model、Schema、Migration
- Location重複判定、Visit保存、Raw Event削除
- Provider、Processing、Application、UI
- Project設定、Signing、CloudKit、外部Package

## Requirements

1. `SwiftDataRawEventRepository`からMotionEventを`PersistenceActor`へ保存する。
2. 保存時刻は注入した`Clock`から取得し、Productionでは`SystemClock`を使用する。
3. 6つのActivity flagを主分類へ変換せずそのまま保存する。
4. low／medium／high confidenceをV1 raw valueへ保存しDomain型へ復元する。
5. 複数flagが同時にtrue、全flagがfalse、endDateがnilでも保存する。
6. 保存成功ごとに該当日の`rawRevision`を1増やし、状態を`pending`にする。
7. 指定`localDateKey`のMotionEventをstartDate昇順で取得する。
8. SwiftDataエラーは機密情報を含まない固定codeの`DriveLogError.persistenceFailure`へ変換する。
9. In-memory SwiftData Integration Testで全field、confidence、revision、日付別取得を検証する。

## Acceptance Criteria

- [x] 全Motion flag、confidence、optional endDateを欠落なくround-tripできる。
- [x] 複数flag／全falseを保存できる。
- [x] 保存ごとにrawRevisionが増える。
- [x] 他の日付のMotionEventを返さない。
- [x] ClockでcreatedAtを注入できる。
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

- MotionEventには設計上の重複判定規則がないため、受信した各eventを`.inserted`として保存する。
- Domain DataにcreatedAtがないため、Repositoryへ`Clock`を注入し、永続化直前の時刻を記録する。
- rawRevision更新処理はIssue 2-2のPersistenceActor helperを同actor内で再利用する。

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

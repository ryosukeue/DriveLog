# [Data] DayDeletionRepositoryを実装する

## Summary

指定日のRaw、Derived、Override、Processing State、Media Cacheを、1つのPersistenceActor操作と1回の保存で完全削除するRepositoryを実装する。

## Background

各Repositoryには種類別の削除APIがあるが、順番に呼ぶと途中失敗時に部分削除となる。日付完全削除は全10 Modelを同じModelContextで削除し、Apple Photosには触れない専用境界が必要である。

## Goal

`DayDeletionRepository.deleteDay(localDateKey:)`から指定日の全V1 Modelを原子的に削除できるようにする。

## Non-Goals

- DeleteDayLogUseCase、確認Dialog、画面遷移
- Integration Testの全Model seedと他日維持確認
- Photos資産削除、論理削除、復元機能

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 1-4 V1 Schema
- Issue 1-5 PersistenceActor

## Scope

### Allowed Changes

- `issues/10-1-day-deletion-repository.md`
- `DriveLog/DriveLog/Data/Repositories/DayDeletionRepository.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+DayDeletion.swift`

### Forbidden Changes

- V1 Schema、Model、既存Repository Interface変更
- Photos API、UI、UseCase追加
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. `DayDeletionRepository: Sendable`を設計文書のSignatureで定義する。
2. `SwiftDataDayDeletionRepository`はInitializerでModelContainerを受け取る。
3. Location、Motion、Visit、Aggregate、Movement、Stayを対象日キーで削除する。
4. Classification Override、Stay Override、Processing State、Media Cacheを対象日キーで削除する。
5. 全FetchとDeleteを同じPersistenceActor／ModelContext操作内で行う。
6. 全Modelを削除予約した後、ModelContextを1回だけ保存する。
7. AggregateやRelationshipが存在しなくても孤立Dataを日付キーで削除する。
8. 指定日以外のDataを変更しない。
9. Apple PhotosおよびPhotoLibraryProvidingを参照しない。
10. 永続化失敗は`DriveLogError.persistenceFailure(code: "delete_day")`へ正規化する。

## Data Model Rules

- V1 Schemaの全10 Modelを`localDateKey`で個別検索する。
- Cascade Relationshipだけに依存しない。
- `isDeleted`、ゴミ箱、復元用Dataを追加しない。

## Interface Contract

```swift
protocol DayDeletionRepository: Sendable {
    func deleteDay(localDateKey: String) async throws
}
```

## Implementation Constraints

- ModelContextはPersistenceActor内だけで使用する
- 1回の保存前に全削除を登録する
- `fatalError()`、`try!`、`as!`、`print()`を追加しない
- 新規Warning、未完成TODOを残さない

## Acceptance Criteria

- [x] DayDeletionRepositoryの設計Signatureが実装される
- [x] V1全10 Modelを同一Actor操作で対象にする
- [x] localDateKeyによる明示検索で孤立Dataも対象にする
- [x] ModelContext保存は全削除登録後の1回だけである
- [x] Photos APIを参照しない
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する
- [x] 新規Warningと仕様外変更がない

## Test Requirements

- 全Model、他日維持、孤立Data、部分削除なしはIssue 10-2のIntegration Testで検証する。
- 本Issueでは既存全TestとBuildでRepositoryのTarget認識・型整合を検証する。

## Decision / Deviations

- SwiftDataの永続化saveをcommit境界とし、全Fetch／Delete完了後に1回だけ呼ぶ。
- SwiftDataの`#Predicate` macroはgeneric Model Protocolを展開できないため、V1各Modelの型付きPredicateを明示した。削除対象とsave境界は変更しない。
- 新規TestはIssue 10-2へ分離し、既存Unit Test 357件とUI Test 8件が成功した。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility message、既存Swift 6予告Warningは既存由来で、新規Source Warningはない。

## Files Expected to Change

- Allowed Changes記載のIssue文書とData Repository実装のみ。

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

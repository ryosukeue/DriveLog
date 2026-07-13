# [Data] PersistenceActorを実装する

## Summary

SwiftDataの`ModelContext`アクセスを直列化する共通`PersistenceActor`を追加する。

## Goal

Repository実装が共有できるModelActor境界と、In-memory Containerで隔離を検証できる土台を作る。

## Non-Goals

- RepositoryのCRUD実装
- Domain DataとModelの変換
- SchemaまたはModelの変更

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 1-6〜1-7 SwiftData V1 SchemaとContainer Factory

## Scope

### Allowed Changes

- `issues/1-9-persistence-actor.md`
- `DriveLog/DriveLog/Data/PersistenceActor/PersistenceActor.swift`
- `DriveLog/DriveLogTests/Data/PersistenceActorTests.swift`

### Forbidden Changes

- 既存Schema、Model、Mapper、Domain Data
- Repository、AppContainer、Project設定
- Signing、CloudKit、外部Package

## Requirements

1. `@ModelActor`を使用するActorとして実装する。
2. `ModelContainer`をInitializerから受け取る。
3. ModelContextをActor外へ返さない。
4. V1 Model型ごとの件数をActor内で取得できる最小APIを提供する。
5. 未保存変更がある場合だけ保存するAPIを提供する。
6. CRUDとTransaction APIは利用側RepositoryのIssueで追加する。
7. In-memory Containerで全V1 Modelへのアクセスと複数Taskからの呼出しを検証する。

## Acceptance Criteria

- [x] `PersistenceActor`がV1 Containerで生成できる。
- [x] 全10 Modelの件数取得が成功する。
- [x] 複数Taskからの呼出しがActor上で安全に完了する。
- [x] ModelContextが公開APIへ漏れない。
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

- 本Issueでは非`Sendable`なSwiftData ModelをActor境界で受け渡さず、`Sendable`な件数だけを返す。
- 保存・取得・置換など用途別操作は、各Repository Issueで`PersistenceActor`へ追加する。

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

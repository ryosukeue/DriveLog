# [Data] RawEventRepository Protocolを実装する

## Summary

生イベントの保存・日付取得・削除を表すRepository境界とTest用In-memory Fakeを追加する。

## Goal

Application／Platform層がSwiftData Modelを知らずにLocation、Motion、Visitを扱える契約を確定する。

## Non-Goals

- SwiftData Repository実装
- 近似重複判定、Visit同一候補判定、rawRevision更新
- ProcessingまたはProvider実装

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 1-1 Location／Motion／Visit Domain Data
- Issue 1-4 Override Domain Data

## Scope

### Allowed Changes

- `issues/2-1-raw-event-repository-protocol.md`
- `DriveLog/DriveLog/Domain/Repositories/RawEventRepository.swift`
- `DriveLog/DriveLog/Domain/Entities/RawDayEvents.swift`
- `DriveLog/DriveLogTests/TestSupport/InMemoryRawEventRepository.swift`
- `DriveLog/DriveLogTests/Domain/RawEventRepositoryTests.swift`

### Forbidden Changes

- SwiftData Model、Mapper、PersistenceActor
- Production Repository、Provider、Application、UI
- Project設定、Signing、CloudKit、外部Package

## Requirements

1. `RawEventRepository: Sendable`を`docs/interfaces.md`の5メソッドどおり定義する。
2. `RawEventSaveResult`は`inserted`、`updated`、`duplicateIgnored`を持ち`Sendable, Equatable`とする。
3. `RawDayEvents`はLocation、Motion、Visit、ClassificationOverride、StayOverride配列を保持する。
4. `RawDayEvents`は`Sendable, Equatable`とし、空値を明示的に生成できるようにする。
5. Test Target内にActor-isolatedな`InMemoryRawEventRepository`を実装する。
6. Fakeで保存、日付別取得、削除、全Save Result生成を検証する。
7. Production Fake、SwiftData、OS FrameworkをDomainへ追加しない。

## Acceptance Criteria

- [x] Protocol Signatureが設計文書と一致する。
- [x] Domain境界がSwiftData／OS Frameworkをimportしない。
- [x] In-memory Fakeが全Protocolメソッドを実行できる。
- [x] 日付別取得と削除が他の日へ影響しない。
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

- `component-specs.md`の旧名`ClassificationOverride`／`StayOverride`は、優先度の高い既存Domain実装に合わせ`Data`型を使用する。
- FakeはProductionの重複・更新規則を先取りせず、保存結果をInitializerで指定可能にする。

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

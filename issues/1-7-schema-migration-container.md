# [Data] Schema VersionとMigration Planを追加する

## Summary

10個のV1 Modelを登録したVersionedSchema、初期Migration Plan、ModelContainer生成Factoryを追加する。

## Goal

Designed V1 Schemaを明示したSwiftData ContainerをProduction／In-memory Test双方で起動できるようにする。

## Non-Goals

- V2 Migration、既存Model Field変更
- Repository、Mapper、PersistenceActor
- `DriveLogApp`の初期テンプレート置換

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 1-6 SwiftData V1 Models

## Scope

### Allowed Changes

- `issues/1-7-schema-migration-container.md`
- `DriveLog/DriveLog/Data/Schema/DriveLogSchemaV1.swift`
- `DriveLog/DriveLog/Data/Schema/DriveLogMigrationPlan.swift`
- `DriveLog/DriveLog/Data/Schema/DriveLogModelContainerFactory.swift`
- `DriveLog/DriveLogTests/Data/SchemaIntegrationTests.swift`

### Forbidden Changes

- V1 Model、Domain、Repository、Mapper、PersistenceActor
- `DriveLogApp.swift`、`ContentView.swift`、`Item.swift`
- Project設定、Signing、Capability、CloudKit、外部Package

## Requirements

1. `DriveLogSchemaV1`を`VersionedSchema`として定義しversionを1.0.0にする。
2. V1の10 Modelだけを登録する。
3. `DriveLogMigrationPlan`を追加しV1だけをschemasへ登録、stagesは空にする。
4. FactoryはSchemaとMigration Planを使用してModelContainerを生成する。
5. Productionは永続Store、Testはin-memoryを選択可能にする。
6. CloudKit設定を追加しない。
7. Container生成失敗を`throws`で呼出側へ返し、強制終了しない。
8. In-memory Containerで全10 Modelを保存・再取得するIntegration Testを追加する。

## Acceptance Criteria

- [ ] V1 versionが1.0.0で10 Modelだけを含む。
- [ ] Migration PlanとProduction／In-memory Container生成が成功する。
- [ ] 全10 Modelの保存・取得Integration Testが成功する。
- [ ] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [ ] CloudKit、新規Warning、TODO、仕様外変更がない。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- Allowed Changes記載の5ファイル

## Migration Requirements

- Schema version: 1.0.0
- Migration stages: なし
- 生ログを破棄しない。

## Decisions

- App Entry Pointの置換はPhase 12まで行わず、FactoryのProduction生成とIn-memory Integration TestでSchema起動を保証する。
- FactoryはStore URLを独自固定せずSwiftData標準Store配置を使用する。

## Definition of Done

- [ ] Goal、Requirements、Acceptance Criteriaを満たす。
- [ ] Allowed Changes内だけを変更する。
- [ ] 全検証が成功する。

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
- Manual Test:
### Deviations
### Unresolved Issues

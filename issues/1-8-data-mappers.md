# [Data] Data Mapperを実装する

## Summary

SwiftData V1 ModelとOS非依存Domain Dataを相互変換するMapperを追加する。

## Goal

RepositoryがSwiftData ModelをDomain境界へ漏らさず、保存形式のRaw ValueとDomain Enumを安全に変換できるようにする。

## Non-Goals

- Repository、PersistenceActor、ビジネス判定
- Route EncodingのProduction実装
- Model／Domain Field変更

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 1-1〜1-5 Domain Data
- Issue 1-6〜1-7 V1 ModelとSchema

## Scope

### Allowed Changes

- `issues/1-8-data-mappers.md`
- `DriveLog/DriveLog/Shared/Formatting/RouteEncoding.swift`
- `DriveLog/DriveLog/Data/Mappers/*.swift`
- `DriveLog/DriveLogTests/Data/DataMapperTests.swift`

### Forbidden Changes

- 既存Domain／Model／Schema
- Repository、PersistenceActor、RouteEncoding実装
- Project設定、Signing、CloudKit、外部Package

## Requirements

1. 全10 ModelについてModel→Domainまたは対応するDomain→Model変換を提供する。
2. 永続Raw ValueをMapper境界だけで扱う。
3. 未知のEnum Raw Valueは設計通り安全な既定値へFallbackする。
4. Model固有FieldはDomain→Model引数として明示する。
5. Movement routeはInitializer Injectionした`RouteEncoding`で変換する。
6. Route変換失敗を隠さず`throws`で返す。
7. Mapperに判定、補正、Repository I/Oを含めない。
8. Media Cache固有Fieldは明示引数で保存し、Reference変換時はUI不要Fieldを漏らさない。

## Acceptance Criteria

- [x] 全10 Modelの変換Testが成功する。
- [x] Enum全Caseと未知値Fallbackが確認される。
- [x] RouteEncodingの注入・失敗伝播が確認される。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warning、TODO、仕様外変更がない。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Decisions

- Issue 1-10より先にMovement Mapperが必要なため、`RouteEncoding` Protocolだけを本Issueで追加する。Production Codecは追加しない。
- 未知値Fallbackはprocessing→pending、automatic→other、各confidence→low、user classification→other、stay source→locationGap、media type→photo、eligibility→ineligibleとする。

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

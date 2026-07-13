# [Data] DerivedDataRepositoryの取得を実装する

## Summary

SwiftDataから日別Aggregate、Movement、Stayと月範囲AggregateをDomain Dataへ復元して決定的な順序で返す。

## Goal

UIとApplicationがSwiftData Modelへ触れずに派生データを取得できるRepositoryのRead側を実装する。

## Non-Goals

- 派生データ一括置換・削除（Issue 4-3）
- Processing状態更新、Override、UI

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/4-2-derived-data-retrieval.md`
- `DriveLog/DriveLog/Data/Repositories/DerivedDataRepository.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+DerivedData.swift`
- `DriveLog/DriveLog/Domain/Entities/DayAggregateData.swift`
- `DriveLog/DriveLog/Domain/Entities/MovementSegmentData.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/LocalMonth.swift`
- `DriveLog/DriveLog/Shared/Formatting/RouteEncoding.swift`
- `DriveLog/DriveLog/Shared/Formatting/PropertyListRouteEncoder.swift`
- `DriveLog/DriveLog/Data/Mappers/DerivedDataModelMapper.swift`
- `DriveLog/DriveLogTests/Data/DerivedDataRepositoryIntegrationTests.swift`

### Forbidden Changes

- SwiftData Schema／Model、Raw／State／Override Repository、Processing、Application、UI、Project設定

## Requirements

1. interfaces.mdどおりのDerivedDataRepository Protocolを定義する。
2. Aggregateは日付一致の0件をnil、1件をDomain Dataで返す。
3. 月取得は`YYYY-MM-01`以上、翌月1日未満だけを日付昇順で返す。
4. Movementは日付一致をstartDate昇順、StayはarrivalDate昇順で返す。
5. routeをV1 PropertyList形式から復元し、decode失敗をpersistenceFailureへ変換する。
6. 不正な月はDriveLogError.invalidDataとする。
7. 純粋Domain値、Mapper、Route encoderをnonisolated化し、PersistenceActorから安全に使う。
8. Write側はIssue 4-3で実装し、このIssueではConcrete型のProtocol準拠を完了扱いにしない。

## Decisions

- SwiftのProtocol準拠は全メソッド実装が必要なため、このIssueで完全なProtocolを定義しConcrete型へReadメソッドを追加する。Issue 4-3でWriteメソッドと正式準拠を追加する。
- `LocalMonth`は1〜12だけを有効とし、翌年境界を文字列範囲へ正規化する。

## Acceptance Criteria

- [x] 日付別3種と月別Aggregate取得が正しい。
- [x] 0件、別日除外、順序、年跨ぎが正しい。
- [x] routeと全Domain fieldを復元する。
- [x] decode／月不正を安全に返す。
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

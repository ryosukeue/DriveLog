# [Data] DerivedData一括置換を実装する

## Summary

日付単位の既存Aggregate、Movement、Stayを、世代整合性を検証した新しい処理結果へ1回のSwiftData saveで置換する。

## Goal

途中失敗をUIへ見せず、旧派生データを維持できるDerivedDataRepositoryのWrite側を完成する。

## Non-Goals

- ProcessingState更新、Override削除、Raw削除、UI

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

- `issues/4-3-derived-data-replacement.md`
- `DriveLog/DriveLog/Data/Repositories/DerivedDataRepository.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+DerivedData.swift`
- `DriveLog/DriveLogTests/Data/DerivedDataReplacementIntegrationTests.swift`

### Forbidden Changes

- Schema／Model、State／Raw／Override Repository、Processing、Application、UI、Project設定

## Requirements

1. SwiftDataDerivedDataRepositoryをDerivedDataRepositoryへ正式準拠させる。
2. localDateKeyと全sourceRawRevisionが引数processedRevisionへ一致することを検証する。
3. 全route encodeと新規Model生成を既存削除より先に完了する。
4. 対象日の既存3種だけを削除し、新規3種をinsertして1回saveする。
5. encode／save失敗時はrollbackし、旧データを維持する。
6. deleteDerivedDataは対象日の3種だけを1回saveで削除し、不存在時も成功する。
7. Override、Raw Event、Processing Stateへ触れない。

## Acceptance Criteria

- [x] 3種を保存・取得できる。
- [x] 再置換で旧データとorphanが残らない。
- [x] encode失敗時に旧データを維持する。
- [x] revision／日付不一致を拒否する。
- [x] 対象日削除と別日非干渉が正しい。
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

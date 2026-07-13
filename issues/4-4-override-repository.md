# [Data] OverrideRepositoryを実装する

## Summary

分類修正と滞在修正を日付単位で取得し、同じoverrideKeyを重複させず保存できるRepositoryを実装する。

## Goal

ユーザー修正を再処理後も維持できる永続化境界を完成する。

## Non-Goals

- Overrideの近似再紐づけ、UseCase、UI、日付完全削除全体

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

- `issues/4-4-override-repository.md`
- `DriveLog/DriveLog/Data/Repositories/OverrideRepository.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+Overrides.swift`
- `DriveLog/DriveLog/Data/Mappers/OverrideMediaModelMapper.swift`
- `DriveLog/DriveLogTests/Data/OverrideRepositoryIntegrationTests.swift`

### Forbidden Changes

- Schema／Model、Derived／Raw／Processing Repository、Processing、Application、UI、Project設定

## Requirements

1. `OverrideRepository: Sendable`を設計どおり実装する。
2. ClassificationOverrideとStayOverrideを日付単位で取得する。
3. 同じoverrideKeyのUpsertは既存Modelを更新し、重複を作らない。
4. 新規Upsertは既存Mapperを使ってModelを追加する。
5. overrideKeyが`localDateKey|targetStableID`と一致しない入力を拒否する。
6. `deleteOverrides`は対象日の2種だけを1回のsaveで削除し、不存在時も成功する。
7. 派生データ置換や再処理でOverrideを削除しない。
8. SwiftDataアクセスはPersistenceActor内で行い、失敗時はrollbackする。
9. 状態を持たない既存MapperはPersistenceActorから安全に利用できるよう`nonisolated`とする。

## Acceptance Criteria

- [x] 2種の保存と日付取得ができる。
- [x] 同じoverrideKeyの更新で1件だけが残り、IDとcreatedAtを維持する。
- [x] 異なる日付とOverride種別が干渉しない。
- [x] 不正なoverrideKeyを拒否する。
- [x] 対象日削除と不存在時削除が成功する。
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

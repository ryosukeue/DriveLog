# [Data] MediaCacheRepositoryを実装する

## Summary

V1 `MediaAssetCacheModel`へPhotoKit参照Metadataを日付別に保存・取得・置換・削除するRepositoryを実装する。

## Goal

Media本体を保存せず、localIdentifier一意性とActor isolationを維持した参照Cacheを提供する。

## Non-Goals

- Eligibility判定、PhotoKitアクセス、Thumbnail保存、Media配置、UI

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

- Issue 1-6、1-8、1-9、8-2

## Scope

### Allowed Changes

- `issues/8-3-media-cache-repository.md`
- `DriveLog/DriveLog/Data/Repositories/MediaCacheRepository.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+MediaCache.swift`
- `DriveLog/DriveLogTests/Data/MediaCacheRepositoryIntegrationTests.swift`

### Forbidden Changes

- V1 Schema／Model／Mapper、PhotoKit Provider、Domain、UI、Project設定、外部Package

## Requirements

1. interfaces.mdの5 APIを持つ`MediaCacheRepository: Sendable`を実装する。
2. SwiftData操作は既存`PersistenceActor`へ隔離する。
3. `cachedAssets`はcreationDate、localIdentifier順で返す。
4. upsertは同一localIdentifierを更新し重複を作らない。
5. replaceは対象日の欠落IDを削除し、入力を同一transactionでupsertする。
6. 同一IDが別日へ移った場合も一意性を保ちlocalDateKeyを更新する。
7. removeは指定IDだけ、deleteCacheは指定日だけを冪等に削除する。
8. 位置なし、動画、Screenshot／Screen Recording metadataを保持する。
9. Media本体、Thumbnail、Previewを保存しない。
10. 失敗は固定codeの`DriveLogError.persistenceFailure`へ変換する。

## Decisions

- RepositoryはEligibilityを判定しない。後続Refresh UseCaseから渡される表示対象を`eligibilityRawValue = eligible`として保存する。
- 入力内の同一localIdentifierは末尾値を採用し、SwiftData unique constraintへ到達する前に正規化する。

## Acceptance Criteria

- [x] 日付別取得、upsert、replace、remove、deleteが成功する。
- [x] localIdentifierが一意で、別日データを誤削除しない。
- [x] 位置なし／動画Metadataをround-tripできる。
- [x] Integration Testと全既存Testが成功する。
- [x] Build、Lint、Format、Diff Checkが成功する。
- [x] Schema変更、新規Warning、仕様外変更がない。

## Deviations

- なし。Build時のAppIntents metadata skipとSimulator runtimeのWarningは既存環境由来。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
### Manual Verification
### Deviations
### Unresolved Issues

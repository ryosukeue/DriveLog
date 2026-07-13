# [Data] Visit保存・更新Repositoryを実装する

## Summary

到着だけ判明したVisitをSwiftDataへ保存し、同一Visitの出発確定イベントを既存recordへ更新できるようにする。

## Goal

Visitの近似同一判定、insert／update、rawRevision更新をPersistenceActor内で実行し、Production RawEventRepository契約を完成させる。

## Non-Goals

- CLVisit Providerと権限処理
- Stay判定、Visitからの派生データ生成
- 日付に関連する派生データを含む完全削除UseCase

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 1-6 SwiftData V1 Models
- Issue 1-9 PersistenceActor
- Issue 2-1 RawEventRepository Protocol
- Issue 2-2／2-3 Location／Motion Repository実装

## Scope

### Allowed Changes

- `issues/2-4-visit-event-repository.md`
- `DriveLog/DriveLog/Data/Repositories/SwiftDataRawEventRepository.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+LocationEvents.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+VisitEvents.swift`
- `DriveLog/DriveLogTests/Data/VisitEventRepositoryIntegrationTests.swift`

### Forbidden Changes

- Domain Repository契約、SwiftData Model、Schema、Migration
- Location／Motion保存規則
- Provider、Processing、Application、UI
- 完全削除、Project設定、Signing、CloudKit、外部Package

## Requirements

1. arrivalDateだけを持ちdepartureDateがnilのVisitを保存できる。
2. 同一`localDateKey`でarrivalDate差60秒以内かつ座標距離が精度半径以内のVisitを同一候補とする。
3. `visitMatchKey`を保存するが、最終判定はarrivalDate差と実距離で行う。
4. 同一Visitへ新しいdepartureDateが届いた場合は既存Modelを更新して`.updated`を返す。
5. 同一Visitに実質的な更新がない場合は`.duplicateIgnored`を返す。
6. insert／update時だけrawRevisionを増やし、duplicateIgnoredでは増やさない。
7. createdAt／updatedAtは注入したClockの時刻を使用し、更新でcreatedAtを変更しない。
8. 指定日のLocation／Motion／Visitを`RawDayEvents`として取得する。
9. `SwiftDataRawEventRepository`を`RawEventRepository`へ準拠させる。
10. `deleteRawEvents`は指定日の3種のRaw Eventだけを削除し、他の日付へ影響させない。
11. SwiftDataエラーは固定codeの`DriveLogError.persistenceFailure`へ変換する。
12. In-memory Integration Testで到着保存、出発更新、近似非一致、revision、日付取得／削除を検証する。

## Acceptance Criteria

- [x] arrival-only Visitを保存できる。
- [x] 同一Visitのdepartureを新規insertせず更新できる。
- [x] arrival時刻または座標条件を外れるVisitは別recordになる。
- [x] insert／updateだけrawRevisionが増える。
- [x] RawEventRepositoryの全methodをProduction実装が満たす。
- [x] 日付取得とRaw Event削除が他の日へ影響しない。
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

- 設計文書に数値閾値がないため、公開API／Schemaを変えない内部値としてarrival差60秒を採用する。
- 座標閾値は`max(10m, existing.horizontalAccuracy, incoming.horizontalAccuracy)`とし、CLVisitの精度を同一判定へ反映する。
- `visitMatchKey`はarrivalの1時間bucketと緯度経度小数4桁相当から生成するが、bucket境界を考慮してkey単独では候補を除外しない。
- Phase 2の最後のRaw Event保存Issueとして、Protocol必須の日付取得とRaw Event単体削除も完成させる。関連派生データの完全削除は後続Issueで扱う。

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

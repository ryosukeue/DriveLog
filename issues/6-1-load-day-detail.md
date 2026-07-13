# [Application] LoadDayDetailUseCase基礎を実装する

## Summary

日付キーから日別集計、移動区間、滞在、Override、再集計状態を取得し、Day Detail用の表示データへ統合する。

## Goal

UIやSwiftData Modelへ依存しない`LoadDayDetailUseCase`契約と表示データを実装する。

## Non-Goals

- MapSceneの実構築ロジック（Issue 6-2）
- Media Cache取得（Phase 8）
- UI実装

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 4-2、4-4、4-5

## Scope

### Allowed Changes

- `issues/6-1-load-day-detail.md`
- `DriveLog/DriveLog/Application/DayDetail/LoadDayDetailUseCase.swift`
- `DriveLog/DriveLog/Domain/Entities/DayDetailData.swift`
- `DriveLog/DriveLog/Domain/Entities/MapScene.swift`
- `DriveLog/DriveLogTests/Application/LoadDayDetailUseCaseTests.swift`

### Forbidden Changes

- SwiftData Schema、Repository実装、既存Processing、UI、Project設定、外部Package

## Requirements

1. `LoadDayDetailUseCase`を`Sendable`で定義する。
2. Aggregate、Movement、Stay、Override、Processing Stateを日付単位で取得する。
3. Movementはユーザー分類を保持し、StayはOverride後の表示状態を返す。
4. `rawRevision > processedRevision`または処理中なら`isReprocessing`をtrueにする。
5. `MapSceneBuilding`へ日別データを渡し、生成結果を返す。
6. Phase 8まではMediaを空配列で返す。
7. Aggregateが存在しない場合は`DriveLogError.invalidData`を返す。
8. Apple UI／MapKit／SwiftDataをimportしない。

## Interface Contract

```swift
protocol LoadDayDetailUseCase: Sendable {
    func execute(localDateKey: String) async throws -> DayDetailData
}
```

## Decisions

- `MapScene`はMapKitに依存しない表示値としてこのIssueで契約だけ定義し、実Builderは6-2で追加する。
- Media Cache RepositoryはPhase 8の対象なので、このIssueでは空配列を返す。
- 同一区間へ複数Overrideが一致した場合は`updatedAt`、同値なら`overrideKey`が後の値を採用する。

## Acceptance Criteria

- [x] 表示用データとUseCase契約が設計文書に一致する。
- [x] Overrideと再集計状態が反映される。
- [x] 空Media、欠損Aggregate、取得失敗をテストする。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

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

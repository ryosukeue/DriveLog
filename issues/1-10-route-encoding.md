# [Shared] RouteEncodingを実装する

## Summary

表示用経路座標をVersion付きbinary Property Listへ変換するProduction実装を追加する。

## Goal

MovementSegmentの経路をV1永続形式で安全に保存・復元できるようにする。

## Non-Goals

- 経路簡略化、座標補正、距離計算
- SwiftData ModelまたはMapperの変更
- V2 PayloadまたはMigration

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 1-1 `RouteCoordinate`
- Issue 1-8 `RouteEncoding` Protocol

## Scope

### Allowed Changes

- `issues/1-10-route-encoding.md`
- `DriveLog/DriveLog/Shared/Formatting/PropertyListRouteEncoder.swift`
- `DriveLog/DriveLogTests/Shared/Formatting/RouteEncodingTests.swift`

### Forbidden Changes

- `RouteEncoding` Protocol、Domain型、Mapper、SwiftData Model
- Processing、Repository、Project設定
- Signing、CloudKit、外部Package

## Requirements

1. `PropertyListRouteEncoder`として`RouteEncoding`へ準拠する。
2. `PropertyListEncoder`のbinary形式を使用する。
3. Payloadは`formatVersion`と緯度経度の座標列を持つ。
4. V1の`formatVersion`を`1`とする。
5. 空座標列を含め入力順とDouble値を保持する。
6. 破損Data、異なるVersion、decode不能Payloadは`DriveLogError.invalidData`を返す。
7. Payload実装型を外部APIへ公開しない。

## Acceptance Criteria

- [x] V1のencode／decode Round-tripが成功する。
- [x] 出力がbinary Property Listである。
- [x] 空配列をRound-tripできる。
- [x] 破損Dataと未知Versionが`invalidData`になる。
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

- Production型名は永続形式を明示する`PropertyListRouteEncoder`とする。
- Payload内部型は将来Version追加時に並存できるようprivateなV1型とする。

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

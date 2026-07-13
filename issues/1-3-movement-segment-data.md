# [Domain] MovementSegment Data型を追加する

## Summary

自動分類、分類信頼度、ユーザー分類と表示用経路を含む移動区間のDomain Dataを追加する。

## Goal

Processing、Repository、UseCase、PresentationがSwiftDataやMapKitに依存せず移動区間を受け渡せるようにする。

## Non-Goals

- 区間生成、移動分類、Route Encoding、stableID生成
- SwiftData Model、Mapper、Override保存
- MapKit表示

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

- Issue 1-1 `RouteCoordinate`
- Issue 1-2 `AutomaticMovementType`

## Scope

### Allowed Changes

- `issues/1-3-movement-segment-data.md`
- `DriveLog/DriveLog/Domain/ValueObjects/ClassificationConfidence.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/UserMovementClassification.swift`
- `DriveLog/DriveLog/Domain/Entities/MovementSegmentData.swift`
- `DriveLog/DriveLogTests/Domain/MovementSegmentDataTests.swift`

### Forbidden Changes

- 既存Domain型
- SwiftData、Mapper、Repository、Processing、Feature
- Project設定、Signing、外部Package

## Requirements

1. 全型を`Sendable, Equatable`へ準拠させる。
2. `ClassificationConfidence`はlow、medium、highを持つ。
3. `UserMovementClassification`はautomotive、train、bus、walking、otherを持つ。
4. `MovementSegmentData`はV1 MovementSegmentのID以外のFieldを型付きで表現する。
5. 永続化用`encodedRouteData`ではなく`[RouteCoordinate]`を保持する。
6. label位置は`RouteCoordinate?`として保持する。
7. 自動分類とユーザー分類を混在させず、Segmentには自動分類だけを保持する。
8. 値型内で分類、経路変換、入力補正を行わない。
9. DomainではFoundation以外をimportしない。

## Interface Contract

```swift
enum ClassificationConfidence: Sendable, Equatable
enum UserMovementClassification: Sendable, Equatable
struct MovementSegmentData: Sendable, Equatable
```

## Acceptance Criteria

- [ ] 3つの型が追加され全Case・Fieldを表現できる。
- [ ] 経路とLabelにOS非依存座標型を使用する。
- [ ] Domain層に禁止Framework importがない。
- [ ] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [ ] 新規Warning、TODO、仕様外変更がない。

## Test Requirements

- [ ] 全Enum Caseの生成と等価性
- [ ] MovementSegmentDataの全Field、Optional速度・Label、複数座標
- [ ] 関連値差分の非等価性
- [ ] Sendable準拠のCompile確認

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- Allowed Changes記載の4ファイル

## Files That Must Not Change

- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- 既存Domain／Shared／Applicationファイル

## Privacy Requirements

- 座標をログ出力・外部送信しない。

## Decisions

- `AutomaticMovementType`はIssue 1-2で`DayAggregateData`の型安全性に必要だったため実装済み。本Issueでは変更せず再利用する。
- ユーザー指定の「車」は自動分類のautomotive-likeと区別するため`automotive`と命名する。

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

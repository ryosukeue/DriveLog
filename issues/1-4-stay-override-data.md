# [Domain] StaySegmentとOverride Data型を追加する

## Summary

滞在区間と、移動分類・滞在表示に対するユーザーOverrideをOS・SwiftData非依存のDomain Dataとして追加する。

## Goal

自動判定データとユーザー修正を分離したままRepository、Processing、UseCase間で受け渡せるようにする。

## Non-Goals

- 滞在判定、Override Matching、stableID／overrideKey生成
- SwiftData Model、Mapper、Repository、UI

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
- Issue 1-3 `UserMovementClassification`

## Scope

### Allowed Changes

- `issues/1-4-stay-override-data.md`
- `DriveLog/DriveLog/Domain/ValueObjects/StayConfidence.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/StayDetectionSource.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/StayOverrideAction.swift`
- `DriveLog/DriveLog/Domain/Entities/StaySegmentData.swift`
- `DriveLog/DriveLog/Domain/Entities/ClassificationOverrideData.swift`
- `DriveLog/DriveLog/Domain/Entities/StayOverrideData.swift`
- `DriveLog/DriveLogTests/Domain/StayOverrideDataTests.swift`

### Forbidden Changes

- 既存Domain型
- SwiftData、Mapper、Repository、Processing、Feature
- Project設定、Signing、外部Package

## Requirements

1. 全型を`Sendable, Equatable`へ準拠させる。
2. `StayConfidence`はlow、medium、highを持つ。
3. `StayDetectionSource`はvisit、locationGap、motionTransition、combinedを持つ。
4. `StayOverrideAction`はconfirm、hide、automaticを持つ。
5. `StaySegmentData`はV1 StaySegmentのID以外を型付きで保持し、代表位置に`RouteCoordinate`を使う。
6. `ClassificationOverrideData`はV1 ClassificationOverrideのID以外を保持する。
7. `StayOverrideData`はV1 StayOverrideのID以外を保持し、元位置に`RouteCoordinate`を使う。
8. 自動判定FieldをOverrideによって直接書き換えるAPIを追加しない。
9. 値型内で判定・Key生成・補正を行わない。
10. DomainではFoundation以外をimportしない。

## Acceptance Criteria

- [ ] 6つのDomain型が追加される。
- [ ] V1 Fieldと全Actionを表現できる。
- [ ] 自動判定とOverrideが別型である。
- [ ] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [ ] 禁止Framework、新規Warning、TODO、仕様外変更がない。

## Test Requirements

- [ ] 全Enum Caseの生成・等価性
- [ ] StaySegment、分類Override、滞在Overrideの全Field保持
- [ ] 異なる値の非等価性
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

- Allowed Changes記載の8ファイル

## Files That Must Not Change

- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- 既存Domain／Shared／Applicationファイル

## Privacy Requirements

- 座標をログ出力・外部送信しない。

## Decisions

- `StayDetectionSource`のCaseは設計文書で一意でない。判定規則に現れる独立証拠を`visit`、`locationGap`、`motionTransition`、複数証拠を`combined`として保守的に表現する。
- `StayConfidence`はClassification Confidenceと同じ3段階だが責務を混在させない別型とする。

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

# [Domain] 共通位置・時刻Valueを追加する

## Summary

位置、モーション、VisitのPlatform入力と処理で共有する、Apple Framework非依存のDomain Data型を追加する。

## Background

Phase 2以降のPlatform Provider、RawEventRepository、Processingは、CoreLocationやCoreMotionの型を境界外へ漏らさずイベントを受け渡す必要がある。

## Goal

位置座標と3種類のRaw Eventを、Foundation以外のFrameworkへ依存しない不変の値型として表現する。

## Non-Goals

- 座標検証、重複判定、距離計算
- SwiftData Model、Mapper、Repository
- CoreLocation／CoreMotion／CLVisitからの変換

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

- Issue 0-6 `RecordedTimeContext`

## Scope

### Allowed Changes

- `issues/1-1-common-location-time-values.md`
- `DriveLog/DriveLog/Domain/ValueObjects/RouteCoordinate.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/MotionConfidence.swift`
- `DriveLog/DriveLog/Domain/Entities/LocationEventData.swift`
- `DriveLog/DriveLog/Domain/Entities/MotionEventData.swift`
- `DriveLog/DriveLog/Domain/Entities/VisitEventData.swift`
- `DriveLog/DriveLogTests/Domain/CommonLocationTimeValuesTests.swift`

### Forbidden Changes

- SwiftData Model、Repository、Mapper
- Platform実装
- 既存Foundation型とAppContainer
- Xcode初期テンプレート
- Project設定、Signing、外部Package

## Requirements

1. 全型を`Sendable, Equatable`準拠にする。
2. Domain層ではFoundation以外をimportしない。
3. `RouteCoordinate`は緯度と経度を`Double`で保持する。
4. `LocationEventData`は座標、timestamp、horizontalAccuracy、任意のspeed、createdAt、記録時TimeZone情報を保持する。
5. `MotionEventData`はstartDate、任意のendDate、6つの元Activity flag、confidence、記録時TimeZone情報を保持する。
6. `MotionConfidence`は`low`、`medium`、`high`を表現する。
7. `VisitEventData`は座標、任意のarrival/departure、horizontalAccuracy、記録時TimeZone情報を保持する。
8. 複数のMotion flagが同時にtrueである状態を許容する。
9. このIssueでは入力値の検証・補正・正規化を行わない。
10. CoreLocation、CoreMotion、SwiftData、SwiftUI、UIKitをimportしない。

## Input

- OS境界で取得後にPrimitiveへ変換された位置・モーション・時刻情報

## Output

- Apple Framework非依存のDomain Data値

## State Changes

- なし

## Error Handling

- このIssueの値型は失敗する生成処理を持たない。
- 不正値の拒否は後続の受信検証・Processing Issueで行う。

## Privacy Requirements

- 値型は座標を保持するが、ログ出力機能を持たない。
- 外部送信を追加しない。

## UI Requirements

- なし

## Accessibility Requirements

- なし

## Processing Rules

- このIssueでは判定・計算を実装しない。

## Data Model Rules

- Motionは単一分類へ変換せず6つの元フラグを保持する。
- speedの負値補正は永続化境界で行い、この値型では行わない。

## Interface Contract

```swift
struct RouteCoordinate: Sendable, Equatable
enum MotionConfidence: Sendable, Equatable
struct LocationEventData: Sendable, Equatable
struct MotionEventData: Sendable, Equatable
struct VisitEventData: Sendable, Equatable
```

## Implementation Constraints

- 不変の値型とする。
- Apple Framework型、SwiftData Annotation、UI責務を含めない。
- `fatalError()`、`try!`、`as!`、Force Unwrap、`print()`を使用しない。
- Raw Valueや`CaseIterable`等の不要な準拠を追加しない。

## Acceptance Criteria

- [ ] 5つのDomain型が実装される。
- [ ] 全型が`Sendable, Equatable`へ準拠する。
- [ ] Motionの複数FlagとOptional時刻を表現できる。
- [ ] Domain層に禁止Framework importがない。
- [ ] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [ ] 新規Warning、未完成TODO、仕様外変更がない。

## Test Requirements

### Unit Tests

- [ ] 各型の全Propertyを保持できる。
- [ ] 同じ値が等価、異なる値が非等価になる。
- [ ] Motionの複数Flagが同時にtrueでも保持される。
- [ ] Optionalのspeed、endDate、arrivalDate、departureDateがnilを保持できる。
- [ ] 全型のSendable準拠をCompile時に確認する。

### Integration Tests

- なし

### UI Tests

- 既存UI Testが成功すること。

### Manual Tests

- Domainファイルのimportを確認する。

## Test Fixtures

- 架空座標と固定日時のみを使用する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- `issues/1-1-common-location-time-values.md`
- `DriveLog/DriveLog/Domain/ValueObjects/RouteCoordinate.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/MotionConfidence.swift`
- `DriveLog/DriveLog/Domain/Entities/LocationEventData.swift`
- `DriveLog/DriveLog/Domain/Entities/MotionEventData.swift`
- `DriveLog/DriveLog/Domain/Entities/VisitEventData.swift`
- `DriveLog/DriveLogTests/Domain/CommonLocationTimeValuesTests.swift`

## Files That Must Not Change

- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Item.swift`

## Migration Requirements

- なし

## Performance Constraints

- 値生成時に計算やI/Oを行わない。

## Cancellation Behavior

- なし

## Logging Requirements

- なし

## Decisions

- `component-specs.md`の単一`activityType`例より、`interfaces.md`の「元フラグを保持」と`data-model.md`の6 Boolを優先し、`MotionEventData`も6つのFlagを保持する。
- `MotionConfidence`はOSのRaw ValueをDomain公開APIへ漏らさず、`low`、`medium`、`high`のCaseだけを持つ。
- Domain DataはPlatform受信値として使用するため永続Modelの`id`、deduplicationKey、created/updated metadataは先取りしない。ただしLocationの`createdAt`はcomponent contractに明記されているため保持する。

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

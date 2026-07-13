# [Domain] 日別集計Data型を追加する

## Summary

日別処理状態、日別集計、月指定、カレンダー日表示をApple Frameworkと永続化方式に依存しないDomain値として追加する。

## Goal

Repository、Processing、Calendar Feature間で日別状態と集計を型安全に受け渡せるようにする。

## Non-Goals

- SwiftData Model、Mapper、Repository
- 日次集計計算、月間カレンダー生成
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

- Issue 1-1 Domain共通Value

## Scope

### Allowed Changes

- `issues/1-2-day-summary-data.md`
- `DriveLog/DriveLog/Domain/ValueObjects/LocalMonth.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/ProcessingStatus.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/AutomaticMovementType.swift`
- `DriveLog/DriveLog/Domain/Entities/DayProcessingStateData.swift`
- `DriveLog/DriveLog/Domain/Entities/DayAggregateData.swift`
- `DriveLog/DriveLog/Domain/Entities/CalendarDayData.swift`
- `DriveLog/DriveLogTests/Domain/DaySummaryDataTests.swift`

### Forbidden Changes

- SwiftData、Repository、Mapper、Processing実装
- Feature、View、ViewModel
- 既存Domain型、Foundation型、AppContainer
- Project設定、Signing、外部Package

## Requirements

1. 全型を`Sendable, Equatable`へ準拠させる。
2. `ProcessingStatus`はpending、processing、completed、failedを持つ。
3. `AutomaticMovementType`はautomotiveLike、walkingLike、otherを持つ。
4. `DayProcessingStateData`はV1処理状態ModelのID以外の全Fieldを型付きで保持する。
5. `DayAggregateData`はV1日別集計ModelのID以外の全Fieldを型付きで保持する。
6. `LocalMonth`はyearと1から12のmonthを保持する単純な値型とする。
7. `CalendarDayData`はlocalDateKey、日番号、任意の移動距離、有効移動有無を保持する。
8. 値型内で集計、日付生成、入力補正を行わない。
9. Foundation以外のFrameworkをDomainへimportしない。
10. Raw Value、CaseIterable、LocalizedError等の不要な準拠を追加しない。

## Interface Contract

```swift
enum ProcessingStatus: Sendable, Equatable
enum AutomaticMovementType: Sendable, Equatable
struct DayProcessingStateData: Sendable, Equatable
struct DayAggregateData: Sendable, Equatable
struct LocalMonth: Sendable, Equatable
struct CalendarDayData: Sendable, Equatable
```

## Acceptance Criteria

- [ ] 6つのDomain型が追加される。
- [ ] V1日別状態・集計のFieldが欠落しない。
- [ ] Calendar表示に必要な日付・距離・有効性を表現できる。
- [ ] Domain層に禁止Framework importがない。
- [ ] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [ ] 新規Warning、TODO、仕様外変更がない。

## Test Requirements

### Unit Tests

- [ ] 全Caseを生成でき、等価性が成立する。
- [ ] DayProcessingStateDataのOptional状態を保持できる。
- [ ] DayAggregateDataの全Fieldを保持し、差分が非等価になる。
- [ ] LocalMonthとCalendarDayDataが値とOptional距離を保持する。
- [ ] 全型のSendable準拠をCompile時に確認する。

### Integration Tests

- なし

### UI Tests

- 既存UI Testが成功すること。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- Allowed Changes記載のIssue、Domain 6ファイル、Test 1ファイル

## Files That Must Not Change

- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- Xcode初期テンプレート
- 既存Domain／Sharedファイル

## Migration Requirements

- なし

## Privacy Requirements

- 座標、経路、メディア識別子を追加しない。
- ログや外部通信を追加しない。

## Decisions

- `DayAggregateData`を永続形式の文字列ではなく型付きにするため、Issue 1-3対象一覧の`AutomaticMovementType`だけを依存型として先に追加する。Issue 1-3ではこの既存型をMovementSegmentへ適用する。
- `LocalMonth`はRepository入力値であり、このIssueでは失敗可能initializerやCalendar依存の検証を追加しない。
- `CalendarDayData.totalDistanceMeters`は未移動日を表現するためOptionalとし、`hasValidMovement`をタップ可否の明示値として保持する。

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

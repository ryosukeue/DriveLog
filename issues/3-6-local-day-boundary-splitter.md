# [Processing] 現地日付境界分割を実装する

## Summary

全生イベントとOverrideを、記録時に保存された`localDateKey`ごとの独立した入力へ分割する。

## Goal

現在の端末タイムゾーンへ依存せず、異なる現地日付のイベントを同一区間へ結合しない純粋なSplitterを実装する。

## Non-Goals

- 日付キーの再計算
- 日付境界上の補間点生成
- Movement／Stay区間の生成

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

- Issue 1-1 Domain Entity
- Issue 0-7 LocalTimeContext

## Scope

### Allowed Changes

- `issues/3-6-local-day-boundary-splitter.md`
- `DriveLog/DriveLog/Processing/DayBoundary/LocalDayBoundarySplitter.swift`
- `DriveLog/DriveLogTests/Processing/LocalDayBoundarySplitterTests.swift`
- `DriveLog/DriveLog/Domain/Entities/RawDayEvents.swift`
- `DriveLog/DriveLog/Domain/Entities/MotionEventData.swift`
- `DriveLog/DriveLog/Domain/Entities/VisitEventData.swift`
- `DriveLog/DriveLog/Domain/Entities/ClassificationOverrideData.swift`
- `DriveLog/DriveLog/Domain/Entities/StayOverrideData.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/UserMovementClassification.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/RouteCoordinate.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/StayOverrideAction.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/MotionConfidence.swift`

### Forbidden Changes

- 保存値、Repository、SwiftData Schema、Clock／TimeZone Provider、UI
- Project設定、外部Package

## Requirements

1. `docs/interfaces.md`の`LocalDayBoundarySplitting`を実装する。
2. Location、Motion、Visit、ClassificationOverride、StayOverrideを各自の保存済み`localDateKey`で分ける。
3. 現在のCalendar、TimeZone、UTC日付からキーを再計算しない。
4. 同じキー内では各入力配列の順序を維持する。
5. キー間でイベントを複製しない。
6. 空入力は空Dictionaryを返す。
7. 純粋Processingから利用するDomain入力型とその値型を明示的`nonisolated`とし、値・保存形式は変えない。

## Input / Output

- 入力: 複数の現地日付を含み得る`RawDayEvents`。
- 出力: `[localDateKey: RawDayEvents]`。

## State Changes / Error Handling

- 状態変更なし。未知の形式を検証・補正せず、保存済みキーをそのまま使用する。

## Privacy / UI / Accessibility Requirements

- ログ・外部通信なし。UI変更なし。

## Acceptance Criteria

- [x] 全5イベント種を保存済みキーだけで分割する。
- [x] UTC上の同日／別日にかかわらず保存済みキーを優先する。
- [x] 入力順序を保ち、イベントを複製・欠落させない。
- [x] 空、単日、複数日を処理できる。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Decisions

- Protocolの出力に順序付き日付配列はないため、Dictionaryの列挙順序は契約に含めず、各日・各イベント種の入力順序だけを保証する。
- VisitやMotionが日付をまたいでも、このIssueでは分割・複製せず、記録済み`localDateKey`側へ所属させる。区間境界処理は後続コンポーネントが担う。

## Test Requirements

### Unit Tests

- [x] 空、単日、複数日。
- [x] 全5イベント種と入力順序。
- [x] UTC日付と保存済みlocalDateKeyの不一致。
- [x] Visit／Motionの日付またぎを複製しない。

### Integration / UI Tests

- なし。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- `issues/3-6-local-day-boundary-splitter.md`
- `DriveLog/DriveLog/Processing/DayBoundary/LocalDayBoundarySplitter.swift`
- `DriveLog/DriveLogTests/Processing/LocalDayBoundarySplitterTests.swift`
- 上記5つの純粋Domain入力型と、直接保持する4つの値型。

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
### Manual Verification
### Deviations
### Unresolved Issues

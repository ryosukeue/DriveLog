# [Processing] MovementSegmenterを実装する

## Summary

Sanitize済み位置点を、長時間Gap、現地日付、Visit、停止証拠を伴う移動モード変化で移動候補へ分割する。

## Goal

後続のStay判定・移動分類が利用できる、距離付きの有効候補、Gap候補、無効候補を純粋処理で生成する。

## Non-Goals

- Stay確定と渋滞・信号判定
- 自動移動分類
- 表示用平均速度・経路簡略化

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

- Issue 3-1 ProcessingConfiguration
- Issue 3-2〜3-6 Location処理と日付境界分割

## Scope

### Allowed Changes

- `issues/3-7-movement-segmenter.md`
- `DriveLog/DriveLog/Processing/Segmentation/MovementSegmenter.swift`
- `DriveLog/DriveLog/Processing/Geometry/GeodesicDistanceCalculator.swift`
- `DriveLog/DriveLog/Processing/Location/LocationSanitizer.swift`
- `DriveLog/DriveLogTests/Processing/MovementSegmenterTests.swift`

### Forbidden Changes

- Domain保存型、Repository、SwiftData Schema、Platform、UI
- Project設定、外部Package

## Requirements

1. `MovementSegmenting`を設計どおり実装する。
2. 位置点間が90分以上、または保存済み`localDateKey`が異なれば分割する。
3. 位置点間にCLVisitが存在すれば分割する。
4. automotive↔walking変化は、位置点の空白が3分以上ある場合だけ分割する。
5. cycling、running、unknownや停止証拠のない短いMotion変化だけでは分割しない。
6. 候補は2点以上かつ100m以上を有効とする。
7. Motion境界だけで生じた短区間は連結可能な近い側へ統合する。
8. 日付、90分Gap、Visit境界を越えて短区間を統合しない。
9. 無効候補を`discardedSegments`、境界を`GapCandidate`として保持する。
10. 区間距離は隣接点間のHaversine地表距離合計とする。
11. 地表距離計算を共通純粋型へ抽出し、LocationSanitizerと共有する。
12. 入力と生ログを変更しない。

## Interface Decisions

- `MovementSegmentationResult`: `segments`、`gaps`、`discardedSegments`。
- `MovementSegmentCandidate`: localDateKey、開始・終了、位置点、距離。
- `GapCandidate`: 境界前後の位置点と`SegmentationBoundaryReason`。
- 境界理由: continuousGap、localDayBoundary、visit、motionTransition。

## Acceptance Criteria

- [x] 90分未満は連結し、90分ちょうど以上は分割する。
- [x] 現地日付境界とVisitで分割する。
- [x] 停止証拠を伴うautomotive↔walkingだけをMotion境界とする。
- [x] 100m／2点境界を適用し、短区間を安全に統合または破棄する。
- [x] 距離、開始・終了、Gap理由が決定的である。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Decisions

- 「位置点の空白または停止」の未定義境界には既存の`minimumStayDuration` 3分を使用し、Motion変化単独での過分割を避ける。
- Motion由来の境界だけを短区間の連結可能境界とし、両側候補がある場合は時間差が小さい側、同値なら前側へ統合する。
- Visitは到着・出発区間が位置点間と重なる場合に境界とし、未確定Visitは存在する端点を使用する。
- 後続分類に距離が必要なため候補へ地表距離を保持する。表示用平均速度ルールはIssue 3-11へ残す。

## Test Requirements

### Unit Tests

- [x] 通常、90分未満／ちょうど／超。
- [x] 日付境界、Visit、複数Visit。
- [x] automotive→walking、walking→automotive、証拠なし、対象外Motion。
- [x] 100m未満／ちょうど、1点／2点。
- [x] 統合可能／不可の短区間、空入力。

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

- Issue文書、MovementSegmenter、共通距離計算、LocationSanitizer、Unit Test。

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

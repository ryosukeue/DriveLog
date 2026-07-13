# [Processing] 渋滞・信号除外を実装する

## Summary

5分以上のGapでも、車両移動が同方向に継続し、automotive→stationary→automotive以外の証拠がない場合だけ自動非表示にする。

## Goal

信号待ち・渋滞を立ち寄りとして誤表示することを抑え、不確実な候補とユーザー確定は維持する。

## Non-Goals

- 道路Map Matching
- 自動移動分類そのもの
- Override近似再紐づけ

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 3-1 ProcessingConfiguration
- Issue 3-7 MovementSegmenter
- Issue 3-8 StayDetector

## Scope

### Allowed Changes

- `issues/3-9-traffic-signal-filter.md`
- `DriveLog/DriveLog/Processing/Configuration/ProcessingConfiguration.swift`
- `DriveLog/DriveLog/Processing/Stay/StayDetector.swift`
- `DriveLog/DriveLogTests/Processing/ProcessingConfigurationTests.swift`
- `DriveLog/DriveLogTests/Processing/StayTrafficFilteringTests.swift`

### Forbidden Changes

- Domain保存型、Repository、SwiftData Schema、Platform、UI、Project設定、外部Package

## Requirements

1. automotive→stationary→automotiveの順序を確認する。
2. 該当時間帯にwalking／runningがあれば除外しない。
3. CLVisitがあれば除外しない。
4. Gap前後に各2点以上の移動候補がなければ除外しない。
5. 前後進行方向の最小角度差が設定値以下の場合だけ同方向とする。
6. MVPの方向差設定値は45度とし`ProcessingConfiguration`へ集約する。
7. 条件が1つでも不足すれば滞在候補を維持する。
8. confirm Overrideは交通候補より優先して表示する。

## Acceptance Criteria

- [x] 全条件が揃う交通候補を自動非表示にする。
- [x] walking、Visit、方向転換、情報不足では表示候補を維持する。
- [x] 45度境界を含める。
- [x] confirm Overrideを優先する。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Decisions

- 「方向が大きく変わらない」の数値が未定義なため、保守的なMVP値として45度を採用し、将来変更可能な`StayRules`へ置く。
- 進行方向は前区間の末尾2点と後区間の先頭2点の初期方位角で比較する。点不足や方位算出情報不足は滞在を残す側へ倒す。
- traffic判定は自動可視性へだけ適用し、その後に完全一致Overrideを適用する。
- 方位角の球面・浮動小数点誤差で45度ちょうどを誤判定しないよう、比較時のみ`1e-6`度を許容する。

## Test Requirements

### Unit Tests

- [x] automotive→stationary→automotive、walkingあり、Visitあり。
- [x] 同方向、45度、45度超、点不足。
- [x] confirm Override。

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

- Allowed Changes記載の5ファイル。

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

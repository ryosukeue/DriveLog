# [Processing] ProcessingConfigurationを追加する

## Summary

DriveLog MVPの位置整形、区間分割、滞在、分類、日別判定、Override、Media、Routeに使う閾値を、交換可能な純粋値型へ集約する。

## Goal

`docs/processing-rules.md`のMVP初期値を`ProcessingConfiguration`1箇所から供給できるようにする。

## Non-Goals

- 位置点の除外・区間分割・分類ロジック
- 設定画面や永続化
- 設計文書にない調整項目

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

- Phase 1 Domain Value型

## Scope

### Allowed Changes

- `issues/3-1-processing-configuration.md`
- `DriveLog/DriveLog/Processing/Configuration/ProcessingConfiguration.swift`
- `DriveLog/DriveLogTests/Processing/ProcessingConfigurationTests.swift`

### Forbidden Changes

- Domain、Data、Platform、Application、UIの既存実装
- SwiftData Schema、Project設定、外部Package

## Requirements

1. `ProcessingConfiguration`を`Sendable, Equatable`の値型として実装する。
2. location、segmentation、stay、classification、dayValidation、overrideMatching、media、routeの8責務へ規則を分ける。
3. 各Rulesも`Sendable, Equatable`の値型とする。
4. `docs/processing-rules.md`の全MVP閾値をSI単位で保持する。
5. 初期値は`ProcessingConfiguration.mvp`だけで構築する。
6. 時間は秒、距離はm、速度はm/s、比率は`0...1`として保持する。
7. 現在時刻、OS Framework、UI、永続化へ依存しない。
8. 各Rulesのmemberwise initializerによりTestや将来の処理へ別Configurationを注入可能にする。

## Acceptance Criteria

- [x] 8分類のRulesと全MVP閾値が定義される。
- [x] `ProcessingConfiguration.mvp`が設計値と一致する。
- [x] 値型としてSendableかつEquatableである。
- [x] Apple Platform Frameworkと保存層へ依存しない。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decisions

- `futureTimestampTolerance = 24時間`、`minimumValidLocationPointCount = 2`、Motion confidence重み、分類信頼度比率は初期値一覧表外だが、判定章に明示された数値のため集約対象とする。
- km/h表記の速度は`1000 / 3600`でm/sへ変換し、後続の距離計算と単位を合わせる。
- 対象は純粋処理値のため`nonisolated`型とし、TargetのMainActorデフォルトから分離する。

## Test Requirements

### Unit Tests

- [x] 全8 RulesのMVP初期値を検証する。
- [x] 同一Configurationの等価性と異なるRulesの非等価性を検証する。
- [x] `Sendable`制約をcompile-time helperで検証する。

### Integration Tests

- なし。

### UI Tests

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

- `issues/3-1-processing-configuration.md`
- `DriveLog/DriveLog/Processing/Configuration/ProcessingConfiguration.swift`
- `DriveLog/DriveLogTests/Processing/ProcessingConfigurationTests.swift`

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

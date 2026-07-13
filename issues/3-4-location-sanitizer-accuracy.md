# [Processing] 水平精度除外を実装する

## Summary

`LocationSanitizer`で設定値を超える水平精度の位置点を派生処理から除外し、理由を保持する。

## Goal

SLCの特性を考慮したMVP上限500mを境界込みで適用し、生ログを変更せず低精度点を除外する。

## Non-Goals

- 座標ジャンプ除外
- 水平精度による滞在・移動分類
- 保存済み生ログの削除

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
- Issue 3-2／3-3 LocationSanitizer

## Scope

### Allowed Changes

- `issues/3-4-location-sanitizer-accuracy.md`
- `DriveLog/DriveLog/Processing/Location/LocationSanitizer.swift`
- `DriveLog/DriveLogTests/Processing/LocationSanitizerTests.swift`

### Forbidden Changes

- Domain、Repository、SwiftData Schema、Provider、UI
- Project設定、外部Package

## Requirements

1. 重複除外後に水平精度上限を適用する。
2. `horizontalAccuracy <= maximumHorizontalAccuracy`を受理する。
3. 上限を超える点を`.poorAccuracy`で除外する。
4. 閾値は`LocationRules`から取得する。
5. 生ログと入力配列を変更・削除しない。
6. 低精度だけで滞在や分類を決定しない。

## Input / Output

- 入力: 無効値・重複を除外済みの位置点。
- 出力: 水平精度が閾値内のacceptedと、`.poorAccuracy`理由付きrejected。

## State Changes / Error Handling

- 永続状態変更なし。空配列と全件除外は正常結果とする。

## Privacy / UI / Accessibility Requirements

- 座標をログへ出力しない。UI変更なし。

## Acceptance Criteria

- [x] 水平精度500mを受理する。
- [x] 500m超を`.poorAccuracy`で除外する。
- [x] 注入した別閾値を適用できる。
- [x] 生ログを変更しない。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Decisions

- 設計された全体処理順に従い、重複点の最良候補を選んだ後で水平精度上限を適用する。

## Test Requirements

### Unit Tests

- [x] 500m、500m超、注入閾値。
- [x] rejected reason。

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

- `issues/3-4-location-sanitizer-accuracy.md`
- `DriveLog/DriveLog/Processing/Location/LocationSanitizer.swift`
- `DriveLog/DriveLogTests/Processing/LocationSanitizerTests.swift`

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

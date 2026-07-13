# [Processing] 座標ジャンプ除外を実装する

## Summary

隣接位置点の推定速度とA-B-C関係を使い、物理的に不自然な座標ジャンプだけを決定的に除外する。

## Goal

250km/h以下の高速移動を保持しつつ、異常点を`.implausibleJump`理由付きで後続処理から除外する。

## Non-Goals

- 移動分類
- 区間生成や距離集計
- 生ログの変更・削除

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
- Issue 3-2〜3-4 LocationSanitizer

## Scope

### Allowed Changes

- `issues/3-5-location-sanitizer-jumps.md`
- `DriveLog/DriveLog/Processing/Location/LocationSanitizer.swift`
- `DriveLog/DriveLogTests/Processing/LocationSanitizerTests.swift`
- `DriveLog/DriveLogTests/Processing/LocationSanitizerJumpTests.swift`

### Forbidden Changes

- Domain、Repository、SwiftData Schema、Provider、UI
- Project設定、外部Package

## Requirements

1. 地表距離を正の時刻差で割った推定速度を使う。
2. `maximumPlausibleSpeed`以下を速度だけで除外しない。
3. 閾値超過の隣接点を座標ジャンプ候補とする。
4. A-B-CでA-Cが自然なら中間Bを除外する。
5. 前後関係で一意に決まらなければ水平精度が悪い側を除外する。
6. 精度が同じ場合は後側を除外する。
7. 同時刻の異なる座標は速度を算出できないため`.invalidSequence`で除外する。
8. 除外後の新しい隣接関係も再評価する。
9. 閾値は`LocationRules`から取得し、生ログを変更しない。

## Input / Output

- 入力: 無効、重複、低精度点を除外済みの時系列位置点。
- 出力: 妥当なacceptedと、理由付きrejected。

## State Changes / Error Handling

- 永続状態変更なし。0件・1件は正常結果とする。

## Privacy / UI / Accessibility Requirements

- 座標・速度をログへ出力しない。UI変更なし。

## Acceptance Criteria

- [x] 250km/h未満とちょうどを保持し、超過を判定する。
- [x] A-B-CでBのみ異常ならBを除外する。
- [x] A-B-CでCが異常ならCを除外する。
- [x] 判定不能時に精度が悪い側、同精度なら後側を除外する。
- [x] 前後点不足と不正時系列をクラッシュせず扱う。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Decisions

- 設計に「精度差が小さい」の数値閾値がないため、独自閾値を増やさず、精度が異なれば悪い側、等しければ後側を除外する。
- 構造上のA-C自然判定を精度比較より優先し、その後に隣接関係を先頭から再評価する。
- 時刻差0以下で異なる座標は推定速度を無限大として候補化し、`.invalidSequence`へ分類する。

## Test Requirements

### Unit Tests

- [x] 250km/h未満、ちょうど、超過、高速鉄道相当。
- [x] A-B-CのB異常、C異常。
- [x] 前後不足、精度差あり、同精度。
- [x] 同時刻の異なる座標、注入閾値。

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

- `issues/3-5-location-sanitizer-jumps.md`
- `DriveLog/DriveLog/Processing/Location/LocationSanitizer.swift`
- `DriveLog/DriveLogTests/Processing/LocationSanitizerTests.swift`
- `DriveLog/DriveLogTests/Processing/LocationSanitizerJumpTests.swift`

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

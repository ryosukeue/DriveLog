# [Processing] 重複位置点除外を実装する

## Summary

時刻差30秒以内かつ地表距離10m以内の位置点を重複と判定し、設計された優先順位で最良の1点だけを後続処理へ渡す。

## Goal

`LocationSanitizer`へ決定的な重複除外を追加し、除外点を`duplicate`理由付きで返す。

## Non-Goals

- 水平精度500m超の除外
- 不自然な座標ジャンプ除外
- Repository保存時の重複判定変更

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
- Issue 3-2 LocationSanitizer

## Scope

### Allowed Changes

- `issues/3-3-location-sanitizer-duplicates.md`
- `DriveLog/DriveLog/Processing/Location/LocationSanitizer.swift`
- `DriveLog/DriveLogTests/Processing/LocationSanitizerTests.swift`

### Forbidden Changes

- Domain、Repository、SwiftData Schema、Provider、UI
- Project設定、外部Package

## Requirements

1. 時刻差が30秒以内かつ実際の地表距離が10m以内の点だけを重複とする。
2. 30秒、10mの境界値を含める。
3. 重複候補では水平精度が良い点、timestampが新しい点、createdAtが早い点の順で1点を残す。
4. 優先度が完全に同じ場合は先に整列された点を残す。
5. 除外点は元の値と`.duplicate`理由を返す。
6. 距離はApple Frameworkへ依存しない地表距離計算で判定する。
7. 入力配列と生ログを変更しない。
8. 閾値は`LocationRules`から取得し、直書きしない。

## Input

- Issue 3-2で有効性を確認し決定的に整列された`LocationEventData`配列。

## Output

- 重複を除いたacceptedと、duplicate理由を持つrejected。

## State Changes

- なし。

## Error Handling

- 空配列、1件、重複なしは正常結果とする。
- クラッシュやthrowを行わない。

## Privacy Requirements

- 座標をログへ出力しない。
- 外部通信を行わない。

## UI / Accessibility Requirements

- なし。

## Processing Rules

- `abs(timestamp差) <= duplicateTimeInterval`かつ地表距離`<= duplicateDistance`。
- 保持優先順位は精度、新しいtimestamp、早いcreatedAt。

## Acceptance Criteria

- [x] 30秒以内かつ10m以内を重複除外する。
- [x] 30秒ちょうど・10mちょうどを重複除外する。
- [x] 時刻または距離の片方だけが条件外なら両方を保持する。
- [x] 前後どちらが高精度でも優れた点を保持する。
- [x] 同精度ではtimestamp、createdAtの優先順位を適用する。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Decisions

- `deduplicationKey`は永続化Modelの候補検索用でDomain入力に公開されていないため、純粋Processingでは全受理候補へ実時刻差とHaversine地表距離を直接適用する。
- 「後から受信した点を除外」と保持優先順位が競合する場合は、より具体的な保持優先順位を採用する。
- 複数の既存点と重複し新しい点が最優先の場合、その新しい点と重複する既存点をすべて除外する。既存点が最優先の場合、互いに重複とは限らない既存点は保持する。

## Test Requirements

### Unit Tests

- [x] 30秒以内・10m以内、両境界ちょうど。
- [x] 30秒以内・10m超、10m以内・30秒超。
- [x] 同一時刻・同一座標。
- [x] 後側／前側の精度が良い場合。
- [x] 同精度でtimestampまたはcreatedAtが異なる場合。
- [x] 閾値を差し替え可能。

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

- `issues/3-3-location-sanitizer-duplicates.md`
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

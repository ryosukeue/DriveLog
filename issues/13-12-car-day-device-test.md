# [Device] 車移動1日Testを実施する

## Summary

実車移動1日でSLC、Motion classification、Movement segmentation、停止判定とBackground継続性を確認する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/processing-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-12-car-day-device-test.md`
- 実機で再現した不具合に直接関係する実装とTest

### Forbidden Changes

- 運転中の端末操作、常時高精度GPS、実測なしの成功記録

## Requirements

1. 安全な同乗または運転終了後に結果を確認する。
2. Automotive Motion、長距離Movement、信号停止、目的地Stayを確認する。
3. App foreground/background/終了後のfallbackを確認する。
4. Routeや座標がLoggerへ出ないことを確認する。

## Acceptance Criteria

- [ ] 接続実機で車移動1日Testを完了する。
- [ ] 分類・距離・停車除外が許容範囲である。
- [ ] Crashと重大な収集欠損がない。

## Decision / Deviations

- 接続実機、実車、現実の移動が必要なため自動実行不能。成功扱いにしない。
- Synthetic classifier/segmenter/stay traffic filtering Testは成功済みだが実機センサー挙動の代替ではない。

## Files Expected to Change

- 現時点では本Issue文書のみ。

## Completion Report Format

- Summary
- Changed files and reasons
- Tests added
- Build result
- Test result
- SwiftLint result
- SwiftFormat result
- Manual verification
- Deviations
- Unresolved issues

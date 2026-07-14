# [Quality] Pro Maxレイアウトを確認する

## Summary

iPhone Pro Max相当の最大画面でCalendar、Day Detail、Full Map、Media Gridの主要表示と操作を確認する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-3-pro-max-layout.md`
- 再現したレイアウト不具合に直接関係するViewとUI Test

### Forbidden Changes

- Product仕様、Navigation、Project設定、永続化の変更

## Requirements

1. CalendarとDay Detailを往復できる。
2. Full MapのAnnotationとCalloutを操作できる。
3. Media Gridと3種のPreview状態を操作できる。
4. 不要な最大幅拡張やiPad対応を追加しない。

## Acceptance Criteria

- [x] 対象3 UI Testが成功する。
- [x] 修正を必要とする再現可能なレイアウト不具合がない。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- iPhone 15 Pro Max / iOS 26.5 SimulatorをPro Max検証端末として作成した。
- Calendar/Day Detail、Full Map、Media Grid/Previewの3 UI Testが成功した。
- UI Automationによる存在・Tap・Navigation検証を実施し、pixel単位の目視比較は未実施。
- 不具合を検出しなかったためSwiftソースの変更はない。

## Files Expected to Change

- `issues/13-3-pro-max-layout.md`のみ。

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

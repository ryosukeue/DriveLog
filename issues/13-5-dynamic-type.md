# [Accessibility] Dynamic Typeを確認する

## Summary

最小画面のiPhone SEで最大Accessibility Dynamic Typeを使用し、主要画面がScroll可能で操作を完了できることを確認する。

## Required Documents

- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-5-dynamic-type.md`
- 再現したDynamic Type不具合に直接関係するViewとUI Test

### Forbidden Changes

- Dynamic Type無効化、固定Text size、Project設定変更

## Requirements

1. iPhone SEで`accessibility-extra-extra-extra-large`を設定する。
2. OnboardingをScrollして完了できる。
3. Day DetailのMedia GridをScrollし全Preview状態を操作できる。
4. 検証後にSimulator設定を標準へ戻す。

## Acceptance Criteria

- [x] 対象2 UI Testが最大Accessibility sizeで成功する。
- [x] Media Gridの3列Accessibility policy Unit Testが既存Suiteにある。
- [x] Simulator Content Sizeを`medium`へ復元する。
- [x] 修正を要する再現可能な不具合がない。

## Decision / Deviations

- iPhone SE（第3世代）/ iOS 26.5で検証した。
- OnboardingとMedia Grid/Previewの2 UI Testは0 failureで成功した。
- 後処理Shellがzsh予約変数`status`への代入で終了1になったが、xcodebuildは`TEST SUCCEEDED`。別CommandでContent Sizeを`medium`へ復元・確認した。
- 人手による全文字の視覚的切れ確認は未実施。AutomationでScroll、Tap、Navigation可能性を確認した。
- 不具合を検出しなかったためSwiftソースの変更はない。

## Files Expected to Change

- `issues/13-5-dynamic-type.md`のみ。

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

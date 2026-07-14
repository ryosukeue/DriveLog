# [Quality] iPhone 15基準レイアウトを確認する

## Summary

iPhone 15をMVPの基準画面サイズとして、Onboarding、Calendar、Day Detail、Full Mapの主要導線を検証する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-2-iphone-15-layout.md`
- 再現したレイアウト不具合に直接関係するViewとUI Test

### Forbidden Changes

- Product仕様、Navigation、Project設定、永続化の変更

## Requirements

1. iPhone 15でOnboardingからCalendarへ進める。
2. CalendarとDay Detailを往復できる。
3. Full MapのMovement/Stay Calloutを切替できる。
4. 主要操作要素が存在しTap可能である。

## Acceptance Criteria

- [x] 対象3 UI Testが成功する。
- [x] 修正を必要とする再現可能なレイアウト不具合がない。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- iOS 17 Runtimeは環境にないため、iPhone 15 / iOS 26.5 Simulatorを作成して検証した。
- Onboarding、Calendar/Day Detail、Full Mapの3 UI Testが成功した。
- UI Automationによる存在・Tap・Navigation検証を実施し、pixel単位の目視比較は未実施。
- 不具合を検出しなかったためSwiftソースの変更はない。

## Files Expected to Change

- `issues/13-2-iphone-15-layout.md`のみ。

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

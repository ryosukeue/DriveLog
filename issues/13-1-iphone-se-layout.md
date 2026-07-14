# [Quality] iPhone SEレイアウトを修正する

## Summary

iPhone SE（第3世代）の画面幅と高さで主要MVP導線が表示・操作できることを確認し、レイアウト崩れがあれば修正する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-1-iphone-se-layout.md`
- レイアウト不具合が確認されたFeature Viewと対応UI Test

### Forbidden Changes

- Product仕様、Navigation、Project設定、永続化の変更

## Requirements

1. iPhone SE（第3世代）SimulatorでOnboarding全権限導線を完了できる。
2. CalendarからDay Detailへ遷移して戻れる。
3. Media GridをScrollし、写真・動画・利用不能Previewを操作できる。
4. 横向きやiPad対応を追加しない。

## Acceptance Criteria

- [x] 対象3 UI TestがiPhone SEで成功する。
- [x] Tap対象がScrollにより到達可能である。
- [x] 修正を必要とする再現可能なレイアウト不具合がない。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- iOS 17 Runtimeは環境にないため、iPhone SE（第3世代）/ iOS 26.5 Simulatorを作成して検証した。
- `testOnboardingPermissionFlowReachesCalendar`、`testCalendarNavigatesToDayDetail`、`testMediaGridPhotoVideoAndUnavailablePreviewFlow`の3件が成功した。
- UI Automationで要素の存在・Scroll・Tap・画面遷移を確認した。スクリーンショットの人手によるpixel単位比較は未実施。
- 不具合を検出しなかったためSwiftソースの変更はない。

## Files Expected to Change

- `issues/13-1-iphone-se-layout.md`のみ。

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

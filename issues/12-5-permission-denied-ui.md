# [UI] 権限拒否表示を実装する

## Summary

Onboardingで各権限が拒否・制限された場合に、利用不能機能と理由、設定アプリ導線、継続操作を表示する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/12-5-permission-denied-ui.md`
- `DriveLog/DriveLog/Features/Onboarding/OnboardingViewModel.swift`
- `DriveLog/DriveLog/Features/Onboarding/OnboardingView.swift`
- `DriveLog/DriveLogTests/Features/OnboardingViewModelTests.swift`

### Forbidden Changes

- PermissionCoordinator、Settings画面、Project設定変更

## Requirements

1. 現在phaseのdenied/restrictedを検出する。
2. 位置拒否はbackground記録不可を説明する。
3. Motion拒否は移動方法推定不可を説明する。
4. Photos拒否は写真・動画表示不可を説明する。
5. 「設定を開く」でPermissionManaging.openSystemSettingsを呼ぶ。
6. 主Buttonから次phaseまたはCalendarへ進める。
7. 拒否だけでアプリ全体を利用不能にしない。
8. Alert色だけに依存せず文言とIconを表示する。

## Acceptance Criteria

- [x] 3権限の拒否説明が正しい。
- [x] Settings呼出がTestされる。
- [x] 拒否状態でも全phaseを完了できる。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- 常設Settings画面はMVP外のため、拒否状態のOnboarding内だけに標準設定導線を置く。
- 2026-07-14にUnit Test 379件、UI Test 11件が成功した。

## Files Expected to Change

- Allowed Changes記載の4ファイルのみ。

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

# [UI] Photos権限要求フローを接続する

## Summary

Onboardingの最後に写真ライブラリ権限を要求し、authorized、limited、拒否の各状態から利用可能機能へ進む。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/12-4-photos-permission-flow.md`
- `DriveLog/DriveLog/Features/Onboarding/OnboardingViewModel.swift`
- `DriveLog/DriveLogTests/Features/OnboardingViewModelTests.swift`

### Forbidden Changes

- PermissionCoordinator、Limited選択変更UI、Project設定変更

## Requirements

1. phaseへphotosを追加する。
2. Motion terminal状態からphotosへ進む。
3. Photos未設定時にrequestPhotosを1回呼ぶ。
4. authorizedとlimitedは追加要求なしで完了する。
5. denied/restrictedでもOnboardingを止めず完了する。
6. location→motion→photos順序を維持する。
7. phaseに応じたButton文言を表示する。

## Acceptance Criteria

- [x] Photos要求が1回だけ行われる。
- [x] limitedを含む全terminal状態が完了する。
- [x] 3権限の順序がTestされる。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- PhotoKitの限定選択変更導線は12-6で追加する。
- 2026-07-14にUnit Test 378件、UI Test 11件が成功した。

## Files Expected to Change

- Allowed Changes記載の3ファイルのみ。

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

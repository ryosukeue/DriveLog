# [UI] Motion権限要求フローを接続する

## Summary

位置権限段階の後にMotion & Fitness権限を要求し、結果にかかわらず次段階へ進めるOnboarding phaseを追加する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/12-3-motion-permission-flow.md`
- `DriveLog/DriveLog/Features/Onboarding/OnboardingViewModel.swift`
- `DriveLog/DriveLog/Features/Onboarding/OnboardingView.swift`
- `DriveLog/DriveLogTests/Features/OnboardingViewModelTests.swift`

### Forbidden Changes

- PermissionCoordinator、Photos要求、Project設定、Production依存変更

## Requirements

1. phaseをlocation、motionで管理する。
2. location terminal状態でmotion phaseへ進む。
3. Motion未設定時にrequestMotionを1回呼ぶ。
4. authorized/denied/restricted時は追加要求せず完了する。
5. Motion拒否でも位置記録を利用可能とする前提でOnboardingを止めない。
6. 重複tapを防ぐ。
7. 現在phaseに応じたButton文言を表示する。

## Acceptance Criteria

- [x] location→motion順序が正しい。
- [x] Motion要求とterminal状態がTestされる。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- Motion完了後は暫定的にOnboarding完了とし、12-4でPhotos phaseを追加する。
- 2026-07-14にUnit Test 377件、UI Test 11件が成功した。

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

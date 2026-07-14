# [UI] 位置権限要求フローを接続する

## Summary

Onboardingから位置情報を「使用中のみ」から「常に許可」へ段階的に要求する状態駆動フローを実装する。

## Background

説明画面は完成したがOS権限要求へ未接続である。promptを重ねず、現在状態に応じた次操作を示す必要がある。

## Goal

PermissionManaging越しに位置権限を段階要求し、許可・拒否のどちらでも次段階へ進める。

## Non-Goals

- Motion、Photos要求
- 拒否詳細画面、Settings導線
- Monitoring開始接続

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/12-2-location-permission-flow.md`
- `DriveLog/DriveLog/Features/Onboarding/OnboardingViewModel.swift`
- `DriveLog/DriveLog/Features/Onboarding/OnboardingView.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLogTests/Features/OnboardingViewModelTests.swift`

### Forbidden Changes

- PermissionCoordinator実装、Motion/Photos要求変更
- Repository、Schema、Processing、Project設定変更

## Requirements

1. 未設定時はWhen In Useを1回要求する。
2. `.whenInUse`時は別操作でAlwaysを1回要求する。
3. `.always`時は要求せず次段階へ進む。
4. denied/restricted時もクラッシュせず次段階へ進む。
5. prompt中の重複操作を無効にする。
6. Permission updatesを観測して表示状態を更新する。
7. UI文言で段階と理由を説明する。
8. PermissionManagingをInitializer Injectionする。

## Acceptance Criteria

- [x] When In Use→Alwaysの順序がTestで固定される。
- [x] 既許可と拒否状態を処理できる。
- [x] 重複要求がない。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- OS prompt完了前にAlwaysを重ねないため、`.whenInUse`更新後にユーザーの次tapを要求する。
- このIssueの「次段階」は暫定的にOnboarding完了であり、12-3/12-4でMotion、Photosを間へ追加する。
- 2026-07-14にUnit Test 376件、UI Test 11件が成功した。

## Files Expected to Change

- Allowed Changes記載の5ファイルのみ。

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

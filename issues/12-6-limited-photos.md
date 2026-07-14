# [UI] Limited Photos状態を実装する

## Summary

Onboardingで写真の限定アクセス状態を明示し、アクセス可能な写真・動画だけが表示対象になることと、選択内容を変更する標準設定導線を案内する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/12-6-limited-photos.md`
- `DriveLog/DriveLog/Features/Onboarding/OnboardingViewModel.swift`
- `DriveLog/DriveLog/Features/Onboarding/OnboardingView.swift`
- `DriveLog/DriveLogTests/Features/OnboardingViewModelTests.swift`

### Forbidden Changes

- PermissionManaging、PhotoLibraryProviding、PhotoLibraryProviderの変更
- Project設定、外部Package、永続化Schemaの変更

## Requirements

1. Photos phaseで`.limited`を専用表示する。
2. アクセスを許可した写真・動画だけが表示対象になることを説明する。
3. 「選択内容を変更」から既存の標準設定導線を開く。
4. 限定アクセス状態でもOnboardingを完了できる。
5. 拒否状態の警告として扱わない。
6. 色だけに依存せず文言とIconで状態を伝える。

## Acceptance Criteria

- [x] Limited Photosの説明がPhotos phaseだけに表示される。
- [x] 選択内容変更操作が`openSystemSettings()`を呼ぶ。
- [x] Limited状態でもCalendarへ進める。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- `PermissionManaging`の公開契約を変更せず、既存の`openSystemSettings()`をApple標準の選択変更導線として使用する。
- アクセス可能な資産だけを返す処理は既存`PhotoLibraryProvider`の責務であり、このUI Issueでは変更しない。
- iPhone 15 / iOS 17.5 Simulatorが利用不能だったため、対象テストはiPhone 17 / iOS 26.5で実行した。
- 2026-07-14にUnit Test 380件、UI Test 11件が成功した。

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

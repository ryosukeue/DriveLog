# [UI] Onboarding画面を実装する

## Summary

初回起動時にDriveLogの目的、3権限の理由、端末内処理と外部送信なしを説明するOnboarding画面を実装する。

## Background

権限を要求する前に用途を説明し、Privacy方針を理解できる初回導線が必要である。

## Goal

初回だけOnboardingを表示し、開始操作後はCalendarへ進める基礎画面と完了状態保持を追加する。

## Non-Goals

- OS権限要求
- 拒否・Limited状態UI
- Settings導線

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/12-1-onboarding-screen.md`
- `DriveLog/DriveLog/Features/Onboarding/OnboardingView.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

### Forbidden Changes

- PermissionCoordinator、OS権限要求、AppContainer変更
- Repository、Schema、Processing変更
- Project設定、外部Package、Signing変更

## Requirements

1. アプリ名と短い説明を表示する。
2. 位置情報、モーション、写真・動画の理由をこの順で表示する。
3. データは端末内で処理されると表示する。
4. 外部サーバーへ送信しないと表示する。
5. 「権限設定を始める」Buttonを表示する。
6. 初回はOnboarding、完了後はCalendarを表示する。
7. 完了状態はUserDefaultsの`hasCompletedOnboarding`へ保存する。
8. ScrollViewで小型端末とDynamic Typeに対応する。
9. SF Symbolと文言を併用し、色だけで意味を表現しない。

## Accessibility Requirements

- Root identifier: `onboarding.root`
- Start identifier: `onboarding.start`
- 各説明は見出しと本文を1つのVoiceOver要素として読む。
- 最小tap areaは標準Buttonで確保する。

## Acceptance Criteria

- [x] 必須7内容が表示される。
- [x] 初回表示と完了後Calendar遷移が動作する。
- [x] UI Testで主要文言と開始Buttonを確認する。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- 権限要求接続前の開始Buttonは完了状態を保存してCalendarへ進む。12-2以降で同Callback内へ段階的権限フローを接続する。
- `-ui-testing-onboarding`では保存状態に関係なく画面を表示する。
- 空Calendar UI fixtureは専用`-ui-testing-calendar`でin-memory化だけを行い、seedを投入しない。
- 2026-07-14にUnit Test 374件、UI Test 11件が成功した。

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

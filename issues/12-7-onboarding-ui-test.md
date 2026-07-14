# [UI Test] Onboarding主要導線を追加する

## Summary

初回説明から位置情報、モーション、限定写真アクセスを経てCalendarへ進むOnboarding主要導線を、OS権限Dialogに依存しないUI Testで保証する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/12-7-onboarding-ui-test.md`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/Features/Onboarding/UITestPermissionManager.swift`
- `DriveLog/DriveLog/Features/Onboarding/OnboardingView.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

### Forbidden Changes

- Production PermissionCoordinator、権限Protocol、Project設定の変更
- OS権限Dialogの自動操作、外部Package追加

## Requirements

1. DEBUG限定Test Doubleで権限状態を決定的に遷移させる。
2. 専用Launch ArgumentではOnboarding未完了状態とIn-Memory永続化を使用する。
3. 位置情報はwhen-in-useからalwaysへ段階的に進む。
4. Motion許可後にPhotos phaseへ進む。
5. Limited Photosの説明と選択変更Buttonを確認する。
6. 最終操作でCalendarが表示されることを確認する。
7. Production起動では実権限実装を使用する。

## Acceptance Criteria

- [x] Onboarding主要導線UI Testが成功する。
- [x] OS権限Dialogや端末権限状態に依存しない。
- [x] Production権限処理へTest Doubleが混入しない。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- OS権限DialogはUI Testで安定制御できないため、`#if DEBUG`内の`UITestPermissionManager`を専用Launch Argument時だけ注入する。
- PhotosはLimitedへ遷移させ、Phase 12の限定アクセス導線も同じEnd-to-End Testで確認する。
- Test順序による`AppStorage`共有を避けるため、専用UI Testの完了状態は一時`@State`で管理する。Productionの完了状態は従来どおり永続化する。
- 親Accessibility identifierが子Buttonを隠したため、Limited説明と選択変更Buttonへ個別identifierを付与した。
- iPhone 15 Simulatorが利用不能だったため、iPhone 17 / iOS 26.5で検証した。初回はSimulator CloneのRunner起動拒否が発生し、競合を避けた直列実行で再検証した。
- 2026-07-14にUnit Test 380件とUI Test Suite 12件が成功した。

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

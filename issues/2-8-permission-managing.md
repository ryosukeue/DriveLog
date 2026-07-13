# [Platform] PermissionManagingを実装する

## Summary

位置情報、モーション、写真の権限状態と要求処理をApple Frameworkの背後へ集約し、Application／UIがOS型へ依存せず状態更新を購読できる基盤を追加する。

## Goal

3種類の権限を一元管理し、拒否や限定アクセスを通常状態として安全に扱えるPermissionCoordinatorを実装する。

## Non-Goals

- Onboarding／権限説明UI
- 監視開始や生イベント保存
- PhotoKit資産取得

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 0-3 PermissionKind／DriveLogError

## Scope

### Allowed Changes

- `issues/2-8-permission-managing.md`
- `DriveLog/DriveLog/Platform/Permissions/PermissionState.swift`
- `DriveLog/DriveLog/Platform/Permissions/PermissionManaging.swift`
- `DriveLog/DriveLog/Platform/Permissions/SystemPermissionAccess.swift`
- `DriveLog/DriveLog/Platform/Permissions/PermissionCoordinator.swift`
- `DriveLog/DriveLogTests/TestSupport/FakePermissionManager.swift`
- `DriveLog/DriveLogTests/Platform/PermissionCoordinatorTests.swift`
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`

### Forbidden Changes

- Domain、Repository、Provider、Application、UI
- Signing、Team、Bundle Identifier、Capability、Deployment Target
- 外部Package

## Requirements

1. `@MainActor PermissionManaging: AnyObject`を設計signatureどおり実装する。
2. LocationはnotDetermined／restricted／denied／whenInUse／alwaysを表現する。
3. MotionはnotDetermined／restricted／denied／authorizedを表現する。
4. PhotosはnotDetermined／restricted／denied／limited／authorizedを表現する。
5. `PermissionState`は3権限を保持し、Sendable／Equatableとする。
6. Production実装はCoreLocation、CoreMotion、PhotoKitをPlatform内部だけで使用する。
7. `refresh()`とOS側の権限変更をcurrentStateとAsyncStreamへ反映する。
8. when-in-use、always、motion、read-write Photosの要求を個別に提供する。
9. 設定アプリURLをUIApplicationで開く。開けない場合もクラッシュしない。
10. Photos limitedをauthorizedへ潰さない。
11. 各権限要求に必要なUsage Descriptionを生成Info.plist設定へ追加する。
12. Fakeは任意状態、Stream更新、全要求関数の呼出回数を扱う。

## Acceptance Criteria

- [x] 3権限の全OS状態がOS非依存の値へ変換される。
- [x] refreshと要求後に状態更新を購読できる。
- [x] limited Photosとwhen-in-use Locationを区別できる。
- [x] Fakeで状態と全呼出回数を検証できる。
- [x] 必要なUsage DescriptionがDebug／Release双方に存在する。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規ソースWarningと仕様外変更がない。

## Decisions

- 設計文書は状態型のcaseを列挙していないため、各Apple authorization statusを情報損失なく表せる最小case集合を採用する。
- 権限説明文は初回UIとは分離し、OSダイアログに必要な簡潔な日本語Usage DescriptionだけをProject設定へ追加する。
- Motion要求は短い履歴queryでOSプロンプトを開始し、callbackを状態更新通知として扱う。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Definition of Done

- [x] GoalとAcceptance Criteriaを満たす。
- [x] Allowed Changes内だけを変更する。
- [x] 全検証が成功する。

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
- Build:
- Unit Tests:
- Integration Tests:
- UI Tests:
- SwiftLint:
- SwiftFormat:
- Diff Check:
### Manual Verification
### Deviations
### Unresolved Issues

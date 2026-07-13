# [Application] UpdateStayOverrideUseCaseを実装する

## Summary

滞在地点に対する確定、非表示、自動判定復帰を、Stay Overrideとして保存する。

## Background

Stay OverrideのDomain Data、SwiftData Model、Repository Upsertは実装済みである。地図Calloutから自動判定を直接変更せずに保存するApplication境界が必要である。

## Goal

滞在区間とユーザー操作から再紐づけ可能なOverride Dataを生成し、同一滞在の修正をUpsertできるようにする。

## Non-Goals

- Map Callout、修正ボタン、Haptic
- 表示データへのOverride適用
- 再処理後の近似再紐づけ
- 自動表示判定の書き換え

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 1-4 StayOverrideData
- Issue 1-6 StayOverrideModel
- Issue 2-6 OverrideRepository
- Issue 0-5 Clock

## Scope

### Allowed Changes

- `issues/9-2-update-stay-override-use-case.md`
- `DriveLog/DriveLog/Application/Overrides/UpdateStayOverrideUseCase.swift`
- `DriveLog/DriveLogTests/Application/UpdateStayOverrideUseCaseTests.swift`

### Forbidden Changes

- Domain Data、SwiftData Schema、Repository実装の変更
- UI、Map、Processing、AppContainerの変更
- StaySegmentの自動判定値変更
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. `UpdateStayOverrideUseCase: Sendable`を設計文書のAPIで定義する。
2. Production実装はInitializer Injectionした`OverrideRepository`と`Clock`を使用する。
3. `confirm`、`hide`、`automatic`を保存できる。
4. `overrideKey`を`localDateKey|targetStableID`で生成する。
5. stableID、日付キー、到着・出発時刻、代表座標をOverrideへ保持する。
6. `createdAt`と`updatedAt`を実行時のClock値にする。
7. 同じoverrideKeyはRepositoryのUpsertへ渡し、複数Overrideを生成しない。
8. `automatic`も自動判定復帰の明示的なActionとして保存する。
9. 自動表示判定、信頼度、検出元、派生滞在を変更しない。
10. 空の日付キー／stableID、出発が到着より前の滞在は`invalidData`として保存しない。
11. Repository Errorを変換せず呼出元へ返す。

## Acceptance Criteria

- [x] 全3ActionのOverride Dataを正しく生成できる。
- [x] overrideKeyと近似再紐づけ用時刻・座標を保持する。
- [x] 同一滞在の再変更を同じKeyでUpsertできる。
- [x] 自動表示判定を変更しない。
- [x] 不正入力でRepositoryを呼ばない。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- `automatic`はOverride削除ではなく、V1 Schemaに定義されたActionとして保存する。
- 更新時の`createdAt`保持は既存PersistenceActor Upsertの責務とする。
- 最初の全Testでは直前のSimulator Runner競合によりUI Test起動がBusyで失敗した。Runner終了とSimulator再起動後、Unit Test 334件・UI Test 8件が成功した。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来であり、このIssueの新規Warningではない。

## Files Expected to Change

- Allowed Changes記載のIssue、Application UseCase、Unit Test。

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

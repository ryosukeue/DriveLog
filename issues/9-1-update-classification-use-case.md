# [Application] UpdateClassificationUseCaseを実装する

## Summary

移動区間に対するユーザー分類を、自動分類と分離したClassification Overrideとして保存する。

## Background

分類OverrideのDomain Data、SwiftData Model、Repository Upsertは実装済みである。Full MapのCalloutから安全に利用できるApplication境界が必要である。

## Goal

移動区間とユーザー分類から決定的なOverride Dataを生成し、同一区間の修正をUpsertできるようにする。

## Non-Goals

- Map Callout、分類Menu、Haptic
- 表示データへのOverride適用
- 再処理後の近似再紐づけ
- 自動分類の書き換え

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 1-4 ClassificationOverrideData
- Issue 1-6 ClassificationOverrideModel
- Issue 2-6 OverrideRepository
- Issue 0-5 Clock

## Scope

### Allowed Changes

- `issues/9-1-update-classification-use-case.md`
- `DriveLog/DriveLog/Application/Overrides/UpdateClassificationUseCase.swift`
- `DriveLog/DriveLogTests/Application/UpdateClassificationUseCaseTests.swift`

### Forbidden Changes

- Domain Data、SwiftData Schema、Repository実装の変更
- UI、Map、Processing、AppContainerの変更
- 自動分類データの変更
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. `UpdateClassificationUseCase: Sendable`を設計文書のAPIで定義する。
2. Production実装はInitializer Injectionした`OverrideRepository`と`Clock`を使用する。
3. `car`相当の`automotive`、`train`、`bus`、`walking`、`other`を保存できる。
4. `overrideKey`を`localDateKey|targetStableID`で生成する。
5. 元区間のstableID、日付キー、開始・終了時刻をOverrideへ保持する。
6. `createdAt`と`updatedAt`を実行時のClock値にする。
7. 同じoverrideKeyはRepositoryのUpsertへ渡し、複数Overrideを生成しない。
8. 自動分類、信頼度、経路、派生区間を変更しない。
9. 空の日付キー／stableID、終了が開始より前の区間は`invalidData`として保存しない。
10. Repository Errorを変換せず呼出元へ返す。

## Acceptance Criteria

- [x] 全5分類のOverride Dataを正しく生成できる。
- [x] overrideKeyと近似再紐づけ用時刻を保持する。
- [x] 同一区間の再変更を同じKeyでUpsertできる。
- [x] 自動分類値を変更しない。
- [x] 不正入力でRepositoryを呼ばない。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- UI表記の「車」は既存Domain Case `automotive`へ対応させる。
- 更新時の`createdAt`保持は既存PersistenceActor Upsertの責務とし、UseCaseは実行時刻を両時刻へ設定した入力を渡す。
- Unit Test 330件、UI Test 8件が成功した。AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来であり、このIssueの新規Warningではない。

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

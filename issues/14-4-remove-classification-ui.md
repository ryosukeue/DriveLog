# [UI] 移動分類Override操作をProduction UIから削除する

## Summary

Movementの自動分類と保存済みOverride表示を維持しつつ、Day Detail/Full Mapから分類変更操作、保存状態、成功Haptic、専用Error表示を削除する。

## Background

分類変更はFull MapのMovement Callout MenuからのみProduction UIへ公開されている。SwiftData V1の`ClassificationOverrideModel`、Repository、UseCase、再処理時のOverride適用は既存データ互換に必要であるため維持する。保存済みOverrideは`OverrideDisplayDataApplier`経由で従来どおり表示分類へ反映するが、新規編集導線は提供しない。

## Goal

Movement Calloutを読み取り専用にし、分類変更固有のPresentation依存をProduction UIから切り離す。

## Non-Goals

- 自動分類処理の変更
- ClassificationOverride永続化Schema/既存データの削除
- Application/Data層のMigrationを伴う削除
- Stay Override UIの変更

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/14-4-remove-classification-ui.md`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/Features/Map/`
- 対応する`DriveLogTests/`と`DriveLogUITests/`ファイル

### Forbidden Changes

- SwiftData V1 Schema、Model、Migration
- 自動分類、Override Repository、再処理処理
- Stay Override UI
- Signing、Package

## Requirements

1. Movement Calloutから分類Menuを削除し読み取り専用にする。
2. Full Mapの分類保存/失敗state、callback、alertを削除する。
3. 分類成功Hapticを削除し、Stay成功Hapticは維持する。
4. Production compositionから`UpdateClassificationUseCase`を切り離す。
5. 分類変更専用Presentation Test/UI Testを削除する。
6. 保存済みOverride表示、自動分類、Schema/Application/Data実装を維持する。

## Acceptance Criteria

- [ ] Production UIに分類変更操作が存在しない
- [ ] Movement情報は読み取り可能
- [ ] Stay修正操作は維持される
- [ ] 保存済みOverrideが表示へ反映される既存Testが成功する
- [ ] Build/Test/Lint/Format/diff checkが成功する
- [ ] Schema変更と新規Warningがない

## Decisions / Deviations

- Migrationリスクを避けるため`ClassificationOverrideModel`、Repository、UseCase、Processing適用は内部互換機能として残す。
- 既存Overrideは表示に反映されるが、UIから変更・解除できない。

## Completion Report Format

- Summary
- Removed UI and presentation code
- Existing override behavior
- Tests removed/updated
- Verification
- Deviations
- Unresolved issues

## Completion

- Movement Calloutの分類Menu、保存中state、更新callback、失敗Alert、分類成功HapticをProduction UIから削除した。
- Calloutは自動分類と保存済みユーザー分類を含む読み取り専用表示として維持した。
- Production compositionから分類更新UseCaseを切り離した。Application UseCase、Repository、V1 Schema、Processing適用は既存データ互換のため維持した。
- 分類変更専用Presentation Unit Testを削除し、Override適用/Application/Data Testは維持した。
- Build成功。全393 Test成功。SwiftLint、SwiftFormat、`git diff --check`成功。
- SimulatorでFull Map/Stay/Mediaを含むUI Testが成功。実機操作は未確認。
- DebuggerVersionStore等のSimulator/Xcode Warningは環境由来で、新規Source Warningはない。

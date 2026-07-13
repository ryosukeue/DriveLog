# [Application] Override適用済みDisplay Dataを実装する

## Summary

Classification／Stay Overrideを適用したDay Detailの表示データを、Map Sceneへ一貫して反映する。

## Background

`MovementDisplayData`、`StayDisplayData`とOverrideMatcherによる照合は実装済みである。一方、MapSceneBuilderは自動判定のDomain Segmentだけを入力とするため、ユーザー分類がMap Calloutへ反映されず、Stayの元の自動表示判定とeffective表示が区別されていない。

## Goal

自動判定値を保持しながら、ユーザー修正をDay DetailとFull Mapの表示へ同じ規則で反映する。

## Non-Goals

- Override保存UI、Haptic
- 再処理Pipelineへの再紐づけ接続
- Domain／SwiftData Schema変更

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 3-14 OverrideMatcher
- Issue 6-2 LoadDayDetailUseCase
- Issue 9-1〜9-4 Override保存・UI

## Scope

### Allowed Changes

- `issues/9-5-override-display-data.md`
- `DriveLog/DriveLog/Application/DayDetail/LoadDayDetailUseCase.swift`
- `DriveLog/DriveLog/Application/DayDetail/OverrideDisplayDataApplier.swift`
- `DriveLog/DriveLogTests/Application/OverrideDisplayDataApplierTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapViewModelTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapViewModelTestSupport.swift`

### Forbidden Changes

- Domain Data、Processing、SwiftData Schema、Repository変更
- Map操作UI、Haptic追加
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. Movement表示は自動分類とユーザー分類を分離して保持する。
2. Map Movement Labelへ一致した`userClassification`を反映する。
3. Overrideなしではユーザー分類をnilのままにする。
4. Stayは`confirm`で表示、`hide`で非表示、`automatic`／nilで元の自動判定に従う。
5. Map Stay Annotationの`isVisibleByAutomaticRule`にはeffective値ではなく元の自動判定値を保持する。
6. MapSceneBuilderの経路、Region、Media結果を変更しない。
7. stableIDが存在しない表示データを別対象へ適用しない。
8. ComponentはSwiftUI、SwiftData、MapKitへ依存しない純粋変換とする。

## Acceptance Criteria

- [x] Classification OverrideがMap Labelへ反映される。
- [x] 自動分類値は不変である。
- [x] Stay 3 ActionとOverrideなしの表示規則が正しい。
- [x] Stay Annotationへ元の自動判定状態が残る。
- [x] 経路、Region、Mediaが不変である。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- 既存Display Dataと照合処理は再実装せず、MapSceneへの最終表示変換だけを`OverrideDisplayDataApplier`へ分離する。
- Issue 9-4で追加したactor Test DoubleがクリーンBuild時に`nonisolated protocol`適合エラーとなったため、同じ同期保証を持つ`OSAllocatedUnfairLock`保護Classへ変更する。Production変更はない。
- Unit Test 352件、UI Test 8件が成功した。新規helperのActor Isolation Warning 2件は`nonisolated`純粋変換として解消し、再BuildでSource Warningがないことを確認した。
- 残るAppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来である。

## Files Expected to Change

- Allowed Changes記載のIssue、Application component／UseCase、Unit Test。

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

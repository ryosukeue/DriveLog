# [Map] 区間Calloutへ分類Menuを追加する

## Summary

Full Mapの移動区間Calloutから、車・電車・バス・徒歩・その他へ分類を修正できる標準Menuを追加する。

## Goal

選択中の移動区間を、元の自動分類を保持したままClassification Overrideとして安全に保存できるようにする。

## Non-Goals

- Stay修正、Haptic、再処理後の再紐づけ
- SwiftData Schema／Repository変更
- 自動分類の変更

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 9-1 UpdateClassificationUseCase
- Issue 7-7 Movement Callout

## Scope

### Allowed Changes

- `issues/9-3-movement-classification-menu.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapViewModel.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLogTests/Features/RouteMapViewModelTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`

### Forbidden Changes

- Domain、Processing、SwiftData Schema、Repository変更
- Stay修正、Haptic追加
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. Movement Calloutへ車、電車、バス、徒歩、その他の標準Menuを追加する。
2. 選択中の`MovementSegmentData`を9-1 UseCaseへ渡す。
3. `MovementDisplayData`をDay DetailからFull Mapへ明示的に渡し、Map表示値からDomain Segmentを復元しない。
4. 保存中はMenuを無効化して連続タップを防ぐ。
5. 成功時にCalloutのユーザー分類を局所更新する。
6. 自動分類表示は変更しない。
7. 失敗時は選択と地図を維持し、短いAlertを表示して再操作可能にする。
8. MenuとCalloutへAccessibility Identifier／Labelを付ける。
9. AppContainerからUseCaseをInitializer Injectionする。

## Acceptance Criteria

- [x] Calloutに5分類のMenuが表示される。
- [x] 保存中の重複操作が抑止される。
- [x] 成功時だけユーザー分類表示が更新される。
- [x] 失敗時にAlertを表示し、元表示を維持する。
- [x] 自動分類値が不変である。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- MapKit Annotation View内にはUIKit標準`UIButton` + `UIMenu`を使用する。
- 保存後の全日再読込は行わず、永続化成功後に選択区間の`MapMovementLabel.userClassification`だけを更新する。
- Unit Test 340件、UI Test 8件が成功した。Menuの実タップ導線はIssue 9-8のUI Testで確認する。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来であり、このIssueの新規Warningではない。

## Files Expected to Change

- Allowed Changes記載のIssue、Composition Root、Navigation、Map UI／ViewModel、Unit Test。

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

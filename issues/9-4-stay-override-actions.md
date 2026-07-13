# [Map] 滞在Calloutへ修正操作を追加する

## Summary

Full Mapの滞在Calloutから、立ち寄り確定、非表示、自動判定復帰を保存できる標準Menuを追加する。

## Goal

元の自動滞在判定を保持したままStay Overrideを保存し、成功結果を地図へ即時反映する。

## Non-Goals

- Haptic、再処理後の再紐づけ
- SwiftData Schema／Repository変更
- 自動滞在判定の変更

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 9-2 UpdateStayOverrideUseCase
- Issue 7-8 Stay Callout

## Scope

### Allowed Changes

- `issues/9-4-stay-override-actions.md`
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
- `DriveLog/DriveLogTests/Features/RouteMapViewModelTestSupport.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`

### Forbidden Changes

- Domain、Processing、SwiftData Schema、Repository変更
- 分類修正、Haptic追加
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. Stay Calloutへ確定、非表示、自動判定へ戻す標準Menuを追加する。
2. 選択中の`StaySegmentData`を9-2 UseCaseへ渡す。
3. `StayDisplayData`をDay DetailからFull Mapへ渡し、元の自動表示判定を保持する。
4. 保存中はMenuを無効化して連続タップを防ぐ。
5. `confirm`成功時は対象を表示したままにする。
6. `hide`成功時はCalloutを閉じ、対象を地図から除外する。
7. `automatic`成功時は元の`isVisibleByAutomaticRule`へ戻し、falseなら地図から除外する。
8. 失敗時は選択と地図を維持し、Alertを表示して再操作可能にする。
9. MenuとCalloutへAccessibility Identifier／Labelを付ける。
10. AppContainerからUseCaseをInitializer Injectionする。

## Acceptance Criteria

- [x] Calloutに3操作のMenuが表示される。
- [x] 保存中の重複操作が抑止される。
- [x] confirm、hide、automaticが成功後だけ表示へ反映される。
- [x] hideと自動非表示でCalloutが閉じる。
- [x] 失敗時に元表示を維持する。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- MapKit Annotation View内にはUIKit標準`UIButton` + `UIMenu`を使用する。
- `automatic`の表示結果はMap Sceneのeffective値ではなく、渡された元`StaySegmentData.isVisibleByAutomaticRule`を正とする。
- Unit Test 347件、UI Test 8件が成功した。Menuの実タップ導線はIssue 9-8のUI Testで確認する。
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

# [UI] 成功時Hapticを追加する

## Summary

全画面地図の分類変更と滞在修正が保存に成功した場合だけ、軽い触覚フィードバックを返す。

## Background

Issue 9-3／9-4で保存操作と成功・失敗状態は接続済みだが、`ui-spec.md`が求める成功時Hapticは未実装である。UIKit依存をViewModelから分離し、失敗・無効操作・保存中の重複操作では発火させない必要がある。

## Goal

注入可能なHaptic境界を通じて、分類変更・滞在修正の保存成功を軽い触覚で通知する。

## Non-Goals

- 日付削除成功Haptic
- 画面遷移、選択、スクロールへのHaptic
- エラー時の強いHaptic

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 9-3 Movement分類Menu
- Issue 9-4 Stay修正操作

## Scope

### Allowed Changes

- `issues/9-7-success-haptic.md`
- `DriveLog/DriveLog/Platform/Haptics/HapticFeedbackProviding.swift`
- `DriveLog/DriveLog/Platform/Haptics/SystemHapticFeedbackProvider.swift`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapViewModel.swift`
- `DriveLog/DriveLogTests/Application/AppContainerTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapViewModelTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapViewModelTestSupport.swift`

### Forbidden Changes

- Override UseCase、Repository、SwiftData Schema変更
- Map操作、Callout選択肢、エラー表示変更
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. UIKitのHaptic APIをProtocolの背後へ隠す。
2. Production実装は軽いImpact Feedbackを1回発火する。
3. Haptic依存はInitializer Injectionする。
4. 分類変更保存の成功後に1回発火する。
5. 滞在修正保存の成功後に1回発火する。
6. 保存失敗、未知ID、依存なし、保存中の重複操作では発火しない。
7. 通常の選択、画面遷移、スクロールでは発火しない。

## Privacy Requirements

- Haptic APIへ座標、経路、メディア識別子、自由文字列を渡さない。
- 外部通信とログ出力を追加しない。

## UI Requirements

- 分類変更成功と滞在修正成功だけ軽い触覚フィードバックを行う。
- 失敗時の表示と保存中の連続タップ防止は既存挙動を維持する。

## Interface Contract

```swift
@MainActor
protocol HapticFeedbackProviding: Sendable {
    func performLightSuccess()
}
```

## Implementation Constraints

- ViewModelはUIKitをimportしない
- Production依存はAppContainerから注入する
- `fatalError()`、`try!`、`as!`、`print()`を追加しない
- 新規Warning、未完成TODOを残さない

## Acceptance Criteria

- [x] 分類変更成功時だけ軽いHapticが1回発火する
- [x] Stay修正成功時だけ軽いHapticが1回発火する
- [x] 失敗・無効・重複操作では発火しない
- [x] ViewModelがUIKitへ依存しない
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する
- [x] 新規Warningと仕様外変更がない

## Test Requirements

- 分類変更成功／失敗時の発火回数
- Stay修正成功／失敗時の発火回数
- AppContainerへのTest Double注入

## Decision / Deviations

- `UIImpactFeedbackGenerator(style: .light)`を使用し、UIKit型はSystem実装内だけに閉じ込める。
- Unit Test 354件、UI Test 8件が成功した。Xcode summaryはparameterized runを展開して389件、論理Test 361件と集計する。
- HapticはSimulatorでは物理的に確認できないため、System実装のBuildとTest Doubleの呼出回数を検証した。実機の触覚強度は手動確認対象とする。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility message、および既存Swift 6予告Warningは既存の環境・コード由来で、新規Source Warningはない。

## Files Expected to Change

- Allowed Changes記載のIssue、Platform境界、Composition Root、ViewModel、Unit Test。

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

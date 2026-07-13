# [Processing] MediaPlacementCalculatorを実装する

## Summary

位置情報付きメディアを実座標へ配置し、経路から500m以内の場合だけ最適な移動区間へ関連付けて日別MapSceneへ反映する。

## Background

Issue 8-10でMedia Annotation表示は完成したが、`LoadDayDetailUseCase`は`MapSceneBuilder`へ空の配置配列を渡している。設計済みの`MediaPlacementCalculating`契約と500mルールを決定的なProcessing実装として接続する必要がある。

## Goal

日別メディアの実位置を地図へ反映し、近傍経路との関連IDを計算できる。

## Non-Goals

- 位置情報なしメディアの時刻による推測配置
- MediaPlacementの永続化
- Media Annotationクラスタリング

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- `MediaAssetReference`、`MovementSegmentData`、`MediaPlacement`
- `ProcessingConfiguration.mvp.media`
- Issue 8-10 Media Annotation

## Scope

### Allowed Changes

- `issues/8-11-media-placement-calculator.md`
- `DriveLog/DriveLog/Processing/Media/MediaPlacementCalculator.swift`
- `DriveLog/DriveLog/Application/DayDetail/LoadDayDetailUseCase.swift`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLogTests/Processing/MediaPlacementCalculatorTests.swift`
- `DriveLog/DriveLogTests/Application/LoadDayDetailUseCaseTests.swift`

### Forbidden Changes

- Domain型、SwiftData Schema、PhotoKit Providerの変更
- 位置情報なしメディアの推測配置
- 閾値のハードコードや500mルール変更
- 座標、localIdentifier、経路のログ出力
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. `MediaPlacementCalculating: Sendable`を設計どおり定義する。
2. 位置情報付き資産だけを入力順で`MediaPlacement`へ変換する。
3. 配置座標はメディアが持つ実座標とする。
4. メディア座標から各移動区間Polylineまでの最短距離を計算する。
5. 500m以内（境界を含む）の最短区間だけを関連付ける。
6. 500m超でもメディアは配置し、関連区間IDをnilとする。
7. 同距離の場合は撮影時刻が区間内、次に区間へ最も近い時刻を優先する。
8. 最後の同率はstableID文字列順で決定する。
9. 空経路の移動区間は候補外とする。
10. `LoadDayDetailUseCase`が計算結果を`MapSceneBuilder`へ渡す。

## Processing Rules

- `maximumRouteMediaDistance = ProcessingConfiguration.mvp.media.maximumRouteMediaDistance`（500m）。
- Polylineは局所正距円筒座標へ投影し、各線分への最近点距離を計算する。
- 距離差が浮動小数点誤差範囲内の場合だけ撮影時刻をTie-breakに使用する。

## Error / Privacy Handling

- 空配列、空経路、creationDateなしをクラッシュさせない。
- creationDateなしは距離判定可能で、時間Tie-breakでは最後に扱う。
- 座標、経路、localIdentifierをLoggerへ出さない。
- SwiftData変更と外部通信なし。

## Acceptance Criteria

- [x] 位置情報なしを除外し、位置ありを実座標へ配置する。
- [x] 500m以内／境界／超過が仕様どおり関連付けられる。
- [x] 最短距離、撮影時刻、stableIDで決定的に候補を選ぶ。
- [x] 日別MapSceneへ配置結果が渡る。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- 位置なし、空経路、単一点、線分最近点。
- 500m以内、ちょうど、超過。
- 最短区間優先、同距離の区間内時刻／最短時間差／stableID順。
- creationDateなし。
- LoadDayDetailUseCaseからMapSceneBuilderへの配置引渡し。

## Decision / Deviations

- 「同距離に近い」の幅は設計に数値定義がない。最短区間ルールを優先し、距離差`0.001m`以内のみ同距離として時間Tie-breakする保守的な実装とする。
- 地球曲率を考慮した局所投影をメディア座標中心で行い、短い日次経路のPolyline最近点を外部Frameworkなしで計算する。
- 利用可能な`iPhone 17 (iOS 26.5)` SimulatorでUnit Test 321件、UI Test 6件が成功した。
- 実Photos資産と実経路の重畳表示はIssue 8-14／最終実機確認対象とする。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来であり、本IssueのSource Code由来の新規Warningはない。

## Files Expected to Change

- Allowed Changes記載のIssue、Calculator、日別UseCase／Composition、Unit Test。

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

# [Processing/UI] 車っぽい移動だけを表示・集計へ残す

## Summary

全てのLocation、Motion、Visitは従来どおりRaw Eventとして保存し、既存の自動分類とSwiftData Schemaを維持する。一方、日別画面、カレンダー、月間サマリー、地図へ渡す移動は`automotiveLike`だけに限定する。

## Background

徒歩、自転車、判定不能な短区間が車の移動ログへ混在すると、距離・時間・地図が実際のドライブと一致しない。充電中は高精度Location Modeへ切り替わるが、分類処理は同じ`MovementClassifier`を通るため、充電状態によって車以外を通過させない共通Filterが必要である。

## Goal

保存済みの生ログと既存の分類結果を壊さず、表示と集計の移動を車っぽい区間だけへ統一する。

## Non-Goals

- Raw Location、Motion、Visitの削除・書換え
- MovementSegmentModel、DayAggregateModel、Schema V1の変更
- CoreLocationの取得条件や充電Modeの変更
- ユーザー分類Overrideの削除・Migration
- 車っぽさの新しい独自判定閾値の追加

## Required Documents

実装前に次を読むこと。

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/processing-rules.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`
- [x] `issues/14-2-charging-location-mode.md`
- [x] `issues/14-7-continuous-calendar.md`

## Dependencies

- `MovementSegmentData`
- `DayAggregateData`
- `MovementClassifier`の既存`AutomaticMovementType`
- `LoadCalendarMonthUseCase`
- `DefaultLoadDayDetailUseCase`

## Scope

### Allowed Changes

- `issues/16-1-automotive-movement-filter.md`
- `DriveLog/DriveLog/Processing/Classification/AutomotiveMovementFilter.swift`
- `DriveLog/DriveLog/Application/Calendar/LoadCalendarMonthUseCase.swift`
- `DriveLog/DriveLog/Application/DayDetail/LoadDayDetailUseCase.swift`
- `DriveLog/DriveLogTests/Processing/AutomotiveMovementFilterTests.swift`
- `DriveLog/DriveLogTests/Application/LoadCalendarMonthUseCaseTests.swift`
- `DriveLog/DriveLogTests/Application/LoadDayDetailUseCaseTests.swift`
- `DriveLog/DriveLogTests/Integration/OverrideIntegrationTests.swift`

### Forbidden Changes

- `DriveLog/DriveLog/Data/Models/`
- `DriveLog/DriveLog/Data/Schema/`
- `DriveLog/DriveLog/Platform/Location/`
- `DriveLog/DriveLog/Application/Processing/`
- Raw Event保存、権限、Signing、Team、Bundle Identifier、Capability、外部Package
- 緯度・経度、経路、PhotoKit localIdentifierの通常ログ出力

## Decision

既存の`MovementClassifier`が生成した`AutomaticMovementType.automotiveLike`だけを採用する。`walkingLike`と`other`は表示・日別カレンダー距離・月間距離/時間・MapSceneから除外する。

保存済みDerived Dataに対しても同じFilterをUseCase境界で適用するため、再処理完了前の古い派生データが一時的に画面へ混在しない。空のMovement配列と`hasValidMovement == true`が同時に返る古いStoreでは、既存Aggregateを互換Fallbackとして使い、通常の処理結果では区間Filterを優先する。

充電中／非充電中に関係なく、分類済みMovementへ同じFilterを適用する。充電中の高精度Location取得自体は既存の単一Providerと既存Classifierを維持する。

既存のOverride統合テストは、Filter導入後も「車っぽい移動」としてOverride再接続を検証できるよう、Fixtureの移動距離・速度を既存の分類フォールバック条件に合わせる。永続化形式や本番判定値は変更しない。

## Requirements

1. Filterは`Sendable`な値型で、`automotiveLike`以外を返さない。
2. Raw EventとSwiftData V1の保存値を変更しない。
3. カレンダー日距離は車っぽい区間の距離だけを使う。
4. Day DetailのSummary、Movement表示、MapSceneは車っぽい区間だけを使う。
5. 月間サマリーはこのFilterを通した値だけを合計する。
6. Classification Overrideの保存形式と既存Stable IDを変更しない。
7. 充電Mode固有の別Filterや高精度GPS常時利用を追加しない。
8. `fatalError()`、`try!`、`as!`、`print()`、`debugPrint()`、`NSLog()`を使用しない。

## Acceptance Criteria

- [x] Walking／cycling／unknown／判定不能区間が画面の移動距離・時間・Polylineへ含まれない。
- [x] Automotive区間は距離、時間、Start/End、MapSceneへ残る。
- [x] Raw Event、既存Schema、Overrideが保持される。
- [x] 充電中の高精度取得結果も同じ分類Filterを通る。
- [x] Unit Testで全分類の採否、集計値、空データ互換Fallbackを確認する。
- [x] Build、Test、SwiftLint、SwiftFormat、`git diff --check`が成功する。

## Privacy Requirements

- 座標や経路をLoggerへ出力しない。
- PhotoKit localIdentifierをLoggerへ出力しない。
- 外部サーバーやAnalyticsへデータを送信しない。

## Completion Report Format

### Summary

Raw EventとSwiftData V1を変更せず、`automotiveLike`のMovementだけをCalendar、Day Detail、MapScene、Monthly Summaryの表示・集計へ渡すFilterを追加した。互換Fallbackにも自動分類チェックを追加した。

### Changed Files

- `Processing/Classification/AutomotiveMovementFilter.swift`: 車分類の抽出と表示用Aggregate再構築。
- `LoadCalendarMonthUseCase.swift`: カレンダー距離を車分類へ限定。
- `LoadDayDetailUseCase.swift`: Summary、Polyline、Movement表示を車分類へ限定。
- 関連Unit/Integration Test: 採否、Fallback、Override再接続のFixtureを検証。

### Tests Added

AutomotiveMovementFilter、Calendar fallback、既存Override再接続のテストを追加・更新。

### Verification

- `./scripts/build.sh`: 成功
- `./scripts/test.sh`: 成功（433 tests / 94 suites、UI 14件を含む）
- `swiftlint lint --strict`: 成功
- `swiftformat --lint .`: 成功
- `git diff --check`: 成功

### Manual Verification

iPhone 17 Simulatorで既存Day Detail、Full Map、Polyline、Stay、削除、Media導線のUI Testを実行し、車分類の表示導線を確認した。実機走行データでの分類精度は未確認。

### Deviations

既存Override統合Fixtureの移動距離・速度だけを自動分類の既存フォールバック条件に合わせた。本番の判定閾値、保存形式、Override Schemaは変更していない。

### Unresolved Issues

車らしさの判定精度は既存`MovementClassifier`に依存するため、実機ログでの誤分類調整は別Issueが必要。

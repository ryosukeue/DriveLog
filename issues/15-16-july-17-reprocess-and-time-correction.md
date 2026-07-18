# [Processing] 7/17のGPSドリフト再処理と時間基準の経路補正

## Summary

実機Storeを読み取り専用で監査し、7/17 16:14〜17:47に残っていた停止中のGPSドリフトMovementを再処理で除外する。あわせて、表示PolylineとStayの端点補正を座標距離ではなく時間的な隣接関係で行う。

## Background

接続中のiPhone 15から最新Storeを取得した。該当区間にはRaw Location 9点があり、16:30:30から17:47:57まで約77分の欠測を挟んで累積約1.28kmのMovementが保存されていた。Raw Locationの精度は3.6〜62.4mで、同日の処理状態は`rawRevision = 3112`、`processedRevision = 3111`、`pending`だったため、端末に表示されていた派生データは最新Raw Eventを反映していなかった。

最新ビルドを端末へInstall／Launchした後、7/17は`3112 / 3112 / completed`となり、該当Movementは再処理結果から消えた。これはRaw Eventを変更せず、既存のAlgorithm Version 4のStationary Drift判定を適用した結果である。

## Goal

7/17の未処理日を最新アルゴリズムで再処理して停止中の誤Movementを除外し、表示PolylineのStay接続を時間基準へ統一する。

## Non-Goals

- Raw Location、Motion、Visitの変更・削除
- SwiftData V1 Schema、永続化Route、距離、時間、平均速度の変更
- Location取得方式、充電Mode、権限、Capabilityの変更
- Map Matchingや欠測区間の推測接続

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/processing-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/15-9-open-visit-route-recovery.md`
- [x] `issues/15-15-stationary-gps-drift.md`

## Dependencies

- Processing Algorithm Version 4
- `MapSceneBuilder`
- `StationaryDriftDetector`

## Scope

### Allowed Changes

- `issues/15-16-july-17-reprocess-and-time-correction.md`
- `DriveLog/DriveLog/Features/Map/MapSceneBuilder.swift`
- `DriveLog/DriveLogTests/Features/MapSceneBuilderTests.swift`

### Forbidden Changes

- SwiftData V1 Schema、Raw Event、Repository、Processing Algorithm Version
- Location、Motion、Visit Providerと充電Mode
- UI操作、Stay Override、Media、Navigation
- Signing、Team、Bundle Identifier、Capability、外部Package
- 座標・経路・PhotoKit Identifierの通常ログ出力

## Decision

Polyline端点の表示補正は、同一`localDateKey`の可視Stayについて、Movement開始・終了との時間差が既存の5分許容以内、またはMovement端点がStayの到着〜出発区間内にある場合にだけ行う。Stay代表座標とRaw route端点の距離は判定条件に使わない。補正は`MapScene`表示専用で、永続RouteとMovement metricsへ補正座標を追加しない。

この判断は、実機でRaw LocationとVisit代表座標が150mを超えてずれると、時間的には同じStayなのにPolylineが切れるためである。時間条件を超える別のStay、非表示Stay、別日Stayは接続しない。

## Requirements

1. 7/17の`rawRevision > processedRevision`状態を起動時のPending処理で再処理できる。
2. Stationary Drift判定を満たす7/17 16:14〜17:47のMovementを派生データへ残さない。
3. 時間的に隣接したStayへは、座標距離に関係なく表示Polyline端点を接続する。
4. Movement端点がStay区間内にある場合も表示Polylineを接続する。
5. 5分を超えて時間的に離れたStay、非表示Stay、別日Stayへは接続しない。
6. 補正座標を距離、時間、平均速度、永続Routeへ含めない。
7. Raw Eventと既存Schemaを変更しない。

## Processing Rules

- GPSドリフトの破棄条件は既存`ProcessingConfiguration.mvp.segmentation.stationaryDrift`を使用する。
- 端末再処理は`rawRevision`と`processedRevision`が一致するまで行う。
- Polyline補正はProcessing結果を変更せず、MapScene生成時だけ適用する。

## Privacy Requirements

- 端末監査は読み取り専用Storeの件数、時刻間隔、精度、状態、距離だけを扱う。
- Loggerへ正確な座標、経路、PhotoKit localIdentifierを出力しない。
- Testへ実機の座標・識別子をコピーしない。

## Test Requirements

### Unit Tests

- [x] 150mを超えていても時間的に隣接した前後Stayへ接続する。
- [x] Movement端点がStayの到着〜出発区間内にある場合に接続する。
- [x] 時間超過、非表示、別日Stayへ接続しない。

### Integration Tests

- [x] 端末Storeの7/17処理状態が`3112 / 3112 / completed`へ進み、該当Movementが消えることを読み取り専用再取得で確認する。

### UI Tests

- [ ] なし（既存Map UIの端点補正のみ）。

### Manual Tests

- [ ] 実機で7/17の地図を開き、誤Movementが表示されず、実移動のPolylineが維持されることを確認する。
- [ ] 端点のStay接続が自然に見えることを確認する。

## Acceptance Criteria

- [x] 7/17の処理状態が最新Raw Revisionまで完了する。
- [x] 16:14〜17:47の停止中GPSドリフトMovementが再処理後に残らない。
- [x] 時間基準のStay接続Unit Testが成功する。
- [x] 座標距離だけを理由に時間的な接続を拒否しない。
- [x] 距離・時間・永続RouteのMetricsが補正で変わらない。
- [ ] 充電中の高密度Location取得を実機走行で確認する。
- [x] Buildが成功する。
- [x] Testが成功する。
- [x] SwiftLintが成功する。
- [x] SwiftFormat Checkが成功する。
- [x] `git diff --check`が成功する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- `issues/15-16-july-17-reprocess-and-time-correction.md`
- `DriveLog/DriveLog/Features/Map/MapSceneBuilder.swift`
- `DriveLog/DriveLogTests/Features/MapSceneBuilderTests.swift`

## Files That Must Not Change

- `DriveLog/DriveLog/Processing/`
- `DriveLog/DriveLog/Data/`
- `DriveLog/DriveLog/Platform/Location/`
- `DriveLog/DriveLog/Platform/Power/`
- `DriveLog/DriveLog/Shared/Logging/`

## Completion Report Format

### Summary

### Changed Files

### Tests Added

### Verification

### Device Data Audit

### Charging Mode Audit

### Deviations

### Unresolved Issues

# [Location] 位置取得をSignificant Location Changeへ統一する

## Summary

走行候補、走行確定、充電状態に関係なく、位置取得をSignificant Location Change（SLC）だけへ統一する。標準Location Updateへの昇格と高密度Location emitを停止する。

## Background

Issue 17-1/17-2ではMotionとGPS証拠により標準Location Updateへ切り替えていたが、実機では取得点が密になりすぎた。最新フィードバックを優先し、省電力なSLCだけをRaw Location入力とする。

## Goal

Application起動後に単一`CLLocationManager`でSLCだけを開始し、Power/Motionの変化でLocation取得方式を変更しない。

## Non-Goals

- Core Motion Raw Event、CLVisitの停止
- Movement分類・処理閾値の変更
- 保存済みLocationの削除または再処理

## Required Documents

- [x] `AGENTS.md`
- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/test-plan.md`
- [x] `issues/17-1-vehicle-aware-recording.md`
- [x] `issues/17-2-vehicle-movement-confirmation.md`

## Scope

### Allowed Changes

- `issues/18-3-significant-location-only.md`
- `docs/project-rules.md`
- `docs/requirements.md`
- `docs/architecture.md`
- `docs/interfaces.md`
- `docs/processing-rules.md`
- `docs/test-plan.md`
- `docs/implementation-plan.md`
- `DriveLog/DriveLog/Platform/Location/LocationProviding.swift`
- `DriveLog/DriveLog/Platform/Location/CoreLocationProvider.swift`
- `DriveLog/DriveLog/Platform/Location/ChargingLocationEmissionFilter.swift`
- `DriveLog/DriveLog/Platform/Power/PowerStateProviding.swift`
- `DriveLog/DriveLog/Application/Monitoring/StartMonitoringUseCase.swift`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- 関連する`DriveLogTests`のTest file

### Forbidden Changes

- SwiftData Schema、Raw Event保存形式、Processing閾値
- Motion/VisitのRaw Event監視
- UI、権限Capability、Signing、外部Package

## Requirements

1. `LocationRecordingMode`はSLCを表す`lowPower`だけを持つ。
2. `CoreLocationProvider`は`startMonitoringSignificantLocationChanges()`だけを開始する。
3. Provider開始時に残存する標準Location Updateを停止する。
4. Power/Motion/Location証拠によるMode切替を行わない。
5. `StartMonitoringUseCase`はLocation、Motion Raw Event、Visitを従来どおり開始する。
6. 同じ正常稼働中のSLCを重複起動しない。
7. SLC callbackの有効Locationは間引かず保存Streamへ流す。
8. 標準Location用の60秒emit filterをProductionから削除する。

## Privacy Requirements

- 座標、正確な時刻、経路をLoggerへ追加しない。
- 外部通信を追加しない。

## Test Requirements

- 初回起動で`lowPower`だけが適用されること。
- Motion/Visit失敗時もSLCが継続すること。
- 正常稼働中の重複開始を防ぐこと。
- Core Location callbackがSLC診断としてLocationを流すこと。
- Build、Test、Lint、Format、Diff Checkを成功させる。

## Acceptance Criteria

- [x] 標準Location Updateを開始するProduction codeがない。
- [x] Power/MotionでLocation Modeが変化しない。
- [x] SLC、Motion、VisitのRaw Event保存が維持される。
- [x] 自動検証が成功する。

## Completion Report Format

- Summary
- Location Contract
- Changed Files
- Tests Added/Removed
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion Report

### Summary

ProductionのLocation監視をSignificant Location Changeだけへ統一し、走行・充電状態による標準Location Updateへの切替を削除した。

### Location Contract

Locationは`lowPower`（SLC）のみ。Motion Raw EventとVisit監視は独立して継続し、SLC callbackは追加間引きなしで保存へ流す。

### Changed Files

Location Provider、Monitoring Use Case、AppContainer、Location関連文書とTestを更新し、標準Location用emit filterを削除した。

### Tests Added/Removed

SLC単一Mode、重複開始防止、Motion/Visit失敗時の継続をTestし、削除した充電切替契約のTestを除去した。

### Verification

450 Unit Test、関連UI Test、Build、SwiftLint strict、SwiftFormat lint、Diff Checkを通過した。

### Manual Verification

SimulatorでLifecycleを確認済み。実機での長時間SLC取得確認は未実施。

### Deviations

なし。

### Unresolved Issues

なし。

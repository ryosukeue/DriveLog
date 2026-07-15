# [Location] 充電中だけ高精度Location Modeへ切り替える

## Summary

非充電時のSignificant Location Change監視を維持し、端末が充電中または満充電の間だけ標準Location Updateへ排他的に切り替えて約1分間隔のRaw Location保存を行う。

## Background

現在は単一`CLLocationManager`の`startMonitoringSignificantLocationChanges()`だけを使用し、`Info.plist`のBackground Modeは`processing`のみである。SLCは低消費電力だが車載走行のPolylineには点が疎い。

提案する状態遷移は次の通り。

- unplugged / unknown → `lowPower`（SLC）
- charging / full → `chargingHighAccuracy`（standard update）
- charging終了 → standard updateを停止して`lowPower`へ戻る
- permission denial / service unavailable → `failed` / `unavailable`

同じ`CLLocationManager`内で切り替え、SLCとstandard updateを同時起動しない。`desiredAccuracy = kCLLocationAccuracyBest`、`distanceFilter = 50m`、`activityType = .automotiveNavigation`を充電中に使用し、Providerからの保存対象emitは前回保存から60秒以上を基本とする。iOSはBackgroundで正確な周期を保証せず、停止・終了・圏外等で欠測し得る。Force Quit後の再開は保証しない。

標準更新はSLCよりBattery/熱負荷が高いが、充電中だけに限定する。Background継続には既存Always Location権限に加え`UIBackgroundModes/location`が必要で、Signing capability、Team、Bundle Identifier変更は不要。実機では充電開始/終了、画面消灯、Background、車載走行、熱・電池状態、保存間隔を確認する。

## Goal

充電状態に応じたLocation記録Modeをテスト可能な状態機械で制御し、非充電時のBattery特性を変えず充電ドライブの経路点数を増やす。

## Non-Goals

- 常時高精度GPS
- 厳密な60秒Timer
- Force Quit後のstandard update再開保証
- SwiftData Schema変更

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 14-1

## Scope

### Allowed Changes

- `issues/14-2-charging-location-mode.md`
- `DriveLog/DriveLog/Platform/Location/`
- `DriveLog/DriveLog/Platform/Power/`
- `DriveLog/DriveLog/Application/Monitoring/`
- `DriveLog/DriveLog/Application/EventStorage/RawEventStorageCoordinator.swift`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/Application/AppLifecycleCoordinator.swift`
- `DriveLog/DriveLog/Shared/Logging/LogEvent.swift`
- `DriveLog/DriveLog/Shared/Logging/OSLogLogger.swift`
- `DriveLog/DriveLog/Info.plist`
- 対応する`DriveLogTests/`ファイル
- `docs/requirements.md`
- `docs/architecture.md`
- `docs/interfaces.md`
- `docs/test-plan.md`
- `docs/implementation-plan.md`

### Forbidden Changes

- SwiftData V1 Schema
- Signing、Team、Bundle Identifier
- 常時高精度化
- 複数Location Provider/Managerの同時起動
- 外部Package

## Requirements

1. 充電状態取得をPlatform Protocolの背後へ隔離する。
2. 状態機械は充電/満充電だけをhigh accuracyとし、unplugged/unknownはlow powerとする。
3. 単一ManagerでSLCとstandard updateを排他的に切り替える。
4. high accuracyはBest、50m distance filter、automotive navigationを使用する。
5. high accuracyのLocation emitはOS配信の範囲で約60秒間隔に抑制する。
6. Background Location modeを追加する。
7. Mode変更、充電状態、取得/emit件数を座標なしの固定イベントで診断する。
8. 緯度、経度、経路、正確な時刻をログへ出さない。

## Acceptance Criteria

- 充電開始/終了でModeが双方向に遷移する。
- SLCとstandard updateが同時に動かない。
- non-chargingの設定と動作は従来通り。
- Unit Testが状態遷移、約1分filter、重複起動防止を確認する。
- Build/Test/Lint/Format/diff check成功、新規Source Warningなし。

## Decisions / Deviations

- 60秒はProviderのemit間隔であり、Core Locationへの厳密な周期指定ではない。
- `unknown`はBattery節約側へ倒してlow powerとする。
- 実機Background継続と熱/電池影響は自動検証できない。

## Completion Report Format

- Summary
- State transitions
- Changed files and reasons
- Tests added
- Build/Test/Lint/Format/diff results
- Manual verification
- Deviations
- Unresolved issues

## Completion

- 単一`CLLocationManager`でSLCとstandard updateを排他的に切り替える状態機械を実装した。
- high accuracy設定はBest、50m、automotive navigation、automatic pause、Background Location。Provider emitは60秒以上の間隔とした。
- Battery stateはUIKitを使うPlatform実装へ隔離し、Application actorが変更Streamを監視する。
- Mode、callback入力数、emit数は固定値と件数だけをPrivacy安全にLoggerへ出す。
- `UIBackgroundModes/location`を追加。Signing、Team、Bundle Identifier、SwiftData Schemaは未変更。
- Build成功。全398 Test（UI Test 13件を含む）が成功。
- SwiftLint、SwiftFormat、`git diff --check`成功。
- 実機での充電状態通知、Background継続、約1分間隔、熱・Battery影響は未確認。

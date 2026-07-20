# [Location/Application] 車両移動検知と記録Modeを統合する

## Summary

Motolog型のActivity Recognitionと、車載型アプリが使う外部電源・車両接続を組み合わせ、充電していない走行でも車両系移動を検知した時だけ高精度Locationへ昇格する。充電中／満充電時の高精度Modeは維持し、車両系Activityが停止した後は短時間の信号変動を吸収して低電力SLCへ戻す。

## Background

現在のLocation Providerは、`charging`または`full`の時だけ`chargingHighAccuracy`を使い、非充電時は常にSignificant Location Changeを使っている。Core MotionはRaw Event保存と後処理分類には利用しているが、記録Modeの切替には利用していない。そのため、非充電時の車移動が疎なSLCだけになり、車でない場所のGPSドリフトと同じ入力経路になる。

Motologは端末のActivity Recognitionと位置情報で走行を自動検知し、DriversnoteやTripLog Driveは車内ビーコン、車両電源、専用GPSで車両境界を補強する。DriveLogでは外部デバイスを必須にせず、Activity Recognitionを主判定、充電状態を高精度化の補助条件として採用する。

## Goal

車両系Activityを検知した非充電時の走行を高精度Locationで記録し、短時間停止やActivityの揺れで経路を不要に分断せず、走行終了後は低電力監視へ戻るテスト可能な状態遷移を実装する。

## Non-Goals

- BLEビーコン、OBD-II、CarPlay、専用GPSデバイスの必須化
- 自家用車、電車、バスを完全に識別する分類器
- 常時高精度GPS、Raw Eventの削除・書換え
- SwiftData V1 Schema、Migration、既存Overrideの変更
- 新しいUI、設定画面、外部Package、サーバー通信

## Required Documents

- [x] `AGENTS.md`
- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`
- [x] `docs/issue-template.md`
- [x] `issues/14-2-charging-location-mode.md`
- [x] `issues/15-13-charging-mode-reconciliation.md`
- [x] `issues/16-1-automotive-movement-filter.md`
- [x] `issues/16-4-automotive-filter-boundary.md`

## Dependencies

- `LocationProviding`
- `MotionProviding`
- `PowerStateProviding`
- `CoreLocationProvider`
- `CoreMotionProvider`
- `StartMonitoringUseCase`
- `RawEventStorageCoordinator`

## Scope

### Allowed Changes

- `issues/17-1-vehicle-aware-recording.md`
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
- `DriveLog/DriveLog/Platform/Motion/MotionProviding.swift`
- `DriveLog/DriveLog/Platform/Motion/CoreMotionProvider.swift`
- `DriveLog/DriveLog/Application/Monitoring/StartMonitoringUseCase.swift`
- `DriveLog/DriveLog/Shared/Logging/LogEvent.swift`
- `DriveLog/DriveLog/Shared/Logging/OSLogLogger.swift`
- `DriveLog/DriveLogTests/TestSupport/FakeMotionProvider.swift`
- `DriveLog/DriveLogTests/Platform/CoreMotionProviderTests.swift`
- `DriveLog/DriveLogTests/Application/StartMonitoringUseCaseTests.swift`
- `DriveLog/DriveLogTests/Shared/Logging/LoggingTests.swift`
- `DriveLog/DriveLogTests/Application/VehicleRecordingStateMachineTests.swift`
- `DriveLog/DriveLog/Application/Monitoring/VehicleRecordingStateMachine.swift`

### Forbidden Changes

- SwiftData V1 Model、Migration、Raw Eventの保存形式
- `AutomotiveMovementFilter`の表示契約、既存の分類Override
- `ContentView.swift`など初期Templateの無関係な変更
- Location Provider以外の複数Location Manager起動
- Signing、Team、Bundle Identifier、Deployment Target、Capabilityの変更
- BLE、OBD、CarPlay、外部Package、サーバー、Analyticsの追加
- 緯度、経度、経路、PhotoKit localIdentifier、写真名のLogger出力
- `fatalError()`、`try!`、`as!`、`print()`、`debugPrint()`、`NSLog()`

## Requirements

1. `MotionProviding`は既存のRaw Event用`events`を維持し、記録Mode判定用に`AsyncStream<MotionEventData>`の`activityChanges`を追加する。
2. `CoreMotionProvider`はMotion Eventを保存用StreamとActivity Streamの両方へ配信する。既存の保存イベントの内容は変更しない。
3. `LocationRecordingMode`に非充電走行用の`automotiveHighAccuracy`を追加する。
4. `charging`／`full`は従来どおり`chargingHighAccuracy`とする。
5. `unplugged`／`unknown`かつ車両系Activityがない場合は`lowPower`とする。
6. 車両系Activityを受信したら、非充電時でも同じ単一`CLLocationManager`を`automotiveHighAccuracy`へ切り替える。
7. `automotive`と`stationary`など複数Flagが同時にある場合は、既存Processing Rulesと同じく車両系Activityを優先する。
8. 車両系Activityがなくなっても、3分間は`automotiveHighAccuracy`を維持する。赤信号や一時的なCore Motion揺れで経路を分断しない。
9. 3分経過後に車両系Activityが戻らず、非充電状態なら`lowPower`へ戻す。充電中／満充電時は`chargingHighAccuracy`を維持する。
10. 同一Modeがすでに正常稼働中の場合、Location Providerを再起動しない。
11. `automotiveHighAccuracy`と`chargingHighAccuracy`はBest accuracy、50m distance filter、automotive navigation、automatic pause無効、Background Locationを使用する。
12. 高精度Modeのemitは既存の約60秒フィルタを共有し、取得・emit・保存件数をPrivacy-safeな固定イベントで診断できるようにする。
13. Activity Streamが利用不可または権限拒否でも、充電状態に基づく既存ModeとSLC保存は継続する。
14. 状態機械は値型として単体テスト可能にし、Activityの車両系／非車両系、猶予期間終了、充電優先を検証する。
15. 既存のMovementClassifierと`AutomotiveMovementFilter`は維持し、記録Modeの昇格を自家用車確定とは扱わない。

## State Changes

記録Modeは次の優先順位で決定する。

```text
charging/full                         → chargingHighAccuracy
unplugged/unknown + automotive       → automotiveHighAccuracy
unplugged/unknown + stop grace       → automotiveHighAccuracy
unplugged/unknown + grace expired    → lowPower
```

Raw Location、Motion、Visit、SwiftData Schemaの状態は変更しない。Mode変更とActivity状態だけをOSLogへ固定Codeで記録する。

## Error Handling

- Motion監視の利用不可、拒否、Callback Errorは既存の`DriveLogError`へ変換し、位置監視を停止させない。
- Mode切替失敗は既存の`locationRecordingModeChangeFailed`で記録し、次のPower／Activity Snapshotで再試行する。
- 猶予Taskのキャンセルは正常な状態遷移として扱い、エラーへ変換しない。

## Privacy Requirements

- Activity Code、Power Code、Mode Code、件数だけをLoggerへ出力する。
- 緯度、経度、経路、正確な時刻、PhotoKit localIdentifier、写真・動画名をLoggerへ出力しない。
- 外部サーバー、Analytics、外部Packageを追加しない。

## Test Requirements

- `CoreMotionProvider`がMotion Eventを既存StreamとActivity Streamへ配信すること。
- 車両系Activityで`automotiveHighAccuracy`へ遷移すること。
- 非車両系Activityの直後に即時低電力へ戻らず、猶予期間中は高精度を維持すること。
- 猶予期間終了後に非充電なら`lowPower`へ戻ること。
- 献電中／満充電時はActivityが非車両系でも`chargingHighAccuracy`を維持すること。
- 既存の充電遷移、重複起動防止、Raw Event保存が回帰しないこと。

## Acceptance Criteria

- [x] 非充電中に車両系Activityを受信すると高精度Modeへ昇格する。
- [x] 充電中／満充電時の高精度Modeが維持される。
- [x] 車両系Activity終了直後の短時間停止でModeが分断されない。
- [x] 猶予期間終了後に非充電ならSLCへ戻る。
- [x] Motion利用不可時も既存のSLC／充電Modeが利用可能である。
- [x] 単一Location Manager、既存Schema、Raw Event、Overrideが維持される。
- [x] Unit Test、Build、Test、SwiftLint、SwiftFormat、`git diff --check`が成功する。
- [x] 新規Warning、座標を含むログ、仕様外変更がない。

## Decision / Deviations

- 外部車載デバイスは今回のMVPへ追加せず、Core Motionを車両境界の主信号とする。充電状態は高精度化の補助信号として残す。
- 3分は赤信号・短時間停車・Activityの一時的な揺れを吸収する初期値であり、iOSのActivity更新間隔を厳密に保証する値ではない。
- Core Motionは自家用車を完全識別しないため、表示・集計は既存の「車っぽい移動」分類を維持する。
- iOS Backgroundの正確なTimer実行と、実機での充電・走行・熱影響は自動検証できない。

## Completion Report

- Summary: Core MotionのActivity Streamを記録Mode切替へ接続し、Significant Location Changeを非充電時の基底監視として維持した。車両系Activityまたは充電／満充電時だけ高精度Modeへ昇格し、車両系Activity終了後は3分の猶予を経て低電力Modeへ戻る。
- Root Cause / Design Decision: 非充電時の走行がSignificant Location Changeのみで疎になっていた。外部ビーコンやOBDは追加せず、Activity Recognitionを主信号、電源状態を優先補助信号とした。
- State transitions: `charging/full → chargingHighAccuracy`; `unplugged/unknown + automotive または停止猶予 → automotiveHighAccuracy`; 猶予終了後は`lowPower`。
- Changed files and reasons: Allowed Changesに列挙したProtocol、Core Location／Core Motion Provider、監視UseCase、Logging、状態機械、Test、設計文書、Issueを変更した。Project設定、Schema、UI、権限Capabilityは変更していない。
- Tests added: `VehicleRecordingStateMachineTests`、Core Motionの二重Stream配信、ActivityによるMode昇格／猶予／充電優先のStartMonitoringテスト、LogEvent等価性テスト。
- Build/Test/Lint/Format/Diff results: `./scripts/build.sh` 成功、`./scripts/test.sh` 成功（Swift Testing 445件、UI Test 15件）、`swiftlint lint --strict` 成功（0 violations）、`swiftformat --lint .` 成功、`git diff --check` 成功。
- Manual verification: iPhone Simulatorで既存の起動・地図・写真・日付操作UI Testを実行した。実機のCore Motion Activity、充電状態、Background継続、実走行時のGPS密度とBattery影響は未確認。
- Deviations: 3分の停止猶予は初期値。iOSのBackground実行とActivity更新は厳密な周期を保証しない。BLE／OBD／CarPlay／専用GPSは今回追加していない。
- Unresolved issues: 実機でActivity認識権限を許可した状態の走行・短時間停車・充電開始／終了・低電力モードを含む遷移確認が必要。

## Completion Report Format

- Summary
- Root Cause / Design Decision
- State transitions
- Changed files and reasons
- Tests added
- Build/Test/Lint/Format/Diff results
- Manual verification
- Deviations
- Unresolved issues

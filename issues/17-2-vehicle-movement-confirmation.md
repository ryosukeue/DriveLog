# [Location/Application] 車両移動をGPSで確認してから記録を確定する

## Summary

Core Motionの`automotive`判定だけで高精度記録へ切り替えず、短い候補状態を経てGPSの実移動を確認してから走行記録を確定する。誤判定時は低電力監視へ戻し、既存のRaw Event保存形式とProcessing/UIの契約を維持する。

## Background

Issue 17-1では、車両系Activityを受信すると直ちに`automotiveHighAccuracy`へ昇格していた。Core Motionは有用な低消費電力信号だが、単独では徒歩・停車・乗車直後の誤判定を排除できない。GPSの速度、精度、位置差を短時間だけ組み合わせ、走行開始を確認する必要がある。

## Goal

Core Motionの車両候補をGPSの移動証拠で確認し、確認前は候補Mode、確認後だけ走行Modeへ遷移する状態機械を実装する。

## Non-Goals

- SwiftData Schema、Migration、Raw Event保存形式の変更
- UIや地図表示の変更
- 常時GPS、毎秒保存、道路Map Matching
- BLE、OBD-II、CarPlay、外部Package、サーバー通信
- 自家用車・電車・バスの完全識別
- 既存の自動分類、Stay、Overrideの変更

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
- [x] `issues/17-1-vehicle-aware-recording.md`

## Dependencies

- Issue 17-1の`VehicleRecordingStateMachine`
- `StartMonitoringUseCase`
- `LocationProviding` / `CoreLocationProvider`
- `MotionProviding` / `CoreMotionProvider`

## Scope

### Allowed Changes

- `issues/17-2-vehicle-movement-confirmation.md`
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
- `DriveLog/DriveLog/Application/Monitoring/StartMonitoringUseCase.swift`
- `DriveLog/DriveLog/Application/Monitoring/VehicleRecordingStateMachine.swift`
- `DriveLog/DriveLog/Application/Monitoring/VehicleMovementEvidenceEvaluator.swift`
- `DriveLog/DriveLogTests/Application/StartMonitoringUseCaseTests.swift`
- `DriveLog/DriveLogTests/Application/VehicleRecordingStateMachineTests.swift`
- `DriveLog/DriveLogTests/Application/VehicleMovementEvidenceEvaluatorTests.swift`
- `DriveLog/DriveLogTests/TestSupport/FakeLocationProvider.swift`
- `DriveLog/DriveLogTests/Platform/CoreLocationProviderTests.swift`

### Forbidden Changes

- SwiftData Model、Migration、Repository、Raw Eventの保存形式
- `ContentView.swift`などUI、Map、Media、Calendar
- `MotionEventData`、`LocationEventData`のSchema変更
- Signing、Team、Bundle Identifier、Deployment Target、Capability
- 複数のLocation Manager起動
- `fatalError()`、`try!`、`as!`、`print()`、`debugPrint()`、`NSLog()`
- Loggerへの座標、経路、PhotoKit localIdentifier、写真名の出力

## Requirements

1. 車両Activity受信後は、直ちに走行確定せず`automotiveCandidate`へ遷移する。
2. Candidateでは標準Locationを短時間だけ使用し、既存のLocation Providerを再利用する。
3. CandidateのGPS確認は、許容水平精度、速度、前回点からの位置差を使う。
4. 有効な移動証拠を2回確認した場合だけ`automotiveHighAccuracy`へ遷移する。
5. GPS精度不良、速度不明かつ位置差不足の場合は証拠をリセットする。
6. Candidate中に車両Activityが終了した場合は、高精度走行へ遷移せず`lowPower`へ戻す。
7. 走行確定後の一時停止は既存の停止猶予を維持し、赤信号で終了扱いにしない。
8. 走行確定後にGPS移動証拠が戻った場合は停止猶予を取り消す。
9. 充電／満充電だけでは高精度Modeへ切り替えない。走行確定後の補助情報としてのみ使用する。
10. Candidateのタイムアウトは既定90秒とし、移動証拠がない場合は`lowPower`へ戻す。
11. `automotiveHighAccuracy`と`chargingHighAccuracy`の既存設定は維持し、Candidateだけを追加する。
12. Raw Eventは削除・変更せず、誤判定の表示可否は既存Processingの分類へ委ねる。
13. Loggerへ座標、速度、時刻、経路を出力せず、既存の固定Codeログだけを使用する。

## State Changes

```text
idle → automotiveCandidate → automotiveHighAccuracy
  ↑            │                    │
  └────────────┘                    └→ stopping → idle
```

- `automotiveCandidate`: Motion候補を受信したが、GPS確認前
- `automotiveHighAccuracy`: GPS移動証拠を2回確認済み
- `stopping`: 走行確定後の一時停止猶予
- `idle`: Significant Location Change中心の低電力監視

## Error Handling

- Motion利用不可・権限拒否時は既存の低電力監視を継続する。
- CandidateのLocation取得失敗は走行確定失敗として扱い、低電力へ戻す。
- Candidate／停止猶予Taskのキャンセルは正常な遷移として扱う。

## Privacy Requirements

- Loggerへ座標、経路、正確な速度、正確な時刻を出さない。
- 診断する場合はMode、Activity Code、固定理由Codeのみを出す。
- 外部通信、Analytics、テストへの実移動Fixtureを追加しない。

## Processing Rules

- Candidate確認の閾値は`ProcessingConfiguration`へ新規追加せず、Location取得の安全なPlatform/Application境界値として固定する。
- 水平精度150m以下を候補確認の上限とする。
- `speedMetersPerSecond >= 3m/s`、または前回有効点から100m以上の移動を1回の証拠とする。
- 2つ目以降の証拠は、前回点より新しい時刻で90秒以内に取得されたものだけを有効とする。
- 2回の有効証拠を要求し、単一GPS点で確定しない。
- 既存の`maximumHorizontalAccuracy=500m`、重複除去、区間分割、車両分類は変更しない。

## Data Model Rules

- 変更なし。

## UI Requirements

- 変更なし。

## Acceptance Criteria

- [x] `automotive`受信直後に`automotiveHighAccuracy`へ切り替わらない
- [x] Candidate中にGPS移動証拠を2回確認すると`automotiveHighAccuracy`へ切り替わる
- [x] 精度不良・速度不明・位置差不足では走行確定しない
- [x] Candidate中にActivityが終了すると`lowPower`へ戻る
- [x] Candidateが90秒でタイムアウトし、低電力へ戻る
- [x] 走行確定後の停止猶予と復帰が維持される
- [x] 充電状態だけでは高精度へ切り替わらない
- [x] Raw Event、Schema、UI、既存分類が変更されない
- [x] Unit Test、Build、Test、SwiftLint、SwiftFormat、`git diff --check`が成功する
- [x] 新規Warning、Privacy違反、仕様外変更がない

## Test Requirements

### Unit Tests

- [x] Candidate、Driving、Stopping、Idleの遷移
- [x] GPS速度による証拠
- [x] 位置差による証拠
- [x] 精度不良、速度不明・位置差不足の拒否
- [x] 2回未満では未確定
- [x] Candidateタイムアウト
- [x] 充電中でもIdleは低電力

### Integration Tests

- [x] なし（Schema／Repository変更なし）

### UI Tests

- [x] なし（UI変更なし）

### Manual Tests

- [ ] 実機で徒歩、停車中の乗車、短時間走行、赤信号、充電中走行を確認する

## Implementation Constraints

- Swift Concurrency、AsyncStream、Initializer Injectionを使用する。
- DomainへApple Frameworkをimportしない。
- Location Providerは単一`CLLocationManager`を再利用する。
- Raw Eventを削除・更新しない。
- 未完成TODOを残さない。

## Files Expected to Change

- `DriveLog/DriveLog/Platform/Location/LocationProviding.swift`
- `DriveLog/DriveLog/Platform/Location/CoreLocationProvider.swift`
- `DriveLog/DriveLog/Platform/Location/ChargingLocationEmissionFilter.swift`
- `DriveLog/DriveLog/Application/Monitoring/StartMonitoringUseCase.swift`
- `DriveLog/DriveLog/Application/Monitoring/VehicleRecordingStateMachine.swift`
- `DriveLog/DriveLog/Application/Monitoring/VehicleMovementEvidenceEvaluator.swift`
- `DriveLog/DriveLogTests/Application/StartMonitoringUseCaseTests.swift`
- `DriveLog/DriveLogTests/Application/VehicleRecordingStateMachineTests.swift`
- `DriveLog/DriveLogTests/Application/VehicleMovementEvidenceEvaluatorTests.swift`
- `DriveLog/DriveLogTests/TestSupport/FakeLocationProvider.swift`
- `DriveLog/DriveLogTests/Platform/CoreLocationProviderTests.swift`
- 設計文書とこのIssue

## Files That Must Not Change

- `DriveLog/DriveLog/DriveLog.xcodeproj/project.pbxproj`
- SwiftData Model／Migration／Repository
- Presentation、Map、Media、Calendar

## Migration Requirements

- Schema version: 変更なし
- Migration Plan: 変更なし
- Existing data behavior: Raw Eventと既存派生データを保持
- Rollback behavior: 既存Modeへ戻せる状態機械とする

## Completion Report Format

- Summary
- Changed files and reasons
- Tests added
- Build/Test/Lint/Format/Diff results
- Manual verification
- Deviations
- Unresolved issues

## Completion Report

### Summary

Core Motionの`automotive`を走行開始の確定信号ではなく候補信号へ変更し、GPSの移動証拠を2回確認した後だけ高精度走行Modeへ遷移するようにした。充電状態だけでは高精度Modeへ入らず、確定後の補助条件として扱う。

### Changed files and reasons

- `LocationProviding.swift`、`CoreLocationProvider.swift`: Candidate Modeと確認用Location Streamを追加し、標準Location設定を実装。
- `ChargingLocationEmissionFilter.swift`: Candidateの10秒間隔を注入可能にした。
- `StartMonitoringUseCase.swift`、`VehicleRecordingStateMachine.swift`: Candidate、GPS確認、90秒タイムアウト、停止猶予復帰の状態遷移を実装。
- `VehicleMovementEvidenceEvaluator.swift`: 精度150m以下、速度3m/s以上または100m以上の位置差、90秒以内の証拠判定を実装。
- Test files: Candidate遷移、GPS証拠、ストリーム分離、充電単独抑止をSwift Testingで追加・更新。
- 設計文書: Candidate確認と充電単独抑止を記録。

### Tests added

VehicleMovementEvidenceEvaluator、VehicleRecordingStateMachine、StartMonitoringUseCase、CoreLocationProviderのUnit Testを追加・更新した。

### Build/Test/Lint/Format/Diff results

- `./scripts/build.sh`: 成功
- `./scripts/test.sh`: 成功（Unit 452件、UI 15件）
- `swiftlint lint --strict`: 成功、違反0件
- `swiftformat --lint .`: 成功
- `git diff --check`: 成功

### Manual verification

実機での走行、徒歩、停車、充電中の切替確認は未実施。Simulator上の既存UI Testは全15件成功した。

### Deviations

既存のRaw Event保存用Streamを変更せず、確認処理専用の`locationChanges`を追加した。これにより保存処理と候補判定が同じAsyncStreamを取り合わない。Candidateの標準Locationは100m精度・100m距離フィルタ、保存間隔は10秒とし、既存の走行確定後設定（Best、50m、約60秒）を維持した。

### Unresolved issues

Build/TestログにはXcode Simulator由来の`AppIntents.framework`メタデータ省略、Core LocationのMain Thread警告、Simulator Accessibility重複警告がある。今回の変更によるSwiftLint警告やコンパイル警告はない。実機では権限、Background、Activity揺れ、GPS精度、充電状態の組み合わせを確認する必要がある。

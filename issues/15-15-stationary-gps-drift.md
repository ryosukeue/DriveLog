# [Processing] 停止中のGPSドリフトをMovementから除外する

## Summary

停止中に同じ範囲を往復するGPS誤差の累積をMovementとして保存せず、実移動のPolylineと日別距離だけを残す。

## Background

実機から読み取り専用で複製済みの2026-07-17 Storeを、座標を出力せず監査した。Raw Locationは69件で、現行Sanitizerでは64件が採用対象になる。保存済みMovement 7件のうち1件だけが、約94分、累積約1.28kmに対して始点からの最大進行が累積距離の約3割、空間的な広がりが約460m、平均約0.23m/sとなっていた。位置点は同じ範囲へ繰り返し戻り、Motionの分類可能時間もstationary優勢である。ほかの長距離6区間は一方向への進行率が約0.56以上であり、同じ特徴を持たない。

根本原因は、現行のMovement確定条件が「2点以上かつ累積100m以上」だけであること。500m以下の水平精度を持つ低速なドリフトはSanitizerを通り、往復するたび距離が加算されるため、停止中でもMovementへ昇格する。水平精度上限を一律に厳しくするとSignificant Location Changeの実移動を失うため採用しない。

## Goal

低速、低進行率、stationary優勢を同時に満たす候補だけをGPSドリフトとして破棄し、実移動、徒歩、往復経路を単一条件で消さない。

## Non-Goals

- Raw Location、Motion、Visitの変更または削除
- 水平精度500m、最大Gap 90分、最小距離100mの変更
- Location取得Mode、Map描画、SwiftData V1 Schemaの変更
- 実機座標または実経路のTest Fixture化

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `issues/14-1-polyline-diagnostics-and-quality.md`
- [x] `issues/15-9-open-visit-route-recovery.md`

## Dependencies

- `LocationSanitizer`
- `MovementSegmenter`
- Processing Algorithm Version invalidation

## Scope

### Allowed Changes

- `issues/15-15-stationary-gps-drift.md`
- `docs/processing-rules.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/Processing/Configuration/ProcessingConfiguration.swift`
- `DriveLog/DriveLog/Processing/Segmentation/MovementSegmenter.swift`
- `DriveLog/DriveLog/Processing/Segmentation/MovementSegmentationTypes.swift`
- `DriveLog/DriveLog/Processing/Segmentation/StationaryDriftDetector.swift`
- `DriveLog/DriveLog/Processing/Location/LocationProcessingDiagnostics.swift`
- `DriveLog/DriveLog/Application/Processing/ProcessingAlgorithmMigrator.swift`
- `DriveLog/DriveLogTests/Processing/ProcessingConfigurationTests.swift`
- `DriveLog/DriveLogTests/Processing/MovementSegmenterTests.swift`
- `DriveLog/DriveLogTests/Processing/StationaryDriftDetectorTests.swift`
- `DriveLog/DriveLogTests/Processing/StationaryDriftSegmenterTests.swift`
- `DriveLog/DriveLogTests/Processing/LocationProcessingDiagnosticsTests.swift`
- `DriveLog/DriveLogTests/Application/ProcessingAlgorithmMigratorTests.swift`

### Forbidden Changes

- SwiftData V1 Schema、Raw Event、Repository、Override
- Platform Location/Motion/Visit取得
- UI、MapKit、PhotoKit
- Signing、Team、Bundle Identifier、Capability
- 外部Package

## Decision

候補をGPSドリフトとして破棄するのは、次のすべてを満たす場合だけとする。

1. 候補時間が5分以上
2. 累積距離÷候補時間が0.5m/s以下
3. 始点からの最大距離÷累積距離が0.4以下
4. 時系列上の最新Motion snapshotを次snapshotまで有効として評価した分類可能Evidenceが3分以上
5. 分類可能Evidence時間のうち、travel flagを持たないstationaryの比率が60%以上

automotive、walking、running、cyclingのいずれかとstationaryが同時に立つsnapshotは、実移動を保護するためtravelを優先する。Motion snapshotの`endDate == nil`は候補終了まで無制限に重ねず、次のsnapshotで置き換える。水平精度だけ、累積距離だけ、平均速度だけでは破棄しない。

閾値は`ProcessingConfiguration`へ集約する。派生データのAlgorithm Versionを4へ上げ、既存Raw Eventを変更せず完了日を一度だけ再処理対象へ戻す。

## Requirements

1. 既存の2点・100m条件を満たしても、Decisionの全条件を満たす候補はMovementへ確定しない。
2. 低速でも一方向へ進む経路、Motionがwalkingを支持する往復経路、Motion Evidence不足の経路は維持する。
3. `endDate == nil`のMotion snapshotは次snapshotまでの状態として扱い、過去状態を重複占有させない。
4. GPSドリフト破棄件数をPrivacy安全な診断値へ追加する。
5. Raw EventとSwiftData Schemaを変更しない。
6. Algorithm Versionを4へ上げ、既存完了日を再処理対象にする。
7. 実機データは読み取り専用監査だけに使用し、座標、経路、IdentifierをIssue、Test、Loggerへ転記しない。

## Input

- Sanitizer採用済みLocation
- 同日のMotion Event
- `ProcessingConfiguration`

## Output

- 確定Movement
- 最小条件またはstationary drift条件で破棄された候補
- stationary drift破棄件数を含むLocation Processing診断

## State Changes

- SwiftData Schema変更なし。
- 完了済み日をAlgorithm Version 4で一度だけpendingへ戻し、既存Foreground/Background処理で派生データを置換する。

## Error Handling

- Motion Evidenceが不足または矛盾する場合は候補を維持する保守的なFallbackとする。
- 不正な0秒時間、0m距離ではstationary drift判定を行わない。

## Privacy Requirements

- 正確な時刻、緯度、経度、経路、Media IdentifierをLoggerへ出力しない。
- 診断値は件数、固定bucket、固定reasonだけとする。
- 外部通信を追加しない。

## UI Requirements

- なし。

## Accessibility Requirements

- なし。

## Processing Rules

- Sanitizer後、Movement候補確定時にstationary drift複合判定を適用する。
- 判定順序は最小点数・距離条件、候補時間、平均進行速度、進行率、Motion Evidenceとする。
- 1条件でも満たさなければMovementを維持する。

## Data Model Rules

- SwiftData V1 Schemaを変更しない。
- Raw Location、Motion、Visitを変更または削除しない。

## Interface Contract

既存の`MovementSegmenting.segment(locations:motions:visits:)`を維持する。新しいDetectorはProcessing内部の値型とする。

## Implementation Constraints

- ProcessingはFoundation以外のApple Frameworkをimportしない。
- 閾値を`ProcessingConfiguration`以外へハードコードしない。
- `fatalError()`、`try!`、`as!`、`print()`を追加しない。
- 新規Warning、未完成TODOを残さない。

## Acceptance Criteria

- [x] 合成した停止中ドリフト候補が破棄される。
- [x] 同じ累積距離でも一方向へ進む低速経路が維持される。
- [x] walking/automotive Evidenceのある往復経路が維持される。
- [x] Motion Evidence不足時は経路が維持される。
- [x] GPSドリフト破棄件数を座標なしで診断できる。
- [x] Algorithm Versionが4になる。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Source Warningと仕様外変更がない。

## Test Requirements

### Unit Tests

- [x] 5分、0.5m/s、0.4、3分、60%の各境界値。
- [x] 1条件だけ外れる候補をそれぞれ維持する。
- [x] travelとstationary競合時にtravelを優先する。
- [x] nil endDateのsnapshotが次snapshotで置換される。
- [x] Segmenterがdrift候補をdiscardedへ移し通常Movementを維持する。
- [x] Diagnosticsがstationary drift破棄件数を保持する。

### Integration Tests

- 既存Processing Pipeline Testを回帰実行する。

### UI Tests

- UI変更なし。既存主要導線を回帰実行する。

### Manual Tests

- 実機へVersion 4をInstall/Launchし、7月17日が再処理され、停止中の約1.28km区間だけが消え、ほかの経路が維持されることを確認する。

## Test Fixtures

- 実機座標を使用せず、原点周辺の架空座標で「同一範囲を往復」「一方向進行」「walking付き往復」を生成する。

## Verification Commands

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Completion Report Format

- Summary
- Root Cause and Evidence
- Decision
- Changed Files
- Tests Added
- Verification
- Device Data Audit
- Manual Verification
- Deviations
- Unresolved Issues

## Completion Report

### Summary

停止中GPSドリフトを、Movement候補の複合判定で除外する処理を追加した。Raw Location、Motion、Visit、SwiftData V1 Schema、取得Modeは変更していない。Algorithm Versionを4へ更新し、既存の完了日を再処理対象へ戻す。

### Root Cause and Evidence

読み取り専用の実機Storeを座標なしで監査した。7月17日はRaw Location 69件、Sanitizer採用64件、既存Movement 7件だった。誤判定区間は約94分、累積約1.28km、平均約0.23m/sで、始点からの進行率が約3割、分類可能Motion Evidenceはstationary優勢だった。水平精度は採用範囲内だったため、accuracy閾値や重複除去が原因ではなく、旧来の「2点以上かつ100m以上」だけの確定条件が原因だった。30m簡略化の対象点数にも達していなかった。

### Decision

候補時間5分以上、平均進行速度0.5m/s以下、始点からの最大距離/累積距離0.4以下、分類可能Evidence 3分以上、stationary比率60%以上の全条件を満たす候補だけを破棄する。travel flagとstationaryが競合する場合はtravelを優先し、Motion Evidence不足は保守的に維持する。閾値は`ProcessingConfiguration`へ集約した。

### Changed Files

- Processing Configuration: stationary drift閾値を追加。
- Movement Segmenter / Stationary Drift Detector: Motion snapshotの時系列評価と複合判定を追加。
- Movement Segmentation Types / Location Diagnostics: 破棄件数を保持。
- Processing Algorithm Migrator: Version 4へ更新。
- Tests: 境界値、各条件の保守的Fallback、Motion競合、Segmenter、Diagnosticsを追加。
- Processing/Test Plan: 判定規則と回帰項目を文書化。

### Tests Added

Stationary drift専用のSwift Testingを8件追加し、既存Processing/SwiftData/UI Testを回帰実行した。

### Verification

- `./scripts/build.sh`: 成功。
- `./scripts/test.sh`: 成功。Swift Testing 416件、UI Test 14件、失敗0。
- `swiftlint lint --strict`: 成功。違反0。
- `swiftformat --lint .`: 成功。変更要求0。
- `git diff --check`: 成功。
- 対象専用テスト: 25件、3 Suite、成功。

### Device Data Audit

実機Storeの読み取り専用複製から件数、精度bucket、時間間隔、距離、速度、Motion分類比率だけを確認した。座標、経路、IdentifierはIssue、Test Fixture、Loggerへ転記していない。再処理後は誤判定区間だけが除外され、他の6 Movementを維持する想定である。

### Manual Verification

実機は現在未接続のため、Version 4をインストールした端末上で7月17日が再処理され、Movementが6区間になることは未確認。Algorithm更新時は一度に全履歴を処理せず、Foreground/Backgroundの既存制限に従って順次再処理される。

### Deviations

初回全体TestではSimulatorのAccessibility重複・起動競合によりUI 3件が一時失敗した。Simulatorを再起動して再実行し、全体Testは成功した。残るAppIntents metadata、CoreLocation main-thread、Simulator Accessibility/MetalのWarningは環境由来で、新規Source Warningではない。

### Unresolved Issues

実機での再処理結果と、停止中の誤Movementが表示から消え、他の経路が維持されることの確認が必要。診断値は`DayProcessingResult`内で保持されるが、永続化やOSLog出力はこのIssueのAllowed Changes外である。

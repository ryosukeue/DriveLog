# [Location] 充電中Location Modeを定期照合する

## Summary

充電しながら走行しても`chargingHighAccuracy`へ切り替わらず、Significant Location Changeだけが記録された実機問題を修正する。

## Goal

Battery通知の取り逃しや一時的なMode切替失敗があっても、現在のPower stateを再照合して充電中高精度Modeへ自己修復する。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `issues/14-2-charging-location-mode.md`

## Allowed Changes

- `issues/15-13-charging-mode-reconciliation.md`
- `docs/requirements.md`
- `docs/architecture.md`
- `docs/interfaces.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/Platform/Power/SystemPowerStateProvider.swift`
- `DriveLog/DriveLog/Application/Monitoring/StartMonitoringUseCase.swift`
- `DriveLog/DriveLog/Shared/Logging/LogEvent.swift`
- `DriveLog/DriveLog/Shared/Logging/OSLogLogger.swift`
- `DriveLog/DriveLogTests/Platform/SystemPowerStateProviderTests.swift`
- `DriveLog/DriveLogTests/Application/StartMonitoringUseCaseTests.swift`
- `DriveLog/DriveLogTests/Shared/Logging/LoggingTests.swift`

## Forbidden Changes

- 常時高精度GPS
- 複数Location Manager/Provider
- SwiftData Schema、Raw Location、Processing閾値
- Signing、Team、Bundle Identifier、Capability、Info.plist
- 外部Package

## Investigation

- 高精度ModeのCore Location設定はBest accuracy、50m distance filter、automotive navigation、自動Pause無効、Background Locationとなっている。
- Power stateは起動/Foreground時の1回の読み取りと`batteryStateDidChangeNotification`だけで更新していた。
- 通知を取り逃した場合、または状態が`unknown`の間に初期化された場合、現在状態を再確認する経路がなかった。
- Mode切替が一時的に失敗した場合も、次のBattery通知まで再試行されなかった。
- 既存ログには選択Modeはあるが、OSから観測したPower stateがなく、実機で「充電判定」と「Mode切替」を分離できなかった。
- 7月17日のOSLogはRepositoryへ保存されておらず、端末も未接続のため、実データからBattery state値そのものは確認できない。上記はコード経路と実機症状からの原因推定である。

## Decision

Battery通知は即時反映に使い続け、`SystemPowerStateProvider`から30秒ごとにも現在状態のSnapshotを流す。Applicationは同じModeが正常動作中ならno-opとし、一時失敗時だけ同じPower stateのSnapshotで再試行する。重複した失敗ログは抑制し、状態または失敗理由が変わった場合だけ再記録する。

公開APIで物理的なCable接続を直接判定せず、従来どおり`UIDevice.BatteryState.charging/full`を高精度条件とする。充電最適化、熱、電源不足等によりOSが`unplugged/unknown`を返す場合はlow powerとなる。この値をPrivacy-safeに記録し、実機監査可能にする。

## Requirements

1. Power state Streamは初期Snapshotを流す。
2. Battery state変更通知を即時に流す。
3. 通知欠落のFallbackとして30秒ごとに現在状態を流す。
4. charging/fullだけを`chargingHighAccuracy`とする。
5. unplugged/unknownは`lowPower`を維持する。
6. 正常動作中に同じSnapshotを受けてもLocation Modeを再起動しない。
7. Mode切替失敗後は同じPower stateでも再試行する。
8. 同一の失敗診断を繰り返し出力しない。
9. 観測Power stateを座標、時刻、Battery残量なしの固定Codeで記録する。
10. BackgroundでTimerが正確に動くことは保証しない。SLC等でProcessが実行可能になった際に照合を再開する。

## Acceptance Criteria

- [x] 初期、通知、定期照合のPower state Snapshotを受信できる。
- [x] missed notification相当の定期Snapshotでhigh accuracyへ切り替わる。
- [x] 一時失敗後、次のSnapshotでhigh accuracyを再試行できる。
- [x] 成功中の同一SnapshotでProviderを重複起動しない。
- [x] Power state、Mode、取得/emit、保存結果をPrivacy-safeに追跡できる。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Completion Report Format

- Summary
- Root Cause
- State Reconciliation
- Changed Files
- Tests Added
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion Report

### Summary

Battery state変更通知だけに依存していたMode選択へ、初期Snapshotと30秒ごとの定期照合を追加した。`charging`または`full`が観測されると、同じLocation Providerを`chargingHighAccuracy`へ切り替える。正常稼働中の同一Snapshotはno-opとし、切替失敗後の同一Snapshotは再試行する。

### Root Cause

Power stateの更新契機が起動/Foreground時の読み取りとBattery通知だけだったため、初期値が`unknown`の間に初期化された場合、通知を取り逃した場合、またはMode切替が一時失敗した場合に、Significant Location Changeから高精度Modeへ自己復旧できなかった。

7月17日の端末OSLogはRepositoryへ保存されておらず、端末も未接続だったため、その走行時にiOSが返したBattery state値は確認できていない。今回の原因は、実機症状と再現可能なコード経路に基づく。

### State Reconciliation

- Stream開始時に現在のPower stateを1回流す。
- Battery通知は従来どおり即時反映する。
- 30秒ごとに現在状態を再送し、通知欠落と一時失敗を回復する。
- 正常稼働中はModeを再起動せず、失敗中だけ再試行する。
- Power state変更、Location Mode変更/失敗、Location受信/emit、保存/棄却を固定Codeと件数だけで追跡する。

### Changed Files

- `SystemPowerStateProvider.swift`: 初期・通知・定期SnapshotとTaskの終了処理。
- `StartMonitoringUseCase.swift`: 状態変更診断、切替再試行、重複失敗ログ抑制。
- `LogEvent.swift`、`OSLogLogger.swift`: Privacy-safeなPower state診断。
- `SystemPowerStateProviderTests.swift`、`StartMonitoringUseCaseTests.swift`、`LoggingTests.swift`: 回帰Test。
- `docs/requirements.md`、`docs/architecture.md`、`docs/interfaces.md`、`docs/test-plan.md`: 自己修復契約と実機確認項目。

### Tests Added

- 初期Snapshotと定期Snapshot。
- Battery通知Snapshot。
- 同一の充電状態を再受信した際の失敗再試行、重複失敗ログ抑制、最終成功。
- Power state LogEventの等価性と非等価性。

### Verification

- `./scripts/build.sh`: 成功。
- `./scripts/test.sh`: 成功。Swift Testing 407 tests / 88 suites、UI Test 13 tests、失敗0。
- `swiftlint lint --strict`: 成功。264 files、違反0。
- `swiftformat --lint .`: 成功。変更要求0。
- `git diff --check`: 成功。
- Allowed Changes監査: 対象外変更なし。

### Manual Verification

端末が未接続のため、実機の充電開始、Background走行、約1分間隔保存、抜線後のlow power復帰は未実施。

### Deviations

なし。

### Unresolved Issues

- iOSはBackgroundで30秒ごとのTask実行を保証しない。Processが実行可能になった時点で照合が再開される。
- 物理的なCable接続ではなく、公開APIの`UIDevice.BatteryState`を判定源とする。車載電源の不足、熱、充電制御等によりiOSが`unplugged`または`unknown`を返す場合は、Batteryを優先してlow powerを維持する。
- 上記2点と実走行時の約1分間隔保存は実機で確認する。

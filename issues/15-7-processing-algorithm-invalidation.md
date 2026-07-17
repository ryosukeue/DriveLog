# [Processing] Algorithm更新時に既存日を再処理する

## Summary

Processing Algorithmの互換性Versionが上がったとき、既存Raw Eventを保持したまま派生データの日を1回だけ再処理待ちへ戻す。

## Background

Issue 15-6でMovement分割を修正しても、`rawRevision == processedRevision`の日は既存派生データを返すため、過去日の表示へ新Algorithmが反映されない。実機の2026-07-15もIssue 15-5で完了世代へ戻ったため、明示的なAlgorithm更新Invalidationが必要である。

SwiftData V1 SchemaにはAlgorithm Version列がないためSchemaは変更せず、端末内Preferenceへ現在Versionを保持する。Version更新時は完了済み処理状態の`processedRevision`だけを1世代戻してpendingにし、Raw Eventと現在表示中の派生データは再処理成功まで保持する。

## Goal

Algorithm更新後の最初のLaunchで既存日を再処理対象にし、中断されても次回再開できる状態を永続化する。

## Non-Goals

- SwiftData V1 Schema変更
- Raw Eventまたは既存派生データの先行削除
- 1回のLaunchで全履歴を同期処理すること
- UI変更

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/test-plan.md`
- [x] `issues/15-5-interrupted-day-reprocessing.md`
- [x] `issues/15-6-visit-route-partition.md`

## Dependencies

- Foreground fallback
- `DayProcessingGate`
- 日付単位の派生データ原子的置換

## Scope

### Allowed Changes

- `issues/15-7-processing-algorithm-invalidation.md`
- `docs/architecture.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/Application/AppLifecycleCoordinator.swift`
- `DriveLog/DriveLog/Application/Processing/ProcessingAlgorithmMigrator.swift`
- `DriveLog/DriveLog/Data/Repositories/ProcessingStateRepository.swift`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+ProcessingState.swift`
- `DriveLog/DriveLogTests/Application/AppLifecycleCoordinatorTests.swift`
- `DriveLog/DriveLogTests/Application/ProcessingAlgorithmMigratorTests.swift`
- `DriveLog/DriveLogTests/Data/ProcessingStateRepositoryIntegrationTests.swift`

### Forbidden Changes

- SwiftData Schema、Raw Event、Override、派生Model構造
- Processing閾値、Movement分割、UI、Location取得
- Signing、Bundle Identifier、外部Package

## Decision

現在のAlgorithm Versionを`2`とし、UserDefaults key `processingAlgorithmVersion`へ保存する。保存Versionが小さい場合だけ、`rawRevision > 0`かつ完了世代の`processedRevision`を1世代戻し`pending`へ変更する。既に未完了の日は変更しない。Invalidation保存後にVersionを更新し、日別再処理は既存Foreground/Background処理へ委ねる。

Schema列を増やさない代償として、再処理待ちの間は`processedRevision`が直前世代を表す。これは既存の`rawRevision > processedRevision`契約に沿い、再処理成功時に同じrawRevisionへ戻る。

## Requirements

1. 保存Versionが現在Version未満のときだけInvalidationする。
2. 完了済みでRaw Eventを持つ日をpendingへ戻す。
3. 既にpending/processing/failedの未完了日は変更しない。
4. Raw Eventと派生データをInvalidation時に削除しない。
5. Invalidation失敗時はVersionを更新せず次回再試行する。
6. Launch時にInvalidationしてからForeground fallbackを実行する。
7. 同じVersionでは再度Invalidationしない。
8. 1回のForeground処理件数制限を維持する。

## Privacy Requirements

- 日付、座標、経路、Media IdentifierをPreferenceやLoggerへ保存しない。
- Version整数だけをUserDefaultsへ保存する。
- 外部通信を追加しない。

## Processing Rules

- Invalidation後も既存派生データを表示可能に保ち、日付単位の再処理成功時だけ置換する。
- 中断時はpending/processing回復規則で再開する。

## Data Model Rules

- SwiftData V1 Schemaは変更しない。
- `DayProcessingStateModel`の既存世代と状態だけを更新する。

## Acceptance Criteria

- [x] Version更新時に完了日がpendingになる。
- [x] 同Versionでは再Invalidationしない。
- [x] 失敗時は次回再試行できる。
- [x] 既存Raw/派生データを削除しない。
- [x] 実機で7/15が新Algorithmにより再生成される。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`
- 実機Build/Install/Launch後、Storeを読み取り専用複製して7/15のMovement時刻を確認する。

## Completion Report Format

- Summary
- Decision
- Changed Files
- Tests Added
- Verification
- Device Verification
- Deviations
- Unresolved Issues

## Completion Report

### Summary

Processing Algorithm Versionを端末Preferenceへ保存し、Version更新時に完了済みの日をRaw Eventと既存派生データを保持したまま再処理待ちへ戻す仕組みを追加した。LaunchではInvalidation完了後に既存Foreground fallbackを実行する。

### Decision

SwiftData V1 Schemaを変更せず、Version `2`を`processingAlgorithmVersion`へ保存する。Invalidationに失敗した場合はVersionを更新せず、次回Launchで再試行する。

### Changed Files

- Application: Algorithm Version Store、Migrator、Launch順序、DIを追加。
- Data: 完了済みProcessing Stateの一括Invalidationを追加。
- Tests: Version更新、再実行防止、失敗時再試行、State選別、Launch順序を追加。
- Docs: Algorithm更新時の再処理契約と検証方針を追記。

### Tests Added

- Migratorが旧Versionを1回だけInvalidationするTest。
- Invalidation失敗時に旧Versionを保持するTest。
- 完了済みStateだけをpendingへ戻し、未完了Stateを維持するIntegration Test。
- Launch時だけMigratorを実行するLifecycle Test。

### Verification

- Simulator Build: 成功。
- Unit/Integration Test: 398件成功。
- UI Test: 13件成功。
- SwiftLint strict: 0 violations。
- SwiftFormat lint: 0 files require formatting。
- `git diff --check`: 成功。
- 実機向け署名BuildとInstall: 成功。

### Device Verification

接続中のiPhone 15へのInstallとLaunchに成功した。再処理後Storeの読み取り専用複製では7/15が`rawRevision 989 / processedRevision 989 / completed`となり、20:49:11開始のMovementは20:59:13で終了した。20:59:07開始のStayを完全に包含するMovementは0件であり、後続Movementも21:33:26以降へ分割された。

### Deviations

最初の自動Launchは端末ロックにより拒否されたため、Unlock後に再実行した。実機データはStoreの読み取り専用複製で件数・時刻・世代だけを確認し、FixtureやRepositoryへコピーしていない。

### Unresolved Issues

なし。

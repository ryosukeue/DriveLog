# [Processing] 車移動フィルタ変更後に保存済み日付を再処理する

## Summary

Issue 16-4で車移動Fallback境界を見直したため、すでに完了済みとして保存されている日付にも新しい分類条件を適用する。SwiftData V1のSchemaやRaw Eventは変更せず、既存の処理アルゴリズムVersionを更新して派生データだけを安全に再生成する。

## Goal

車移動フィルタ境界の変更を、次回起動時に過去の保存済みログへ反映し、16日以外の日付でも再処理後の車Polylineと月間集計が表示される状態にする。

## Non-Goals

- Raw Location、Motion、Visitの削除・書換え
- SwiftData V1 Schema、Migration、永続化形式の変更
- 新しい分類条件、UI、Location取得方式の追加

## Required Documents

実装前に次を読むこと。

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`
- [x] `issues/16-4-automotive-filter-boundary.md`
- [x] `issues/3-10-movement-classifier.md`

## Dependencies

- `DefaultProcessingAlgorithmMigrator`
- `ProcessingStateInvalidating`
- `ProcessingAlgorithmMigratorTests`
- Issue 16-4の`ProcessingConfiguration.mvp`

## Scope

### Allowed Changes

- `issues/16-5-reprocess-after-automotive-boundary.md`
- `DriveLog/DriveLog/Application/Processing/ProcessingAlgorithmMigrator.swift`
- `DriveLog/DriveLogTests/Application/ProcessingAlgorithmMigratorTests.swift`

### Forbidden Changes

- Raw Event、Photos Asset、SwiftData V1 Model、Schema、Migrationの変更
- `ProcessingConfiguration`、`MovementClassifier`、`AutomotiveMovementFilter`の追加変更
- Location Provider、充電Mode、Map描画、Calendar／Day Detail UIの変更
- Signing、Team、Bundle Identifier、Capability、外部Package
- 座標、経路、PhotoKit localIdentifier、写真・動画名の通常ログ出力

## Decision

`DefaultProcessingAlgorithmMigrator.currentVersion`を4から5へ更新する。アプリ起動時に保存Versionが5未満なら、既存のProcessing Stateだけを未処理へ戻し、次のProcessing CoordinatorがRaw Eventから派生データを再生成する。再処理に失敗した場合はVersionを書き換えず、次回起動で再試行する既存設計を維持する。Schema MigrationやRaw Event削除は行わない。

## Requirements

1. 現在のアルゴリズムVersionを5とする。
2. 保存Versionが4以下の場合、既存の`invalidateProcessedDaysForAlgorithmUpdate()`を1回呼ぶ。
3. 無効化成功後だけ保存Versionを5へ更新する。
4. 保存Versionが5以上の場合、再処理を実行しない。
5. 無効化失敗時は保存Versionを更新せず、次回起動で再試行可能にする。
6. Raw Event、Override、SwiftData V1 Schemaを変更しない。
7. Swift TestingでVersion未満・同値・失敗時の再試行を確認する。
8. `fatalError()`、`try!`、`as!`、`print()`、`debugPrint()`、`NSLog()`を使用しない。

## State Changes

- Processing Stateの`processedRevision`を既存Invalidatorの責務で未処理へ戻す。
- Raw EventとOverrideは変更しない。
- UserDefaultsの`processingAlgorithmVersion`を成功時だけ5へ更新する。

## Error Handling

- Invalidatorが失敗した場合はVersionを更新せず、既存の無言Retry設計を維持する。
- 起動処理をクラッシュさせず、次回起動で再処理を試みる。

## Privacy Requirements

- 座標、経路、PhotoKit localIdentifier、写真・動画名をLoggerへ出力しない。
- 外部Server、Analytics SDK、外部Packageを追加しない。

## Acceptance Criteria

- [x] Version 4の保存状態で起動するとProcessing Stateが再処理対象になる。
- [x] 再処理無効化成功後にVersion 5が保存される。
- [x] Version 5以上では再処理されない。
- [x] 無効化失敗時はVersionが更新されず、再試行できる。
- [x] Schema、Raw Event、Override、UIに仕様外の変更がない。
- [x] Build、Test、SwiftLint、SwiftFormat、`git diff --check`が成功する。

## Completion Report Format

### Summary

車移動Fallback境界変更後の既存ログを、起動時のアルゴリズムVersion更新で安全に再処理可能にする。

### Changed Files

- `ProcessingAlgorithmMigrator.swift`: Version 5と既存Invalidatorの再利用。
- `ProcessingAlgorithmMigratorTests.swift`: Version更新・Skip・失敗時Retryの検証。

### Tests Added

Version未満、Version同値以上、Invalidator失敗時のSwift Testingを確認する。

### Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

### Manual Verification

実機で次回起動後に対象日付が再処理され、車Polylineと月間集計へ反映されることを確認する。

### Deviations

なし。

### Unresolved Issues

アプリを強制終了している間は再処理が進まず、次回起動後のBackground実行タイミングはiOS制約に依存する。

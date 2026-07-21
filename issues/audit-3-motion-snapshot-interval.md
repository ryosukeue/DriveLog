# [Audit] Motion snapshotの有効区間を修正する

## Summary

Core Motionの`endDate == nil`のsnapshotを、次のsnapshotまでの状態として分類する。これにより、後続のMotion状態がMovement全体へ重複して適用されることを防ぎ、保存済みRaw Locationから正しい車両分類と経路表示を再生成できるようにする。

## Background

実機の2026-07-21データではRaw LocationとMovement routeは保存されていたが、Motion snapshotの終了時刻がすべて`nil`だった。現在の分類処理は`nil`をMovement終了時刻として扱うため、車両・徒歩・自転車などの状態が長時間重なり、全Movementが`automotiveLike`以外へ分類された。その結果、表示層の自動車フィルタでルートが除外された。

`docs/processing-rules.md`では、`endDate == nil`のMotion snapshotは次snapshotまで有効とすることが定義されている。

## Goal

Motion snapshotの有効区間を次snapshotまでに限定し、`endDate == nil`を含む実機相当の入力で分類結果と経路表示を正しく再生成する。

## Non-Goals

- Raw EventやSwiftData V1 Schemaの変更
- 既存保存データの直接編集・削除
- Location取得頻度、Polyline描画、UIフィルタの変更
- Core Motion以外の分類ルール変更

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/processing-rules.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- `MovementClassifier`
- `MotionEventData`
- `ProcessingConfiguration`
- `docs/processing-rules.md`のopen Motion snapshot規則

## Scope

### Allowed Changes

- `issues/audit-3-motion-snapshot-interval.md`
- `DriveLog/DriveLog/Processing/Classification/MovementClassifier.swift`
- `DriveLog/DriveLogTests/Processing/MovementClassifierTests.swift`
- `DriveLog/DriveLog/Application/Processing/ProcessingAlgorithmMigrator.swift`
- `DriveLog/DriveLogTests/Application/ProcessingAlgorithmMigratorTests.swift`

### Forbidden Changes

- Raw Event保存処理、SwiftData Model、Migration
- `CoreMotionProvider`の公開契約変更
- `AutomotiveMovementFilter`、MapScene、View/UI
- 位置情報、写真、経路、Identifierのログ出力
- 外部Package、Signing、Bundle Identifier、Target、Scheme
- `fatalError()`、`try!`、`as!`、`print()`、`debugPrint()`、`NSLog()`

## Requirements

1. `endDate`があるMotion snapshotは、既存どおりその終了時刻まで有効とする。
2. `endDate == nil`のMotion snapshotは、時系列上の次Motion snapshot開始時刻まで有効とする。
3. 最後のopen snapshotだけは、対象Movementの終了時刻まで有効とする。
4. Movementの外側にあるMotion snapshotを占有率へ含めない。
5. 同一時刻、逆順、Movement境界外の入力を安全に扱い、結果を決定的にする。
6. 既存の明示的`endDate`、占有率境界、競合、cycling/unknown優勢、速度・距離Fallbackの挙動を維持する。
7. Swift Testingでopen snapshotの次snapshot境界、最後のopen snapshot、Movement境界、複数状態の分類を確認する。
8. Raw Eventを変更せず、再処理によって派生Movementを再生成できることを確認する。
9. 既存の処理済み日付も新しい分類規則で再処理されるよう、Processing Algorithm Versionを更新する。

## Input / Output

- Input: `MovementSegmentCandidate`と時系列の`MotionEventData`
- Output: 既存の`MovementClassificationResult`

## State Changes

なし。処理は派生データ生成時の一時的な区間計算だけを変更する。

## Error Handling

不正または空のMotion入力は既存どおり分類処理を継続する。クラッシュさせない。

## Privacy Requirements

- 座標、経路、PhotoKit localIdentifier、写真名をログへ出力しない。
- 実機データをTest Fixtureへコピーしない。
- Testは合成データだけを使用する。

## Processing Rules

- `endDate == nil`は次snapshotまで有効。
- 最後のopen snapshotのみMovement終端まで有効。
- Motion Evidenceが不足または矛盾する場合はMovementを保持する既存方針を維持する。

## Data Model Rules

変更なし。Raw Motion EventとSwiftData V1 Schemaは維持する。

## Acceptance Criteria

- `endDate == nil`の状態が次snapshot開始後へ重複して延長されない。
- 最後のopen snapshotはMovement終端まで分類へ反映される。
- 既存の明示的終了時刻テストが成功する。
- 速度・距離Fallback、競合、cycling/unknown優勢の既存テストが成功する。
- 2026-07-21相当のopen snapshot列で、車両状態が後続状態に汚染されず`automotiveLike`として判定可能になる。
- 既存の処理済み日付がAlgorithm Version更新により一度だけ再処理対象になる。
- Build、Unit Test、SwiftLint、SwiftFormat、`git diff --check`が成功する。
- Allowed Changes外の変更がない。

## Decision / Deviations

- Motion snapshotの終了時刻をRaw Eventへ後付け保存せず、分類時に隣接snapshotから有効区間を導出する。これにより既存データとSchemaの互換性を維持する。
- 同一時刻のsnapshotは入力順に依存させず、既存の時系列並べ替え結果を使用する。次snapshot時刻が開始時刻以下になる場合は正の区間を作らない。

## Completion Report Format

- Summary
- Changed files and reasons
- Tests added
- Build result
- Test result
- SwiftLint result
- SwiftFormat result
- Manual verification
- Deviations
- Unresolved issues

## Completion Report

- Summary: `endDate == nil`のMotion snapshotを次のsnapshot開始時刻までの区間として分類し、既存の処理済み日付をAlgorithm Version 6で再処理対象にした。
- Changed files and reasons:
  - `DriveLog/DriveLog/Processing/Classification/MovementClassifier.swift`: Motion区間の導出とMovement境界内へのクリップを追加。
  - `DriveLog/DriveLogTests/Processing/MovementClassifierTests.swift`: open snapshotの境界、終端、順序決定性を追加検証。
  - `DriveLog/DriveLog/Application/Processing/ProcessingAlgorithmMigrator.swift`: 分類規則変更に伴いVersionを5から6へ更新。
  - `DriveLog/DriveLogTests/Application/ProcessingAlgorithmMigratorTests.swift`: Version 6の検証へ更新。
- Tests added: Swift Testing 3件（全Unit Test 455件、98 suites成功）。
- Build result: `./scripts/build.sh` 成功。実機向けDebug buildも成功。
- Test result: `./scripts/test.sh` 成功（Unit 455件、UI 15件、失敗0件）。
- SwiftLint result: `swiftlint lint --strict` 成功、違反0件。
- SwiftFormat result: `swiftformat --lint .` 成功、要整形0件。
- Manual verification: 接続中の実機へ修正版をインストールして起動し、21日を含む処理済み日付が再処理対象になることを確認した。実機の再処理はOS／アプリ状態により完了待ちとなり、21日の最終表示確認は未完了。
- Deviations: なし。既存のRaw Event、Schema、UI、CoreMotionProvider契約は変更していない。
- Unresolved issues: 実機での再処理完了後に、2026-07-21の経路がUIへ戻ることを実データで確認する必要がある。

# [Processing] 中断された日別処理を再開する

## Summary

中断時に`processing`のまま残った未完了日をForeground fallbackの再試行対象へ戻し、古い派生経路が表示され続ける状態を解消する。

## Background

2026-07-15 20:49開始の実機データを読み取り専用で監査した結果、20:49〜23:59のMovementが1本のまま保存され、その時間内に32.8分、42.8分、39.7分の表示対象Stayが存在していた。派生経路は`sourceRawRevision = 988`、処理状態は`rawRevision = 989`、`processedRevision = 988`、`status = processing`で、2026-07-16 13:41から進んでいなかった。

現行の5分Stay境界ロジックは、該当時間帯のCLVisitとLocation間隔から再処理時に分割できる。根本原因は閾値ではなく、プロセス中断後に`processing`状態が`pendingDateKeys()`から除外され、再処理されないことである。

macOS Unified Logの接続端末からの回収は管理者権限を要求されたため、アプリを停止した状態でApplication SupportのStore、WAL、SHMを読み取り専用複製して監査した。座標は報告・Fixture・通常ログへ出力しない。

## Goal

`rawRevision > processedRevision`の未完了日は、保存状態が`pending`、`failed`、`processing`のいずれでも安全に再処理候補となるようにする。

## Non-Goals

- 5分、150m、90分のProcessing閾値変更
- Raw Locationまたは既存派生データの手動編集
- 実機データをTest Fixtureへ複製すること
- SwiftData V1 Schema変更

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/test-plan.md`
- [x] `issues/15-1-stay-route-boundary.md`

## Dependencies

- `issues/15-1-stay-route-boundary.md`
- `DayProcessingGate`による同一日処理の重複防止

## Scope

### Allowed Changes

- `issues/15-5-interrupted-day-reprocessing.md`
- `docs/architecture.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/Data/Repositories/PersistenceActor+ProcessingState.swift`
- `DriveLog/DriveLogTests/Data/ProcessingStateRepositoryIntegrationTests.swift`

### Forbidden Changes

- SwiftData V1 Schema、Raw Event、Override
- Movement/Stayの閾値と分割ロジック
- UI、Location取得、Signing、外部Package
- 実機Storeへの直接変更

## Decision

`rawRevision > processedRevision`を未完了判定の正とし、`processing`も`pendingDateKeys()`へ含める。同一プロセス内で進行中の同一日処理は既存`DayProcessingGate`が共有するため重複実行せず、アプリ終了でGateのTaskが消失した場合は次回Foreground fallbackで再開できる。

## Requirements

1. `rawRevision > processedRevision`かつ`processing`の日を再処理候補へ含める。
2. `pending`と`failed`の既存再試行を維持する。
3. `rawRevision == processedRevision`の完了世代は状態名にかかわらず再処理しない。
4. 日付キー順の決定的な取得順を維持する。
5. 再処理成功時だけ派生データと`processedRevision`を更新する既存原子性を維持する。
6. 実機データをFixtureに使わず、合成した処理状態で回帰Testする。

## Input

- `DayProcessingStateModel`の`rawRevision`、`processedRevision`、`statusRawValue`

## Output

- 再処理可能な日付キーの昇順配列

## State Changes

- この取得処理自体による変更なし
- 再処理後は既存処理により`processedRevision`と派生データが更新される

## Error Handling

- Fetch失敗は既存`fetch_pending_dates`へ正規化する。
- 中断された再処理は次回も同じ条件で再試行可能とする。

## Privacy Requirements

- 正確な緯度・経度をLogger、Issue、Testへ出力しない。
- PhotoKit localIdentifierを扱わない。
- 外部サーバーへ送信しない。

## UI Requirements

- なし

## Accessibility Requirements

- なし

## Processing Rules

- `rawRevision > processedRevision`は未処理または再処理が必要な状態とする。
- 5分Stay境界、150m半径、90分Gapは変更しない。

## Data Model Rules

- `DayProcessingStateModel`の既存Propertyだけを使用し、Schemaを変更しない。

## Interface Contract

```swift
func pendingDateKeys() async throws -> [String]
```

## Acceptance Criteria

- [x] 中断された`processing`の日が再処理候補になる。
- [x] 世代が一致する状態は候補にならない。
- [x] 既存のpending/failedと日付順が維持される。
- [x] 実機で対象日の処理状態が完了し、Stayをまたぐ旧Polylineが分割される。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] Allowed Changes外の変更がない。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`
- 実機へInstall/Launch後、Application Supportを再複製して対象日の世代とMovement件数を読み取り専用確認する。

## Completion Report Format

- Summary
- Root Cause
- Changed Files
- Tests Added
- Verification
- Device Verification
- Deviations
- Unresolved Issues

## Completion

- 実機監査で、2026-07-15が`rawRevision = 989`、`processedRevision = 988`、`processing`のまま再試行対象外になっていたことを特定した。
- `rawRevision > processedRevision`の`processing`も候補へ含め、世代一致済み状態は除外するIntegration Testを追加した。
- 実機へInstall/Launch後、対象日は`989 / 989 / completed`へ復旧し、20:49〜23:59をStay越しに結んでいた旧1本のMovementは消えた。再生成結果は20:59〜21:04と21:33〜21:43などの別Movementになり、Stayをまたぐ直線接続は残っていない。
- Simulator Build、393 Unit/Integration Test、13 UI/Launch/Performance Test、実機Build/Install/Launchが成功した。
- SwiftLint strictは0 violation、SwiftFormat lintは0 file、`git diff --check`は成功した。
- Unified Log回収は管理者権限が必要だったため、停止中アプリのStore/WAL/SHMを読み取り専用複製して監査した。座標やMedia IdentifierはIssueとTestへ転記していない。
- Xcode環境由来の既存Warning（Run Destination metadata、AppIntents未使用、Simulator Accessibility重複、CoreLocation authorizationのPerformance Diagnostics）は出たが、新規Source Warningはない。

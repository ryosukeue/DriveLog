# [Processing] 起動時の未処理日付を滞留させない

## Summary

実機Storeで複数日が`rawRevision > processedRevision`のまま残り、起動ごとに最古の1日しか再処理されないため、移動経路が復元されない状態を修正する。Foregroundの処理は既存のBackground上限と同じ最大3日へ拡張し、Raw EventとSchemaには触れない。

## Goal

アプリ起動・Foreground復帰時に未処理日付を最大3日ずつ処理し、数日分のログが一度の起動で滞留し続けないようにする。

## Required Documents

実装前に次を読むこと。

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`
- [x] `issues/16-5-reprocess-after-automotive-boundary.md`
- [x] `issues/11-2-background-processing.md`

## Dependencies

- `AppLifecycleCoordinator`
- `DayProcessingCoordinating`
- `BackgroundTaskCoordinator.defaultPendingDayLimit`

## Scope

### Allowed Changes

- `issues/16-6-process-pending-days.md`
- `DriveLog/DriveLog/Application/AppLifecycleCoordinator.swift`
- `DriveLog/DriveLogTests/Application/AppLifecycleCoordinatorTests.swift`

### Forbidden Changes

- Raw Event、Location Provider、充電Mode、Processing判定ロジックの変更
- SwiftData V1 Schema、Migration、Repository永続化形式の変更
- Background TaskのExpiration／Cancel契約の変更
- UI、Map描画、Media、Signing、Team、Bundle Identifier、Capability、外部Package
- 座標、経路、PhotoKit localIdentifier、写真・動画名のログ出力

## Decision

Foregroundの起動・復帰処理を固定値1日から最大3日へ変更する。3日は既存Background Taskの`defaultPendingDayLimit`と同じ上限であり、起動時の処理時間とBattery消費を制限しつつ、数日分の未処理を段階的に解消できる。日付順序、処理中の排他、失敗時の扱いは`DayProcessingCoordinator`へ委譲し、既存契約を変えない。

## Requirements

1. `handleLaunch()`とForeground復帰は未処理日付の処理上限3を渡す。
2. Background Taskの処理上限とExpiration挙動を変更しない。
3. 既存のPermission、Location、Motion、Visit開始処理を変更しない。
4. Unit TestでLaunch、Foreground復帰、起動失敗時の上限3を確認する。
5. `fatalError()`、`try!`、`as!`、`print()`、`debugPrint()`、`NSLog()`を使用しない。

## Acceptance Criteria

- [x] 起動時に最大3日分の未処理日付が処理対象になる。
- [x] Foreground復帰時も最大3日分を処理対象にする。
- [ ] 実機で7/16、7/17、7/18の滞留が段階的に解消される。
- [x] Background処理とExpiration挙動が変わらない。
- [x] Build、Test、SwiftLint、SwiftFormat、`git diff --check`が成功する。

## Privacy Requirements

- 座標、経路、PhotoKit localIdentifier、写真・動画名をLoggerへ出力しない。
- 外部Server、Analytics SDK、外部Packageを追加しない。

## Completion Report Format

### Summary

起動時の未処理日付処理上限を1日から3日へ変更し、複数日ログの再処理滞留を解消する。

### Changed Files

- `AppLifecycleCoordinator.swift`: Foreground処理上限を3へ変更。
- `AppLifecycleCoordinatorTests.swift`: 上限値の期待値を更新。

### Tests Added

Launch、Foreground復帰、起動失敗時の処理上限をSwift Testingで確認する。

### Verification

- `./scripts/build.sh`: 成功。
- `./scripts/test.sh`: 成功（Swift Testing 438件、UI Test 15件）。
- `swiftlint lint --strict`: 成功（0 violations）。
- `swiftformat --lint .`: 成功（0 files require formatting）。
- `git diff --check`: 成功。

### Manual Verification

旧ストアの整合性と経路Blobの存在はローカル保全コピーで確認済み。アプリ削除後の端末へ復元して未処理日付の`processedRevision`が追いつき、経路が表示されることは未確認。

### Deviations

端末アプリ削除により旧データContainerが失われたため、実機の滞留解消確認は旧ストア復元後に実施する。

### Unresolved Issues

現在進行中の日付は新しいRaw Eventが追加されるため、処理中にもRevision差が残る場合がある。次回ForegroundまたはBackgroundで再試行する。

# [Map] 連続する同一場所のStay表示を時系列で統合する

## Summary

同じ場所で連続して検出されたStayを、表示上だけ時系列にまとめて一つの滞在時間として示す。永続化されたStay、Stable ID、Stay Overrideは変更しない。

## Background

StayDetectorはMovement segmentationの各Gapを個別にStayへ変換する。そのため、同じ場所で位置イベントが複数回届いた日には、終了時刻と次の開始時刻が連続しているStayが複数行・複数ラベルへ分割される。7/17の再処理後も自宅付近にこのパターンが残っている。

## Goal

同一場所で時間的に連続し、間に実MovementがないStayだけを時系列で表示統合し、滞在時間を分割せずに示す。

## Non-Goals

- SwiftData V1 Schema、StaySegmentModel、Raw Eventの変更
- Stayの削除、永続的な結合、Stable IDの再生成
- Stay Overrideの削除・変更・Migration
- 離れた時刻の同一場所Stay、実Movementを挟むStay、別日Stayの結合

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/processing-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/9-4-stay-override-actions.md`
- [x] `issues/9-6-override-reconnection.md`
- [x] `issues/15-10-selected-route-stay-summary.md`

## Dependencies

- `MapStayAnnotation`
- `MapMovementLabel`
- `RouteMapCoordinator`
- `RouteMapViewModel`

## Scope

### Allowed Changes

- `issues/15-17-stay-display-time-grouping.md`
- `DriveLog/DriveLog/Features/Map/StayDisplayGrouping.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Places.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLogTests/Features/StayDisplayGroupingTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapStayEmphasisTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`

### Forbidden Changes

- `DriveLog/DriveLog/Data/`
- `DriveLog/DriveLog/Processing/`
- SwiftData Schema、Repository、Override persistence
- Location、Motion、Visit、Power Provider
- Signing、Team、Bundle Identifier、Capability、外部Package
- 座標・経路・PhotoKit Identifierの通常ログ出力

## Decision

表示統合の条件を次のすべてとする。

1. 同じ`localDateKey`であること。
2. Stay代表座標間が既存`stayRadius`（150m）以内であること。
3. 時系列上の隙間または重なりが既存`automaticStayDuration`（5分）以内であること。
4. 2つのStayの間にMovementの時間区間が存在しないこと。

統合グループの到着は最初のStay、出発は最後のStayとし、表示時間はその区間全体で計算する。各StayのStable IDはグループ選択とOverride操作のために保持し、個別の保存データは変更しない。条件を満たさないStayは従来どおり個別表示する。

`MapScene`とそのAnnotationは1日分だけを入力として生成され、`MapStayAnnotation`自体には`localDateKey`がない。そのためAnnotation側はScene単位の固定キーで同日性を表し、Place Sheet側の`StayDisplayData`では保存値の`localDateKey`を比較する。

## Requirements

1. 同一場所で隙間5分以内かつMovementを挟まないStayを時系列順に一つの表示グループへまとめる。
2. 統合表示の滞在時間は最初の到着から最後の出発までとする。
3. 統合グループに含まれる全Stable IDをPlace選択へ渡す。
4. Place Sheetでは統合グループを一行で表示し、個別Stayの回数表記を出さない。
5. 同一場所でも5分超の隙間、Movementを挟む場合、別日、150m超は統合しない。
6. 選択中Movementの前後Stay判定、Stay Override操作、VoiceOverを維持する。
7. SwiftData保存値、Override対象、Raw Eventを変更しない。

## UI Requirements

- Stay marker、Media付属Stay、Stay Cluster、Place Sheetで同じ時系列統合規則を使用する。
- 統合グループは`滞在 X時間Y分`形式で表示し、`滞在N回`を表示しない。
- Dynamic Type、VoiceOver、既存の44pt以上のタップ領域を維持する。

## Privacy Requirements

- 新しいログを追加しない。
- 座標は表示判定にだけ使い、Loggerへ出力しない。
- PhotoKit localIdentifierを扱うAPIやログを追加しない。

## Test Requirements

### Unit Tests

- [x] 隣接する同一場所Stayが一グループになる。
- [x] グループ時間が最初の到着〜最後の出発になる。
- [x] 5分超、150m超、別日、Movement区間ありを統合しない。
- [x] 全Stable IDがグループに残る。

### Integration Tests

- [ ] なし（永続化変更なし）。

### UI Tests

- [x] Place Sheetで統合時間が一行表示され、`回`が表示されない。

### Manual Tests

- [ ] 7/17の同一場所Stayが分割表示されず、時系列の滞在時間になる。
- [ ] Stayを選択してOverride操作できる。

## Acceptance Criteria

- [x] 同一場所・連続時間・MovementなしのStayだけが統合される。
- [x] 統合グループの全Stable IDが選択・Overrideへ残る。
- [x] 実Movementを挟むStayや別時刻の訪問が誤統合されない。
- [x] `滞在N回`が統合グループのUIに残らない。
- [x] Build、Test、SwiftLint、SwiftFormat、`git diff --check`が成功する。
- [x] 仕様外ファイルを変更しない。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- `issues/15-17-stay-display-time-grouping.md`
- `DriveLog/DriveLog/Features/Map/StayDisplayGrouping.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Places.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Features/Map/FullRouteMapView.swift`
- `DriveLog/DriveLogTests/Features/StayDisplayGroupingTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapStayEmphasisTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`

## Completion Report Format

### Summary

同一日・同一場所で時間的に連続するStayを、保存データを変更せず表示上の一つの滞在グループへ統合した。7/17の再処理後に確認したGPSドリフト由来の古いMovementは、処理Revisionを揃えて解消済みである。

### Changed Files

- `StayDisplayGrouping.swift`で時系列、150m以内、5分以内、Movement区間なしの条件を判定。
- MapのStay marker、Media付属Stay、Place Sheet、Full Mapの滞在表示へ同じグループ規則を適用。
- Stable IDと既存Overrideは保持し、`滞在N回`表示を削除。
- 関連するSwift Testingの期待値とグルーピングテストを追加・更新。

### Tests Added

- Stayの隣接・重複・時間差・距離差・Movement介在・別日・Stable ID保持を検証する7テスト。

### Verification

- `./scripts/build.sh`: 成功
- `./scripts/test.sh`: Unit 425件（91 Suite）とUI 14件、全て成功
- `swiftlint lint --strict`: 成功、違反0件
- `swiftformat --lint .`: 成功、要修正0件
- `git diff --check`: 成功

### Device Data Audit

- 実機Storeを読み取り専用で監査し、7/17 16:14〜17:47は未処理Revisionが原因で古い派生データが表示されていたことを確認。
- 最新Build起動後に再処理が完了し、該当する誤Movementは消失した。Raw Locationや保存済みデータは削除していない。

### Deviations

- `MapScene`は一日単位で生成され、`MapStayAnnotation`に日付キーがないため、Map表示側はScene単位の固定キーで同日性を表現した。保存値を使うPlace Sheet側では`localDateKey`を比較する。
- 実走行での充電中約1分間隔の取得確認は、このIssueの表示変更とは別に手動確認が必要。

### Unresolved Issues

- 実機での7/17表示確認と、充電中の実走行サンプリング間隔の確認は未実施。

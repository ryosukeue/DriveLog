# [Processing] 未確定VisitによるPolyline欠落とStay境界の隙間を修正する

## Summary

出発未確定VisitをMovementのhard split根拠から除外して欠落Polylineを復元し、表示経路の端点を近接する前後Stayへ安全に接続する。

## Background

実機から取得済みの7/15 Storeを読み取り専用で監査した。Raw Location 57件のうち48件が現行Sanitizer条件を通過し、9件は500m超の精度で除外された。現行Segmenterを同じ時刻構造で追跡すると、次の候補が破棄されていた。

- 22:41:27: 1点
- 23:16:53: 1点
- 23:42:29〜23:42:46: 2点、約94.9m

出発未確定Visitが23:16:53〜23:42:29の約25.6分・約12kmと、23:42:46〜23:48:32の約5.8分・約418mを`stationaryStay`としてhard splitしたため、前後が単一点または100m未満となったことがPolyline欠落の原因である。座標や実経路はIssueとTestへ転記しない。

また、Movementの最初/最後のRaw LocationとCLVisit代表座標には推定誤差があり、PolylineとStay Markerの間に短い視覚的な隙間が残る場合がある。

## Goal

未確定Visitを理由に実移動Polylineを失わず、大きな欠損を接続することなく、近接する前後Stayまで表示経路を連続させる。

## Non-Goals

- Raw Location、Visit、SwiftData Schemaの変更
- 100m、5分、150m、90分の閾値変更
- Map Matching、道路補正、距離・速度への補正座標加算
- 同一場所のStay表示集約変更

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/processing-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/15-1-stay-route-boundary.md`
- [x] `issues/15-6-visit-route-partition.md`
- [x] `issues/15-7-processing-algorithm-invalidation.md`

## Scope

### Allowed Changes

- `issues/15-9-open-visit-route-recovery.md`
- `docs/processing-rules.md`
- `docs/ui-spec.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/Processing/Segmentation/MovementSegmenter.swift`
- `DriveLog/DriveLog/Application/Processing/ProcessingAlgorithmMigrator.swift`
- `DriveLog/DriveLog/Features/Map/MapSceneBuilder.swift`
- `DriveLog/DriveLogTests/Processing/MovementSegmenterTests.swift`
- `DriveLog/DriveLogTests/Features/MapSceneBuilderTests.swift`

### Forbidden Changes

- SwiftData V1 Schema、Raw Event、永続化Model
- Location取得Mode、権限、Background Capability
- Stay Override、Media、Navigation、Signing、外部Package

## Decision

`stationaryStay` hard splitでCLVisitを根拠にするのは、arrival/departureが揃い5分以上のVisitだけとする。到着のみまたは5分未満のVisitは既存の`.visit` soft gapとしてStayDetectorへ渡すが、Movement chunkを分割しない。端点距離150m以内の位置停止証拠は従来通りhard splitする。

表示時はMovement開始/終了と5分以内に接する可視Stayのうち時間的に最も近い1件を選び、Polyline端点との距離が150m以内の場合だけStay代表座標を先頭/末尾へ追加する。この補正は`MapScene`だけに適用し、永続Route、距離、時間、平均速度を変更しない。

Processing Algorithm Versionを`3`へ上げ、既存完了日を一度だけ再処理対象へ戻す。

## Requirements

1. 出発未確定VisitだけではMovementをhard splitしない。
2. 5分未満VisitだけではMovementをhard splitしない。
3. arrival/departure確定済み5分以上Visitは従来通りhard splitする。
4. 150m以内の位置停止、90分Gap、日付境界を維持する。
5. 近接する前後Stayへ表示Polylineを接続する。
6. 150m超または5分超離れたStayへは接続しない。
7. 補正座標を距離、時間、速度、永続Routeへ含めない。
8. 実機データをTest Fixtureへコピーしない。

## Acceptance Criteria

- [x] 未確定Visitを跨ぐ移動が1本のMovementとして残る。
- [x] 7/15の23:16以降相当の合成経路が最小区間破棄されない。
- [x] 確定Visit前後の分割が回帰しない。
- [x] Polylineが150m以内の前後Stay座標へ接続する。
- [x] 大きな欠損をStay補正で直線接続しない。
- [x] Algorithm Versionが3になる。
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
- Decision
- Changed Files
- Tests Added
- Verification
- Device Data Audit
- Deviations
- Unresolved Issues

## Completion Report

### Summary

到着のみのVisitをMovementのhard split根拠から除外し、疎なLocation間に実移動がある経路を最小区間破棄から保護した。表示Polylineは、時間5分以内かつ距離150m以内の可視Stay代表座標へだけ前後端を延長する。

### Root Cause

7/15 StoreではRaw Location 57件中48件がSanitizerを通過していたが、到着のみのVisitが約25.6分・約12kmと約5.8分・約418mのLocation間隔を`stationaryStay`へ昇格していた。分割後に単一点または約94.9mのchunkとなり、2点・100mの最小条件を満たせずPolylineが永続化されなかった。

### Decision

arrival/departureが揃い5分以上のVisitだけをStayによるhard split根拠にした。到着のみと5分未満のVisitは`.visit` soft gapとして診断とStay検出へ残す。表示端点補正はMapScene内だけで行い、永続Route、距離、時間、平均速度を変更しない。Algorithm Versionを3へ上げ、既存の完了日を次回起動時に再処理対象へ戻す。

### Changed Files

- Movement Segmenter: 未確定/短時間Visitのsoft gap化。
- Map Scene Builder: 前後Stayへの安全な表示端点接続。
- Processing Algorithm Migrator: Version 3への更新。
- Tests: 疎なLocationと未確定Visit、確定Visit、接続許可/拒否条件を追加。
- Docs: Processing、Map表示、Test規則を更新。

### Tests Added

- 2件の到着のみVisitを跨ぐ合成移動が1本で残るTest。
- 5分確定Visitが離れた端点でも分割を維持するTest。
- 時間・距離条件を満たす前後Stayへ表示Polylineが接続するTest。
- 距離超過、時間超過、非表示Stayへ接続しないTest。

### Verification

- Simulator Build: 成功。
- Unit/Integration Test: 403件成功。
- UI Test: 13件成功。
- SwiftLint strict: 0 violations。
- SwiftFormat lint: 0 files require formatting。
- `git diff --check`: 成功。

### Device Data Audit

取得済みStoreは読み取り専用で件数・時刻間隔・距離・分割理由だけを監査した。座標と実経路はIssueおよびTest Fixtureへ転記していない。修正版の実機Store再処理は端末未接続のため未実施。

### Deviations

最初の全TestではMedia Previewの左Swipe UI Testが1回失敗した。同ケース単独再実行は成功し、その後の`./scripts/test.sh`全再実行で403件とUI 13件がすべて成功した。Simulator由来のAppIntents未使用Warning、CoreLocation Main Thread診断、MapKit Resource/Metal診断は既存の環境Warningとして残る。

### Unresolved Issues

次回実機Build後にAlgorithm Version 3の再処理が7/15へ適用され、23時台のPolylineが復旧することと、前後Stayへの見た目の接続を端末上で確認する必要がある。

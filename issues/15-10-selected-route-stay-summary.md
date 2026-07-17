# [Map] 同一場所のStay表示を選択経路の前後へ整理する

## Summary

同一場所に複数のStayがある場合の「滞在N回」集約を廃止し、Movement選択中はその経路の直前・直後に関係するStay時間だけを表示する。

## Background

現在は150m以内のStayを場所単位でまとめ、地図縮小時やMedia Clusterで`滞在N回・計X分`を表示する。この表示は選択Movementとの関係が分からず、地図を縮小しても古い集約件数が目立ち続ける。経路選択時の減光は導入済みだが、Label本文は全Stayの件数と合計時間のままである。

## Goal

選択経路と同一場所のStayの関係を「前」「後」で明確にし、経路に無関係な反復回数を地図上へ残さない。

## Non-Goals

- Stay検出、分割、Override、永続化Schemaの変更
- 場所グループの150m閾値変更
- Stay Callout、場所Sheet、Media Previewの変更
- Stayデータの削除または結合

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/15-8-selected-route-stay-emphasis.md`

## Scope

### Allowed Changes

- `issues/15-10-selected-route-stay-summary.md`
- `docs/ui-spec.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Places.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapStayEmphasisTests.swift`

### Forbidden Changes

- Processing、Location取得、Raw Event、SwiftData Schema
- Stay Override操作、Navigation、Media Preview
- Signing、Bundle Identifier、外部Package

## Decision

Movement未選択時は単一Stayだけ`滞在 X分`を表示し、同一場所に複数ある場合は件数・合計時間を出さず`滞在`とする。

Movement選択中は、開始時刻と出発時刻が5分以内のStayのうち最も近い1件を`前`、終了時刻と到着時刻が5分以内のStayのうち最も近い1件を`後`として表示する。同一Stayが両方に選ばれた場合は時間差が小さい側だけへ割り当てる。該当しない場所は`滞在`だけを残して既存通り減光する。

この規則を独立Stay、Stay Cluster、Media付属Stay、Media Clusterへ共通適用し、Movement選択変更と解除へ即時追従させる。

## Requirements

1. `滞在N回`と合計時間を地図Annotationから削除する。
2. Movement未選択時の複数Stayは`滞在`と表示する。
3. Movement選択時は時間的に最も近い直前/直後Stayを各1件だけ表示する。
4. 直前/直後の関連許容は既存の5分を使用する。
5. 無関係Stayの減光、Media Thumbnail、Tap、VoiceOverを維持する。
6. 選択Movementの変更と解除でLabelを即時更新する。
7. Stayデータ、Override、場所選択へ渡すID一覧を変更しない。

## Acceptance Criteria

- [x] 同一場所の複数Stayで`滞在N回`が表示されない。
- [x] 選択経路の前後Stay時間だけが`前`/`後`として表示される。
- [x] 無関係な反復Stay時間は表示されず減光される。
- [x] Media/Stay Clusterでも同じ規則になる。
- [x] 選択解除で単一Stay時間または汎用`滞在`へ戻る。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Completion Report Format

- Summary
- Decision
- Changed Files
- Tests Added
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion Report

### Summary

同一場所のStay集約から回数と合計時間を削除し、Movement選択中は経路開始に最も近い前Stayと終了に最も近い後Stayを各1件だけ表示するよう整理した。独立Stay、Stay Cluster、Media付属Stay、Media Clusterへ共通適用する。

### Decision

既存の5分許容を使い、Stay出発とMovement開始、Stay到着とMovement終了の時間差が最小の各1件を選ぶ。同一Stayが両側候補になる場合は時間差が小さい側だけへ割り当てる。未選択時は単一Stayのみ時間を表示し、複数Stayは`滞在`とする。全Stay IDは場所選択へ維持する。

### Changed Files

- Map Places: 前後Stay選択と共通Summary生成。
- Map Annotations: 選択変更時のLabel/減光即時更新。
- Annotation Views: Stay Summaryだけの再設定とVoiceOver基底Label維持。
- Tests: 回数削除、前後選択、無関係Stay、選択解除を追加・更新。
- Docs: UI規則とTest方針を更新。

### Tests Added

- 同一場所の前後/無関係Stayから各端点に最も近い1件だけを表示するTest。
- Movement選択変更で`前 8分・後 30分`となり、解除で`滞在`へ戻るTest。
- Media付属の複数Stayが`滞在N回`を表示しないTest。

### Verification

- Simulator Build: 成功。
- Unit/Integration Test: 404件成功。
- UI Test: 13件成功。
- SwiftLint strict: 0 violations。
- SwiftFormat lint: 0 files require formatting。
- `git diff --check`: 成功。

### Manual Verification

端末未接続のため実機の縮小/拡大表示は未確認。Simulator UI Testでは地図、Polyline Callout、Stay場所Sheet、Media Cluster導線が成功した。

### Deviations

なし。

### Unresolved Issues

同一地点に複数Stayがある実データで、経路選択時の`前`/`後`表示と縮小時に回数表示が残らないことを実機確認する必要がある。

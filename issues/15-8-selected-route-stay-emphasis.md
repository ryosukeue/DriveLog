# [Map] 選択経路に関連する滞在を強調する

## Summary

Movement Polylineを選択している間、その経路の出発・到着に時間的に関連するStay表示を維持し、無関係なStay時間表示を視覚的に抑える。

## Background

全画面地図では選択経路以外のPolylineは細く半透明になるが、Stay AnnotationとMedia下のStay時間は全日のまま同じ強さで表示される。このため、選択した経路と関係のない滞在が経路詳細より目立つ。

## Goal

経路選択時の視覚的な主従をPolyline、関連Stay、その他のStayの順に整理し、選択解除時は全Stayを通常表示へ戻す。

## Non-Goals

- Stay判定、Movement分割、永続化、Overrideの変更
- Stay Annotationの操作削除
- Media Thumbnail自体の減光
- SwiftData Schema変更

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/14-12-map-selection-emphasis.md`
- [x] `issues/15-6-visit-route-partition.md`

## Scope

### Allowed Changes

- `issues/15-8-selected-route-stay-emphasis.md`
- `docs/ui-spec.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Polyline.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`
- `DriveLog/DriveLogTests/Features/RouteMapStayEmphasisTests.swift`

### Forbidden Changes

- Processing Algorithm、Location取得、Raw Event、SwiftData Schema
- Stay修正操作、Media Preview、Polyline詳細内容
- Signing、Bundle Identifier、外部Package

## Decision

選択Movementの開始5分前から終了5分後までに時間区間が接触するStayを関連Stayとする。5分は新しい判定値を増やさず、既存の`automaticStayDuration`を表示上の境界余裕として使用する。経路端点とStay推定時刻の数分の差を吸収しつつ、同日の離れたStayを関連扱いしない。

無関係な独立Stay/Stay ClusterはAlphaを下げる。Media Annotation/Clusterは写真を主役として通常表示を維持し、その下のStay時間Labelだけを減光する。VoiceOverの情報とTap操作は維持する。

## Requirements

1. 経路未選択時は全Stayを通常表示する。
2. 経路選択時は関連Stayを通常表示で維持する。
3. 経路選択時は無関係なStay AnnotationとStay Clusterを減光する。
4. Mediaに付属する無関係なStay時間だけを減光し、Thumbnailは減光しない。
5. 選択経路の変更と選択解除を即時反映する。
6. Stay Callout、Stay修正、VoiceOver、Tap判定を維持する。

## Acceptance Criteria

- [x] 20:49経路では端点付近のStayだけが通常表示になる。
- [x] 同日の離れたStayは減光される。
- [x] Media Thumbnailは関連性によらず通常表示を維持する。
- [x] 空地図Tapで全Stayが通常表示へ戻る。
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

Movement選択中に関連Stayだけを通常表示し、無関係な独立Stay/ClusterとMedia付属Stay時間を減光する表示状態を追加した。選択経路の変更と空地図Tapによる解除へ即時追従する。

### Decision

関連判定は選択Movementの開始5分前から終了5分後までに接するStayとした。既存`automaticStayDuration`を境界余裕に使用し、新しいProcessing閾値は追加していない。独立StayはView全体をAlpha `0.22`、MediaはStay LabelだけをAlpha `0.22`とし、Thumbnail、Tap、VoiceOver情報を維持する。

### Changed Files

- Map Coordinator: 関連Stay判定と選択変更時の表示更新を追加。
- Annotation Views: Stay内容だけを減光・復元できる状態を追加。
- Tests: 時間境界、無関係Stay、Media Thumbnail維持、選択解除を追加。
- Docs: UI仕様とTest方針へ選択経路時のStay表示規則を追加。

### Tests Added

- 経路端点から5分以内のStayが関連扱いになるTest。
- 離れたStayが無関係扱いになり、選択解除で復元するTest。
- 無関係なStay Markerは減光し、Media Thumbnailは通常表示を保つTest。

### Verification

- Simulator Build: 成功。
- Unit/Integration Test: 400件成功。
- UI Test: 13件成功。
- SwiftLint strict: 0 violations。
- SwiftFormat lint: 0 files require formatting。
- `git diff --check`: 成功。

### Manual Verification

実機データの時刻監査では20:49:11〜20:59:13のMovementに対し、20:59:07開始Stayが関連境界内、21:44以降のStayは境界外となることを確認した。修正版を接続中のiPhone 15へBuild、Install、Launchできた。最終的な見た目と操作感は端末画面で確認する。

### Deviations

なし。

### Unresolved Issues

なし。

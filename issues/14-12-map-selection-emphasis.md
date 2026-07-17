# [Map] Stay修正UIを外してPolyline選択を強調する

## Goal

地図の操作を閲覧中心に整理し、選択中の経路をひと目で判別できるようにする。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `issues/14-11-direct-route-selection-map-ui.md`

## Allowed Changes

- `issues/14-12-map-selection-emphasis.md`
- `docs/ui-spec.md`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapStayCalloutView.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`

## Forbidden Changes

- SwiftData Schema、保存済みStay Override、Repository、Processing
- Location/Polyline生成処理、写真Annotation
- Project設定、Signing、外部Package

## Requirements

1. Stay Calloutから「滞在表示を修正」Menuを削除する。
2. Stay Calloutは滞在時間、到着、出発だけを表示する。
3. 選択Polylineを太く不透明にする。
4. 選択中は非選択Polylineを薄くし、選択対象とのコントラストを作る。
5. 選択解除時は全Polylineを通常表示へ戻す。
6. Stay OverrideのSchemaと内部機能は変更しない。

## Acceptance Criteria

- [x] Stay修正操作がProduction Map UIに表示されない。
- [x] 選択Polylineが明確に強調される。
- [x] 選択解除で通常表示へ戻る。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Decisions

- 選択線は8pt・不透明、非選択線は選択中のみ3pt・45% opacity、未選択状態は4pt・不透明とする。
- 保存済みStay Overrideの表示結果は維持し、編集入口だけを外す。

## Completion Report Format

- Summary
- Changed Files
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion

- Stay Calloutから修正Menuを削除し、滞在時間・到着・出発だけのMaterial表示に縮小した。
- 選択Polylineを8pt・不透明、非選択Polylineを3pt・45% opacityへ変更した。
- 選択解除時は全Polylineが4pt・不透明へ戻る。
- 保存済みStay Override、Schema、内部UseCaseは変更していない。
- Polylineの太さとopacityを検証するUnit Testを追加した。
- Build成功、全Test成功、SwiftLint 0 violation、SwiftFormat、`git diff --check`成功。
- 実機上の指での見え方とDark Mode実寸は未確認。

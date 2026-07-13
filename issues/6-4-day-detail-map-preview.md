# [UI] Day Detail Map Previewを実装する

## Summary

Day Detail上部へ当日の全経路と滞在を収めた、タップ可能な地図Previewを表示する。

## Goal

日別データを地図として確認し、後続のFull Map導線へ接続できるUI土台を作る。

## Non-Goals

- Full Map画面、Callout、現在地、Media AnnotationのThumbnail
- Summary、詳細統計、状態表示

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 6-2、6-3

## Scope

### Allowed Changes

- `issues/6-4-day-detail-map-preview.md`
- `DriveLog/DriveLog/Features/DayDetail/DayDetailView.swift`
- `DriveLog/DriveLog/Features/DayDetail/DayMapPreview.swift`

### Forbidden Changes

- Domain、UseCase、Repository、SwiftData、App Navigation、Project設定、外部Package

## Requirements

1. MapSceneのPolylineと表示StayをMapKitで描画する。
2. Sceneの初期領域を使用し、当日経路を収める。
3. Preview内のPan、Zoom、Calloutを無効にする。
4. Preview全体をタップ可能にし、Full Map用Closureを呼ぶ。
5. 拡大可能であることを示すアイコンとAccessibility Labelを付ける。
6. Day Detail全体を縦Scroll可能にし、Previewを端末高へ適応させる。
7. iOS 17で利用可能なAPIだけを使う。

## Decisions

- Phase 7の`MKMapView`共通Wrapper完成前はSwiftUI MapをPreview専用に使用し、Scene契約は共有する。
- Full Map遷移先はPhase 7のため、このIssueでは`onOpenMap` Closureのみを公開する。

## Acceptance Criteria

- [x] 経路とStayがPreviewへ表示される。
- [x] Preview操作は抑制され、全体TapがClosureへ伝わる。
- [x] Dynamic Typeと小型画面で縦Scrollできる。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
### Manual Verification
### Deviations
### Unresolved Issues

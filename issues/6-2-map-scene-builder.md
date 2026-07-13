# [Map] MapSceneBuilder基礎を実装する

## Summary

日別の移動、滞在、Media配置をMapKit非依存の`MapScene`へ変換する。

## Goal

地図PreviewとFull Mapが共有できる、決定論的なScene生成ロジックを実装する。

## Non-Goals

- MKMapView／SwiftUI表示
- Callout、Clustering、現在地
- Media配置計算

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

- Issue 6-1

## Scope

### Allowed Changes

- `issues/6-2-map-scene-builder.md`
- `DriveLog/DriveLog/Features/Map/MapSceneBuilder.swift`
- `DriveLog/DriveLogTests/Features/MapSceneBuilderTests.swift`

### Forbidden Changes

- Domain契約、Repository、Processing、SwiftData、UI、Project設定、外部Package

## Requirements

1. `MapSceneBuilding`のProduction実装を状態を持たない`struct`で追加する。
2. 空でない経路をPolylineへ変換する。
3. Label座標がある区間だけMovement Labelを生成する。
4. 表示対象StayだけAnnotationへ変換する。
5. 渡されたMediaPlacementをAnnotationへ変換する。
6. 全表示座標が収まる初期領域を生成する。
7. 座標がない場合は初期領域をnilにする。
8. MapKit、SwiftUI、SwiftData、PhotoKitをimportしない。

## Decisions

- 初期領域は緯度経度の包含矩形へ20%の余白を加え、単一点でも操作可能な最小Span 0.01度を確保する。
- 反日付変更線を跨ぐ経路の最短Span最適化はMVP対象地域と仕様にないため追加しない。

## Acceptance Criteria

- [x] Polyline、Label、Stay、Mediaを変換できる。
- [x] 非表示Stayを除外できる。
- [x] 空、単一点、複数座標の初期領域をテストする。
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

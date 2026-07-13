# [Map] 現在地ボタンを実装する

## Summary

Full MapへMapKit標準の現在地追従Buttonを追加する。

## Goal

既存の位置権限範囲内で、ユーザーが現在地へ地図を戻せるようにする。

## Non-Goals

- 権限要求、高精度GPS開始、独自Tracking UI、Preview表示

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 7-4

## Scope

### Allowed Changes

- `issues/7-5-map-current-location.md`
- `DriveLog/DriveLog/Features/Map/RouteMapView.swift`

### Forbidden Changes

- Location Provider、Permission、Domain、UseCase、Repository、SwiftData、Project設定

## Requirements

1. Full modeで`showsUserLocation`を有効にする。
2. `MKUserTrackingButton`をSafe Area右下へ配置する。
3. Buttonを44pt以上にする。
4. Accessibility LabelとIdentifierを付ける。
5. Preview modeでは現在地とButtonを表示しない。
6. 独自に位置権限要求やGPS監視を開始しない。

## Acceptance Criteria

- [x] Full modeだけ現在地Buttonを持つ。
- [x] PreviewへButtonが混入しない。
- [x] 権限不可時の状態をMapKit標準挙動へ委ねる。
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

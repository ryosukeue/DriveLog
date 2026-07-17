# [Processing] 5分以上の滞在で経路を分割する

## Summary

5分以上の滞在が推定できる位置観測間をMovement routeの境界として扱い、滞在をまたぐPolylineの連結を防ぐ。

## Goal

移動・滞在・次の移動が、地図上でも別の経路区間として理解できる処理結果を生成する。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/processing-rules.md`
- [x] `docs/test-plan.md`
- [x] `issues/14-1-polyline-location-diagnostics.md`

## Allowed Changes

- `issues/15-1-stay-route-boundary.md`
- `docs/processing-rules.md`
- `docs/test-plan.md`
- `DriveLog/DriveLog/Processing/Segmentation/MovementSegmenter.swift`
- `DriveLog/DriveLogTests/Processing/MovementSegmenterTests.swift`
- `DriveLog/DriveLogTests/Processing/StayDetectorTests.swift`

## Forbidden Changes

- SwiftData Schema、Raw Location、既存Override
- 位置取得頻度、90分欠損、日付境界
- Stayの3分/5分/150m設定値
- UI、Signing、外部Package

## Decision

独自の閾値は追加せず、既存`automaticStayDuration = 5分`を分割時間に使用する。前後位置が既存`stayRadius = 150m`以内、または同区間にCLVisitがある場合だけ分割する。5分未満、150mを超えてVisitもない区間は、低頻度Locationの欠測を滞在と誤認しないため接続を維持する。

## Requirements

1. 5分以上かつ前後位置が150m以内の観測間をStay境界として分割する。
2. 5分以上かつCLVisitが重なる観測間もStay境界として分割する。
3. 5分未満ではStay境界として分割しない。
4. 150mを超え、CLVisitもない5分以上の観測間は分割しない。
5. 90分欠損と日付境界の既存hard splitを維持する。
6. StayDetectorが新しい境界からStayを生成できる。

## Acceptance Criteria

- [x] 5分境界で前後Movementが別Segmentになる。
- [x] 5分未満と範囲外Locationは不要に分割しない。
- [x] Stay生成と既存hard splitが回帰しない。
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
- Deviations
- Unresolved Issues

## Completion

- 既存の5分・150m規則とCLVisit証拠を使用する`stationaryStay`境界を追加した。
- 5分未満、150mを超えてVisitもない欠測、90分Gap、localDate境界を個別に回帰検証した。
- 追加4件を含むUnit/Integration 393件とUI/Launch/Performance 13件がすべて成功した。
- Build、SwiftLint strict、SwiftFormat lint、`git diff --check`は成功した。
- 設定値の変更、Schema変更、Raw Locationの削除はない。

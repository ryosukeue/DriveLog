# [Map] 選択Calloutの指標行を整列する

## Summary

Polyline選択時の所要時間・開始・終了・平均速度を、見出し行と値行が揃う等幅グリッドへ修正する。

## Goal

Movement Callout内の4項目を同じ基準線と列中心で表示し、項目ごとのインデントずれに見える状態をなくす。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `issues/14-11-direct-route-selection-map-ui.md`
- [x] `issues/14-13-map-selection-reliability.md`

## Allowed Changes

- `issues/14-14-map-metric-alignment.md`
- `DriveLog/DriveLog/Features/Map/RouteMapMetricsView.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`

## Forbidden Changes

- Calloutの表示項目、値、Formatter
- Polyline選択・強調・Hit Test
- Stay、Media、Processing、SwiftData Schema
- Project設定、Signing、外部Package

## Root Cause

4項目をそれぞれ独立した縦Stackとして配置していたため、文字幅に応じた値Labelの縮小や内部Layoutが列ごとに決まり、見出しと値の基準位置が揃って見えなかった。

## Requirements

1. 見出し4件を同一の横Rowへ等幅配置する。
2. 値4件を同一の横Rowへ等幅配置する。
3. 各見出しと対応する値の横中心を一致させる。
4. 見出しRow同士、値Row同士の縦位置を一致させる。
5. System Material、角丸、表示項目、VoiceOver読上げ順を変更しない。
6. 共通Viewを使うStay Calloutでも同じ整列規則を維持する。

## Acceptance Criteria

- [x] Movement Calloutの所要時間・開始・終了・平均速度が2段の等幅グリッドで揃う。
- [x] 見出しと値の列中心が一致する。
- [x] 既存の表示内容とAccessibility Labelが維持される。
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
- Changed Files
- Tests Added
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion

- 独立した4つの縦Stackを、見出しRowと値Rowからなる共通2段グリッドへ置き換えた。
- 各Rowは等幅列を使い、対応する見出しと値の横中心を一致させた。
- グリッド全体をMaterial中央へ配置し、見出しと値の間隔を3pt以内に保った。
- 表示項目、Formatter、System Material、VoiceOverの読上げ順は変更していない。
- 列中心、各Rowの縦位置、行間隔を検証するRegression Testを追加した。
- Build成功。Unit/Integration 388件、UI/Performance/Launch 13件がすべて成功した。
- SwiftLint 0 violation、SwiftFormat、`git diff --check`成功。
- 接続中のiPhone 15向けBuild、上書きInstall、App起動は成功した。実データのPolylineを選択した最終的な見た目はユーザー確認対象。

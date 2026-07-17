# [UI] 経路Calloutを簡潔化する

## Summary

Full Mapの経路Calloutを、開始時刻・終了時刻・平均速度だけを読みやすく表示するiOS標準に近い情報パネルへ整理する。

## Goal

経路選択時に必要な3情報を大きな文字ですぐ確認でき、地図を妨げない簡潔なUIにする。

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/14-10-movement-callout-polish.md`
- `docs/ui-spec.md`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapMovementCalloutView.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`

### Forbidden Changes

- Domain、Data、Processing、SwiftData Schema
- 経路計算、平均速度計算、分類処理
- 写真・Stay Annotation
- Project設定、Signing、外部Package

## Requirements

1. 経路Calloutの表示項目を開始時刻、終了時刻、平均速度だけにする。
2. 値はDynamic Type対応の大きな文字で表示する。
3. System Material、System Color、標準Fontを使い、Light/Dark Modeへ対応する。
4. 3項目を簡潔に比較できるレイアウトにする。
5. 平均速度がない場合は既存どおり`--`を表示する。
6. VoiceOverでは3項目を意味の分かる順番で読み上げる。
7. 経路選択、Calloutの単一表示、閉じる挙動は変更しない。

## Acceptance Criteria

- [x] 開始、終了、平均速度だけが表示される。
- [x] 移動時間、距離、仮分類、ユーザー分類が表示されない。
- [x] 値が従来より大きく読みやすい。
- [x] Light/Dark Mode、Dynamic Type、VoiceOverに対応する。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。

## Decisions / Deviations

- 3項目はSystem Material上の等幅3列で表示し、値へ`title3`、項目名へ`caption1`を用いる。
- 既存の赤枠は荒い印象と地図上での主張が強いため廃止し、System Materialと控えめなShadowで階層を示す。
- 既存の写真Annotation信頼性修正が同一ファイルに未コミットで存在するため、その差分には触れず経路Callout型だけを変更する。

## Verification

- `./scripts/build.sh`
- `./scripts/test.sh`
- `swiftlint lint --strict`
- `swiftformat --lint .`
- `git diff --check`

## Completion Report Format

- Summary
- Changed Files
- Tests Added
- Build Result
- Test Result
- SwiftLint Result
- SwiftFormat Result
- Manual Verification
- Deviations
- Unresolved Issues

## Completion

- 開始、終了、平均速度だけをSystem Material上の3列で表示する専用Calloutへ変更した。
- 値はDynamic Type対応の`title3`、項目名は`caption1`とし、System色とMaterialでLight/Dark Modeへ対応した。
- VoiceOverは「開始」「終了」「平均速度」を意味の分かる順に1つの静的情報として読み上げる。
- 表示内容とAccessibilityを確認するUnit Testを1件追加した。
- Build成功。Unit/Integration 384件、UI/Performance/Launch 13件がすべて成功した。
- SwiftLintは`/tmp`のcacheを指定して0 violation、SwiftFormatと`git diff --check`も成功した。
- SimulatorでCalloutの表示・切替UI Testは成功。実機での文字サイズ別外観は未確認。

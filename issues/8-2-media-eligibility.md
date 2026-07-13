# [Media] MediaEligibilityEvaluatorを実装する

## Summary

写真・動画Metadataから、DriveLogの表示対象かをApple Framework非依存で判定する。

## Goal

ScreenshotとScreen Recordingを確実に除外し、不確実な取得元のMediaを過剰除外しない純粋な判定境界を作る。

## Non-Goals

- PhotoKit検索、Cache保存、画像解析、撮影元推測、UI

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 1-5、8-1

## Scope

### Allowed Changes

- `issues/8-2-media-eligibility.md`
- `DriveLog/DriveLog/Processing/Media/MediaEligibilityEvaluating.swift`
- `DriveLog/DriveLog/Processing/Media/DefaultMediaEligibilityEvaluator.swift`
- `DriveLog/DriveLogTests/Processing/MediaEligibilityEvaluatorTests.swift`

### Forbidden Changes

- PhotoKit Provider、Domain型、Schema、Repository、UI、Project設定、外部Package

## Requirements

1. `MediaEligibilityEvaluating: Sendable`を定義する。
2. `DefaultMediaEligibilityEvaluator`は状態を持たない`struct`とする。
3. ScreenshotまたはScreen Recordingを`.ineligible`とする。
4. creationDateがないMediaは日付へ所属できないため`.ineligible`とする。
5. 上記以外のphoto／videoは取得元を推測せず`.eligible`とする。
6. Apple Framework、UI、SwiftDataをimportしない。
7. AI、画像内容、filename、localIdentifierのpatternで判定しない。

## Decisions

- component-specsの「撮影日時を持つメディア」を採用条件とし、`creationDate == nil`はineligibleとする。
- Protocol名はTest PlanのEvaluator表現へ合わせ`MediaEligibilityEvaluating`、実装名は`DefaultMediaEligibilityEvaluator`とする。

## Acceptance Criteria

- [x] Screenshot／Screen Recording／日時なしを除外する。
- [x] 通常photo／videoと不明な取得元をeligibleに保つ。
- [x] 全組合せUnit Testが成功する。
- [x] Build、全Test、Lint、Format、Diff Checkが成功する。
- [x] 新規Warning、仕様外変更がない。

## Deviations

- なし。Build時のAppIntents metadata skipとSimulator runtimeのWarningは既存環境由来。

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

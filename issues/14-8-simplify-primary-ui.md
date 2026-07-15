# [UI] 地図と写真を中心に主要画面を簡潔化する

## Summary

Calendar、Day Detail、Full Mapの機能削除後の余分なCard表現と説明項目を減らし、地図、距離/時間、写真を中心に整える。

## Background

分類変更と詳細統計を削除した後も、基本SummaryはCard背景と「代表仮分類」を持つ。Media GridはAccessibility Dynamic Typeでも3列固定でThumbnailが小さい。Calendar/Mapは既にSystem色、Dynamic Type、VoiceOver、標準Animationを使用している。

## Goal

iOS標準に近い簡潔な階層にし、SE幅からAccessibility文字サイズまで主要情報を読みやすくする。

## Required Documents

- [x] `docs/ui-spec.md`
- [x] `docs/requirements.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/14-8-simplify-primary-ui.md`
- `DriveLog/DriveLog/Features/DayDetail/DaySummaryCard.swift`
- `DriveLog/DriveLog/Features/DayDetail/MediaGridSection.swift`
- 対応するFeature Test

### Forbidden Changes

- Design System/外部Package
- Accent Color、Domain/Data/Processing
- 独自Animation

## Requirements

1. 基本SummaryのCard背景/過剰なpaddingを削除する。
2. Summaryは距離、時間、開始、終了、Media件数に限定する。
3. Accessibility Dynamic Type時はMediaを2列にしてtap領域を確保する。
4. System色とDark Mode対応を維持する。
5. Reduce Motionを妨げる独自Animationを追加しない。

## Acceptance Criteria

- [ ] 地図/写真が視覚的主役になる
- [ ] 基本距離/時間が維持される
- [ ] Accessibility文字サイズでMediaが2列になる
- [ ] Build/Test/Lint/Format/diff check成功

## Decisions / Deviations

- 大規模な見た目変更を避け、System componentsと既存赤Accentを維持する。
- Full Mapは全面地図で既に簡潔なため追加装飾変更をしない。

## Completion Report Format

- Summary
- UI changes
- Accessibility/Dark Mode/Reduce Motion
- Verification
- Manual verification
- Deviations

## Completion

- Summaryを「移動」に簡潔化し、Card背景/paddingと代表仮分類を削除した。
- 距離、移動時間、開始/終了、Media件数は維持した。
- Accessibility Dynamic TypeのMedia Gridを2列にし、Thumbnail/tap領域を拡大した。
- System色、Dark Mode、赤Accent、標準Motionを維持し独自Animationは追加していない。
- Build、全392 Test、SwiftLint、SwiftFormat、`git diff --check`成功。
- 実機Dark Mode、Reduce Motion、SE/Pro Max各実寸は未確認。新規Source Warningはない。

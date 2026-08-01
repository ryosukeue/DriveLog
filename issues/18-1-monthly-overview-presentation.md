# [UI] 月間ギャラリーの閉じる導線と空状態を修正する

## Summary

月間ギャラリーの写真・動画プレビューに常に戻るボタンを表示し、記録がない月の空状態が重なって表示されないようにする。

## Background

月間ギャラリーは`MediaPreviewView`をNavigation containerなしで`fullScreenCover`へ表示しているため、Toolbar上の戻るボタンが描画されない。Calendar全体の空状態はScroll contentへ重ねるOverlayになっており、月間サマリーの空状態と同じ位置で競合する。

## Goal

月間画面から開いたプレビューを明示的に閉じられ、記録がない月には単一の月間空状態だけが表示されるようにする。

## Non-Goals

- Media読み込み処理の変更
- Movement表示Filterの変更
- Location取得Modeの変更

## Required Documents

- [x] `AGENTS.md`
- [x] `docs/project-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `issues/16-3-monthly-overview-map-gallery.md`
- [x] `issues/15-3-media-preview-paging.md`

## Scope

### Allowed Changes

- `issues/18-1-monthly-overview-presentation.md`
- `DriveLog/DriveLog/Features/Calendar/CalendarView.swift`
- `DriveLog/DriveLog/Features/Calendar/MonthlyOverviewView.swift`
- `DriveLog/DriveLog/Features/Calendar/MonthlySummaryView.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`
- `DriveLog/DriveLogUITests/DriveLogFeedbackUITests.swift`

### Forbidden Changes

- Repository、SwiftData Schema、PhotoKit Provider
- Movement分類、Location Provider
- Signing、Capability、外部Package

## Requirements

1. 月間ギャラリーから開いたPreviewに上部左の戻るボタンを表示する。
2. 戻るボタンでPreviewを閉じ、月間ギャラリーへ戻る。
3. Calendar全体の空状態をOverlay表示しない。
4. 記録がない月は月間サマリーの空状態を代表表示とする。
5. 月間Overviewが完全に空の場合は重複する空メッセージを追加しない。

## Accessibility Requirements

- Previewの戻るボタンは`mediaPreview.back`を維持する。
- 月間空状態は`calendar.monthlySummary.empty`を維持する。
- Dynamic Typeと44ptの標準Toolbar操作領域を維持する。

## Privacy Requirements

- PhotoKit localIdentifier、座標、ファイル名をLoggerへ出力しない。
- 外部通信を追加しない。

## Test Requirements

- UI Testで月間ギャラリーから写真Previewを開き、戻るボタンで閉じる。
- UI Testで空Calendarに重複Overlayが存在しないことを確認する。
- Build、Test、SwiftLint strict、SwiftFormat lint、Diff Checkを成功させる。

## Acceptance Criteria

- [x] 月間ギャラリーPreviewに戻るボタンが表示される。
- [x] 戻る操作で月間ギャラリーへ復帰する。
- [x] 空状態が重ならない。
- [x] 自動検証が成功する。

## Completion Report Format

- Summary
- Root Cause
- Changed Files
- Tests Added
- Verification
- Manual Verification
- Deviations
- Unresolved Issues

## Completion Report

### Summary

月間Previewを`NavigationStack`内に表示して戻るToolbarを有効化し、Calendarと月間Overviewの重複する空Overlayを除去した。

### Root Cause

PreviewにNavigation containerがなく、Calendar、月間Summary、月間Overviewがそれぞれ空状態を表示していた。

### Changed Files

Calendar、Monthly Overview、Monthly Summaryと専用UI回帰Testを更新した。

### Tests Added

空状態が1つだけであることと、月間Gallery Previewの戻る操作をUI Testへ追加した。

### Verification

450 Unit Test、関連する全UI Test、Build、SwiftLint strict、SwiftFormat lint、Diff Checkを通過した。

### Manual Verification

iPhone 17 Simulatorで自動操作確認済み。実機確認は未実施。

### Deviations

UI Testの型・File行数規約を守るため、追加Testを`DriveLogFeedbackUITests.swift`へ分離した。

### Unresolved Issues

なし。

# [Calendar] 月Sectionを縦方向へ連続スクロールする

## Summary

横Swipeによる単月切替を廃止し、現在月付近から過去・未来の月Sectionを縦方向へ連続して閲覧できるCalendarへ変更する。

## Background

既存Calendarは1か月だけを表示し、Drag gestureで前後月を再取得していた。月を跨ぐ記録確認に不向きで、横操作も地図等の標準Navigationと一貫しない。

## Goal

明確な月見出しを持つLazyな縦Calendarを提供し、記録日の選択規則を維持する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/14-7-continuous-calendar.md`
- `DriveLog/DriveLog/Features/Calendar/`
- `DriveLog/DriveLog/Domain/ValueObjects/LocalMonth.swift`
- 対応するCalendar Unit/UI Test

### Forbidden Changes

- Calendar永続化/Schema、Day Detail、Signing、Package

## Requirements

1. 月Sectionを`ScrollView`/`LazyVStack`で縦表示する。
2. 現在月から開始し、端のSection表示時に3か月ずつ遅延追加する。
3. 横Swipe月送りを削除する。
4. Today、選択日、距離、記録なし日の無効化を維持する。
5. 月を含むVoiceOver labelと一意なIdentifierを使用する。
6. Dynamic TypeとiPhone SE幅で7列を維持する。

## Acceptance Criteria

- [ ] 上下スクロールで過去/未来月へ移動できる
- [ ] 全月一括生成をしない
- [ ] 横Swipe処理がない
- [ ] 記録なし日から遷移しない
- [ ] Build/Test/Lint/Format/diff check成功

## Decisions / Deviations

- 初回は現在月の前後2か月（計5か月）だけを取得し、現在月へScrollする。以後、端で3か月ずつ増やす。
- `LocalMonth`は月Cache keyとSection identityのため`Hashable`/`Comparable`にした。
- 過去側追加時の厳密なpixel位置保持はSwiftUIへ委ね、現在月への初回Scrollを明示する。

## Completion Report Format

- Summary
- Loading/window strategy
- Accessibility
- Tests/verification
- Manual verification
- Deviations

## Completion

- Calendarを`ScrollView`/`LazyVStack`の月Sectionへ変更し、横Swipe gestureを削除した。
- 初回は現在月前後2か月だけを取得して現在月へ位置合わせし、端で3か月ずつ遅延追加する。
- Today/選択日の表示、距離、記録なし日の無効化を維持し、月を含む一意なAccessibility label/identifierを追加した。
- Calendar Unit Testを連続window/年境界へ更新し、UI Testを縦Scrollへ更新した。
- Build、全392 Test、SwiftLint、SwiftFormat、`git diff --check`成功。
- Simulator競合時に対象Simulatorをerase/rebootして再検証した。最終Runは13 UI Testを含め全成功。
- iPhone SE実寸、実機VoiceOver、長時間の過去/未来Scrollは未確認。新規Source Warningはない。

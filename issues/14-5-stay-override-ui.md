# [UI] Stay修正操作を簡潔に整理する

## Summary

Full MapのStay Calloutから「滞在として確定」「非表示」「自動判定へ戻す」を明確に操作でき、保存状態と結果をAccessibilityを含めて確認できるようにする。

## Background

既存実装はStay Annotation選択、3操作、即時Scene更新、永続化、再処理時のOverride再接続、保存中表示、失敗Alert、成功Hapticを備える。分類UI削除後もこの導線は独立している。現状の「立ち寄り」とDomain/UIの「滞在」で用語が不一致で、保存中状態のVoiceOver valueが明示されていない。

## Goal

Stay Overrideの既存機能を維持し、簡潔で一貫した用語と状態通知へ整える。

## Non-Goals

- Override Schema/Matching変更
- Movement分類UIの再追加
- 新しいStay判定Rule

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/14-5-stay-override-ui.md`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- 対応するMap Unit/UI Test

### Forbidden Changes

- SwiftData Schema、Override Repository/UseCase/Matcher
- Movement UI、Processing Rule、Signing、Package

## Requirements

1. Stay Annotation/Calloutだけに3操作を表示する。
2. 用語を「滞在として確定」に統一する。
3. 保存中は二重操作を防ぎ、VoiceOverへ状態を伝える。
4. 既存の即時反映、成功Haptic、失敗Alert、再処理再接続を維持する。

## Acceptance Criteria

- [ ] 3操作と順序が明確
- [ ] Movement CalloutにStay Menuがない
- [ ] 保存中の表示、無効化、Accessibility valueが正しい
- [ ] Build/Test/Lint/Format/diff check成功

## Decisions / Deviations

- 状態機械と永続化は既に要件を満たすため変更せず、Presentationの用語とAccessibilityだけを修正する。

## Completion Report Format

- Summary
- Changed files
- Existing behavior verified
- Verification
- Manual verification
- Deviations

## Completion

- Stay Menuを「滞在として確定」「非表示」「自動判定へ戻す」に統一した。
- 操作可能/保存中をVoiceOver valueへ追加し、保存中の無効化を維持した。
- 即時Scene反映、成功Haptic、失敗Alert、Override再接続は既存Testで維持される。
- Build、全393 Test、SwiftLint、SwiftFormat、`git diff --check`成功。
- 実機VoiceOver操作は未確認。Simulator由来Warning以外の新規Warningはない。

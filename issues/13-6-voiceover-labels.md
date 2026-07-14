# [Accessibility] VoiceOver Labelを確認する

## Summary

主要な操作・状態・Map annotationへ意味のあるAccessibility LabelとIdentifierがあり、色や画像だけに依存しないことを監査する。

## Required Documents

- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-6-voiceover-labels.md`
- 再現したAccessibility不具合に直接関係するViewとTest

### Forbidden Changes

- UI文言・Navigation・Product仕様の不要な変更

## Requirements

1. Calendar day、Map annotation/callout、Media cell/previewへLabelを付ける。
2. Icon-only操作へVoiceOver名を付ける。
3. Loading、Empty、Error、Progressを識別可能にする。
4. 主要導線をAccessibility identifierでUI Test可能にする。

## Acceptance Criteria

- [x] 主要FeatureにAccessibility APIの設定がある。
- [x] Map custom viewのLabel/Identifier Unit Testがある。
- [x] Onboarding、Calendar、Map、MediaのUI TestがLabel/Identifierで要素を操作する。
- [x] 修正を要する明確な欠落がない。

## Decision / Deviations

- Feature sourceを静的監査し、Accessibility関連設定77箇所を確認した。
- Media cell、Calendar day、Map annotation/cluster/callout/current-location、Previewへ明示Labelがある。文字付きSwiftUI Buttonは表示文字を標準Labelとして使用する。
- `simctl ui`はVoiceOver切替をサポートしないため、実際の読み上げ順序・発音・Rotor操作は実機で未確認。
- 既存Unit Testと成功済み主要UI TestでCustom UIKit viewと操作導線を確認したため、コード変更はない。

## Files Expected to Change

- `issues/13-6-voiceover-labels.md`のみ。

## Completion Report Format

- Summary
- Changed files and reasons
- Tests added
- Build result
- Test result
- SwiftLint result
- SwiftFormat result
- Manual verification
- Deviations
- Unresolved issues

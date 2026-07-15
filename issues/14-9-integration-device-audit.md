# [Quality] 実機改善のIntegration監査と確認Checklistを完成する

## Summary

Issue 14-1〜14-8の仕様を設計文書へ反映し、Privacy、Schema、Location状態遷移、Media、Calendar、Accessibilityを総合検証して実機確認項目を固定する。

## Goal

実装と文書の不一致を解消し、Simulatorで保証できる範囲と実機で確認すべき範囲を明確にする。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/14-9-integration-device-audit.md`
- 上記Required Documentsと`docs/project-rules.md`
- `docs/real-device-checklist.md`
- 監査で必要になった対応Test/Source（Schema/Signingを除く）

### Forbidden Changes

- SwiftData V1 Schema/Migration
- Signing、Team、Bundle Identifier、Package
- Photos Asset/Raw Locationの削除

## Requirements

1. Issue 14の状態遷移、Polyline、Media、UI仕様を文書へ同期する。
2. 実機Checklistへ充電、Background、Polyline、PhotoKit、VoiceOver、端末幅を記載する。
3. Privacy禁止値、force operation、TODO、Schema、iOS 17、iPhone/Portraitを監査する。
4. Build、全Test、Lint、Format、diff checkを実行する。

## Decisions / Deviations

- 監査で旧横Swipe専用`CalendarSwipeInterpreter`がProduction未使用になったため、型と専用Testを削除する。

## Acceptance Criteria

- [ ] 文書が現行UI/Location仕様を正とする
- [ ] 実機未確認を成功扱いにしない
- [ ] Schema/Signing差分がない
- [ ] 全自動検証が成功する

## Completion Report Format

- Audit summary
- Requirements/interfaces/data/privacy results
- Automated verification
- Device checklist
- Warnings/deviations/unresolved items

## Completion

- Requirements/Architecture/Interfaces/Data Model/Processing/UI/Test/Implementation PlanへIssue 14の優先仕様を反映した。
- Privacy監査でforce unwrap/cast、`fatalError`、`try!`、`print`系、座標/Media identifierを扱うLogging API、TODO/Placeholderは検出されなかった。
- SwiftData V1 Model/Migration、Signing、Team、Bundle Identifier、外部Packageの差分はない。
- iOS Deployment Target 17.0、iPhone family `1`、Portrait onlyをBuild Settingsで確認した。
- 旧横Swipe専用の未使用型/Testを削除した。
- Build成功。全390 Test（13 UI Testを含む）成功。SwiftLint、SwiftFormat、`git diff --check`成功。
- Xcodeのsupported platform表示、AppIntents metadata skip、DebuggerVersionStore、Simulator accessibility duplicate classは環境由来Warning。新規Source Warningはない。
- `docs/real-device-checklist.md`の充電/Background/走行/PhotoKit/端末幅/VoiceOver/既存Storeは実機未確認である。

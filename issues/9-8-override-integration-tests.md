# [Test] Override統合Testを追加する

## Summary

SwiftDataへ保存したOverrideが再処理後の派生置換を越えて保持され、stableID完全一致または一意の近似一致で表示へ適用される統合Testを追加する。

## Background

OverrideMatcher、処理Pipeline、表示Data適用は個別Unit Test済みである。Phase 9完了には、Repository保存、rawRevision更新、再処理、派生一括置換、Day Detail表示を通した回帰Testが必要である。

## Goal

Classification／Stay Overrideの再処理後維持と誤候補拒否を、インメモリSwiftDataを用いた実経路で保証する。

## Non-Goals

- Production実装・Schema・公開Interface変更
- UI操作、Haptic、実機触覚Test
- Override照合閾値変更

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 4-4 OverrideRepository
- Issue 4-5 ProcessDayUseCase
- Issue 9-5 Override適用済みDisplay Data
- Issue 9-6 再処理後Override再紐づけ

## Scope

### Allowed Changes

- `issues/9-8-override-integration-tests.md`
- `DriveLog/DriveLogTests/Integration/OverrideIntegrationTests.swift`

### Forbidden Changes

- Production Swift、SwiftData Schema、Project設定変更
- Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. インメモリSwiftData ContainerとProduction Repository／UseCaseを使用する。
2. Classification Override保存後にrawRevisionを進めて再処理する。
3. stableIDが変化しても一意の近似Classification Overrideが表示へ適用されることを確認する。
4. Stay Override保存後にrawRevisionを進めて再処理する。
5. stableIDが変化しても一意の近似Stay Overrideが表示と集計へ適用されることを確認する。
6. 派生Stayの自動表示値と元Overrideが再処理後も保持されることを確認する。
7. 近似Stay候補が複数ある場合、どちらにもOverrideを適用しないことを確認する。
8. Fixtureへ実在個人の座標やメディア識別子を使用しない。

## Acceptance Criteria

- [x] Classification Overrideが再処理後の新stableIDへ近似適用される
- [x] Stay Overrideが再処理後の新stableIDへ近似適用される
- [x] 自動値と元Overrideが保持される
- [x] 複数候補では自動適用されない
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する
- [x] Production差分、新規Warning、仕様外変更がない

## Test Requirements

- Classificationの保存→再処理→表示統合Test
- Stay hideの保存→再処理→集計・表示統合Test
- 2件の近似Stay候補に対する拒否統合Test

## Decision / Deviations

- Fixtureは赤道上の相対距離だけを用い、現実の行動履歴や個人情報を含めない。
- 新規Integration Test 3件を追加し、Unit Test 357件とUI Test 8件が成功した。Xcode summaryはparameterized runを展開して392件、論理Test 364件と集計する。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility message、既存Swift 6予告Warningは既存由来で、新規Source Warningはない。

## Files Expected to Change

- Allowed Changes記載のIssue文書とIntegration Testのみ。

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

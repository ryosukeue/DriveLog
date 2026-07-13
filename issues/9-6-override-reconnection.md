# [Processing] 再処理後Override再紐づけを接続する

## Summary

再処理でstableIDが変化しても、一意に特定できるStay Overrideを処理結果へ再適用する。自動判定値と元Overrideは保持し、誤候補が複数ある場合は適用しない。

## Background

`OverrideMatcher`にはstableID完全一致、近似一致、複数候補拒否が実装済みであり、`DefaultDayProcessor`もStay Overrideを集計へ反映している。しかし現在は適用後の表示状態を派生Stayの自動判定Propertyへ保存しており、再処理後に自動判定へ戻せなくなる。

## Goal

自動判定済みStayを不変のまま保存しつつ、一意に再紐づいたOverrideを日次集計へ反映する。

## Non-Goals

- Overrideの更新、削除、targetStableIDの書換え
- Classification Overrideによる自動分類値・自動代表分類の変更
- UI、Haptic、SwiftData Schemaの変更

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 3-14 OverrideMatcher
- Issue 3-16 DefaultDayProcessor
- Issue 9-5 Override適用済みDisplay Data

## Scope

### Allowed Changes

- `issues/9-6-override-reconnection.md`
- `DriveLog/DriveLog/Processing/Pipeline/DefaultDayProcessor.swift`
- `DriveLog/DriveLogTests/Processing/DefaultDayProcessorTests.swift`
- `DriveLog/DriveLogTests/Processing/DefaultDayProcessorOverrideTests.swift`

### Forbidden Changes

- Domain Data、OverrideMatcher規則、Repository、SwiftData Schema変更
- Overrideの永続化形式・公開Interface変更
- UI、Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. stableID完全一致を近似一致より優先する。
2. 完全一致がない場合、一意の近似候補だけへStay Overrideを適用する。
3. 近似候補が0件または複数の場合は適用しない。
4. `confirm`、`hide`、`automatic`のeffective表示状態を日次集計へ反映する。
5. 返却・保存対象の`StaySegmentData.isVisibleByAutomaticRule`はOverride適用前の自動値を保持する。
6. 元Overrideを削除、更新、再保存しない。
7. Classification Overrideは表示層で適用し、自動分類と自動代表分類を変更しない。

## Processing Rules

- stableID完全一致を最優先する。
- Movement近似条件は同一日、開始・終了差15分以内、重なり率50%以上とする。
- Stay近似条件は同一日、到着・出発差15分以内、代表座標差300m以内とする。
- 候補は1件のときだけ採用し、元Overrideは削除しない。

## Data Model Rules

- Overrideは派生DataとのRelationshipを持たず、元のtargetStableIDと近似照合情報を保持する。
- `isVisibleByAutomaticRule`はユーザー修正後のeffective値ではなく自動判定値を保持する。

## Interface Contract

既存の`OverrideMatching`と`DayProcessing`を変更せず使用する。

## Implementation Constraints

- ProcessingはSwiftUI、SwiftData、Apple Platform APIへ依存しない
- `fatalError()`、`try!`、`as!`、`print()`を追加しない
- 元Overrideと自動判定Dataを変更しない
- 新規Warning、未完成TODOを残さない

## Acceptance Criteria

- [x] stableID完全一致のOverrideが再適用される
- [x] 一意の近似Overrideが再適用される
- [x] 複数近似候補ではOverrideが適用されない
- [x] effective状態が日次集計へ反映される
- [x] 派生Stayの自動判定値が保持される
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する
- [x] 新規Warningと仕様外変更がない

## Test Requirements

- stableID完全一致のhide適用
- 一意の近似hide適用
- 複数近似候補のconfirm拒否
- 各適用後も返却Stayの自動判定値が変化しないこと

## Decision / Deviations

- Classification Overrideは自動値を変更せずIssue 9-5のDisplay Dataで適用するため、本IssueではStayのeffective状態を集計へ接続する。
- Unit Test 354件とUI Test 8件が成功した。Xcodeの集計ではparameterized test runを展開した合計389件、論理Test 361件として表示される。
- 初回の全Test再実行はSimulatorの`SBMainWorkspace Busy`によりUI Runnerを起動できなかった。重複processがないことを確認してiPhone 17 Simulatorを再起動し、競合のない再実行で全件成功した。
- AppIntents metadata skip、SimulatorのLLDB debugger version store／Accessibility Runtime messageは既存の環境由来で、新規Source Warningはない。

## Files Expected to Change

- Allowed Changes記載のIssue文書、処理Pipeline、Unit Test。

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

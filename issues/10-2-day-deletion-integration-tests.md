# [Test] 日付完全削除Integration Testを追加する

## Summary

DayDeletionRepositoryがV1全10 Modelを指定日だけ完全削除し、他日とApple Photosを変更しないことをインメモリSwiftDataで検証する。

## Background

Issue 10-1で全削除を1つのPersistenceActor操作と1回のsaveへ集約した。削除対象漏れ、日付条件漏れ、Aggregateに紐づかない孤立Dataの残存を防ぐ統合回帰Testが必要である。

## Goal

指定日の全Model削除、他日維持、孤立Data cleanup、空日付の冪等性をProduction Repository越しに保証する。

## Non-Goals

- Production実装、Schema、UseCase、UI変更
- PhotoKit資産の作成・削除
- 永続Store破損やOS強制終了のFault Injection

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 10-1 DayDeletionRepository

## Scope

### Allowed Changes

- `issues/10-2-day-deletion-integration-tests.md`
- `DriveLog/DriveLogTests/Data/DayDeletionRepositoryIntegrationTests.swift`

### Forbidden Changes

- Production Swift、SwiftData Schema、Project設定変更
- Photos／PhotoLibrary API使用
- Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. インメモリV1 ModelContainerへ全10 Modelを対象日・他日の2組保存する。
2. ProductionのSwiftDataDayDeletionRepositoryで対象日を削除する。
3. 対象日の全10 Modelが0件になることを個別に確認する。
4. 他日の全10 Modelが各1件維持されることを確認する。
5. Aggregate、Rawが存在しない孤立Derived、Override、State、Mediaも削除されることを確認する。
6. 対象Dataがない日付の削除が成功し、既存Dataを変更しないことを確認する。
7. Photos ProviderやPhotoKitをFixtureへ導入しない。
8. 現実の個人座標やメディア識別子をFixtureへ使用しない。

## Acceptance Criteria

- [x] 指定日のV1全10 Modelが削除される
- [x] 他日のV1全10 Modelが維持される
- [x] Aggregate非存在の孤立Dataが削除される
- [x] 空日付削除が冪等である
- [x] 1カテゴリだけ残る部分削除状態がない
- [x] Photos APIをTest・Production削除経路で使用しない
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する
- [x] Production差分、新規Warning、仕様外変更がない

## Test Requirements

- 全10 Modelの対象日削除／他日維持
- 孤立Derived・Override・State・Media cleanup
- 空日付削除

## Decision / Deviations

- save失敗のFault InjectionはPersistenceActorの実装境界を変更せずには行えない。本Testは公開Repositoryで削除後に全10カテゴリが同時に0となることを確認し、commit前の単一save構造はIssue 10-1で監査する。
- 新規Integration Test 3件を追加し、Unit Test 360件とUI Test 8件が成功した。
- Delete RepositoryとTest Fixtureのimport／型参照を確認し、PhotoKit／PhotoLibraryProvidingを使用していない。
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

# [Application] 生イベント保存Coordinatorを実装する

## Summary

Location、Motion、Visit ProviderのStreamを購読し、生イベントをRawEventRepositoryへ保存するApplication Coordinatorを追加する。

## Goal

3系統のProviderを独立して購読し、個別イベントの失敗が他のイベントやProviderの保存を止めない生ログ保存経路を確立する。

## Non-Goals

- Provider監視の開始／停止
- 日別Processingの実行
- UI、Background Task、権限要求

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issues 2-1〜2-7 RawEventRepositoryと3 Provider
- Issue 0-4 Logging

## Scope

### Allowed Changes

- `issues/2-9-raw-event-storage-coordinator.md`
- `DriveLog/DriveLog/Application/EventStorage/RawEventStorageCoordinator.swift`
- `DriveLog/DriveLogTests/Application/RawEventStorageCoordinatorTests.swift`
- `DriveLog/DriveLogTests/TestSupport/SpyEventLogger.swift`

### Forbidden Changes

- Provider、Repository、SwiftData Schema、Domain、UI、App Entry Point
- Project設定、Signing、外部Package

## Requirements

1. 3 ProviderのAsyncStreamを独立Taskで購読する。
2. location／motion／visit eventを対応するRawEventRepository APIへ渡す。
3. inserted／updatedだけを保存成功として固定LogEventへ記録する。
4. location duplicateとlocation provider／persistence failureは固定reasonCodeで記録する。
5. stateChanged eventは永続化しない。
6. 1イベントの保存失敗後も同じStreamの次イベントを処理する。
7. 1 Providerの失敗で他Providerの購読を停止しない。
8. startは多重購読を作らず、stopは購読Taskだけをcancelする。
9. 座標、経路、OS Error、メディアIDをログへ含めない。
10. SwiftDataへ直接アクセスしない。

## Acceptance Criteria

- [x] 3種類の生イベントを対応Repositoryへ保存できる。
- [x] accepted saveだけが対応するsaved LogEventになる。
- [x] location duplicate／failureがprivacy-safeな固定reasonCodeになる。
- [x] 個別失敗後も後続イベントと他Providerを保存できる。
- [x] stop時にProvider監視自体を停止しない。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規ソースWarningと仕様外変更がない。

## Decisions

- `RawEventRepository`の設計責務に「保存成功時のrawRevision更新」があり、既存実装も保存と同一Actor操作で更新する。別の`markDirty`呼出しはrevisionを二重加算しうるため、Issue 2-9のmarkDirty責務はRepositoryのatomic saveに委譲する。
- 固定13 LogEventにはMotion／Visitの失敗caseがない。意味の異なる既存caseを流用せず、保存成功とLocation rejectだけを記録する。
- CoordinatorのstopはStream購読だけを止め、低消費電力監視の停止判断はLifecycle／Monitoring UseCaseへ残す。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Definition of Done

- [x] GoalとAcceptance Criteriaを満たす。
- [x] Allowed Changes内だけを変更する。
- [x] 全検証が成功する。

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
- Build:
- Unit Tests:
- Integration Tests:
- UI Tests:
- SwiftLint:
- SwiftFormat:
- Diff Check:
### Manual Verification
### Deviations
### Unresolved Issues

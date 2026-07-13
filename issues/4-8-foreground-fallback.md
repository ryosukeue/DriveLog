# [Application] Foreground fallbackを実装する

## Summary

アプリ起動時とForeground復帰時に、監視状態の再確認後、古い未処理日を少量処理するfallbackを追加する。

## Goal

BGTaskが実行されない環境でも、通常利用中に日別派生データを前進させる。

## Non-Goals

- BGTask登録、全未処理日の一括処理、メディア変更反映、UI

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/4-8-foreground-fallback.md`
- `DriveLog/DriveLog/Application/AppLifecycleCoordinator.swift`
- `DriveLog/DriveLogTests/Application/AppLifecycleCoordinatorTests.swift`

### Forbidden Changes

- DayProcessingCoordinator／UseCase、Repository、Platform、UI、App Entry、Project設定

## Decision

設計文書の「アプリ起動時に未処理日を軽く処理する」には件数指定がない。Foreground滞在を長く占有しない最小実装として、1回につき古い日を1件処理する。

## Requirements

1. AppLifecycleCoordinatorへ`DayProcessingCoordinating`をinitializer注入する。
2. Launch時は権限更新と監視確認後に`processPendingDays(limit: 1)`を実行する。
3. Foreground時も同じ順序で1日処理する。
4. Background移行では日別処理を開始・停止せず、SLC監視を継続する。
5. Lifecycleは日付選択やRepository参照を行わない。
6. 処理失敗はCoordinator内で状態管理されるため、監視処理へ波及させない。

## Acceptance Criteria

- [x] Launchで権限、監視、pending処理の順に実行する。
- [x] Foreground復帰ごとにlimit 1でfallbackを実行する。
- [x] 監視開始失敗時もfallbackを実行する。
- [x] Backgroundではfallbackとキャンセルを呼ばない。
- [x] 既存の監視継続・再試行テストが成功する。
- [x] 全検証が成功し、新規Warningと仕様外変更がない。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Definition of Done

- [x] Acceptance Criteria、Allowed Changes、全検証を満たす。

## Completion Report Format

### Summary
### Changed Files
### Tests Added
### Verification
### Manual Verification
### Deviations
### Unresolved Issues

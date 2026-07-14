# [Application] 充電中優先条件を設定する

## Summary

Background移行時のBGProcessingTask予約へ外部電源必須条件を設定する。

## Background

Lifecycle予約は11-3で接続済みだが、暫定的に外部電源不要である。設計では日別処理を充電中に優先実行する。

## Goal

すべてのbackground予約が`requiresExternalPower: true`を使用するよう固定する。

## Non-Goals

- 実行時刻の保証
- Battery状態の独自監視
- Network接続条件追加

## Required Documents

- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 11-3 Background lifecycle scheduling

## Scope

### Allowed Changes

- `issues/11-4-background-external-power.md`
- `DriveLog/DriveLog/Application/AppLifecycleCoordinator.swift`
- `DriveLog/DriveLogTests/Application/AppLifecycleCoordinatorTests.swift`

### Forbidden Changes

- Platform Scheduler、Handler、App DI変更
- Battery監視、Repository、Schema、UI変更
- Project設定、外部Package、Signing変更

## Requirements

1. handleBackgroundは`requiresExternalPower: true`で予約する。
2. 外部電源条件はOS Schedulerへ委ねる。
3. 実行時刻や充電開始直後の実行を保証しない。
4. Foreground fallbackを変更しない。
5. Scheduler失敗時もfallbackを維持する。

## Acceptance Criteria

- [x] 通常予約と失敗予約の両Testでtrue条件を確認する。
- [x] Foreground pending limit 1が維持される。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- なし。
- 2026-07-14にUnit Test 370件、UI Test 10件が成功した。

## Files Expected to Change

- Allowed Changes記載の3ファイルのみ。

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

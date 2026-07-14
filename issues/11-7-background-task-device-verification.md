# [Device] BGTask実機確認手順を実施する

## Summary

BGProcessingTaskの登録、充電中実行、expiration、Foreground fallbackを実機で確認する手順と結果欄を定義する。

## Background

Platform、Application、Lifecycle、Unit Testは完了したが、BGTaskの実行時刻と電源条件はSimulator/Unit Testだけでは保証できない。

## Goal

実機で再現可能な検証手順を残し、実施できない環境では未確認項目を明確にする。

## Non-Goals

- OS実行時刻の保証
- 実機なしでの成功判定
- Production code変更

## Required Documents

- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/11-7-background-task-device-verification.md`

### Forbidden Changes

- Source、Project設定、Test、Signing変更

## Preconditions

1. iOS 17以上の署名済みiPhoneへDebug BuildをInstallする。
2. Xcode Debuggerを接続する。
3. 位置権限と必要な監視を許可し、pending日を用意する。
4. iPhoneを外部電源へ接続する。

## Device Procedure

1. アプリを起動し、launch登録が失敗せずForeground pending処理が動くことを確認する。
2. Homeへ戻してbackground移行し、`com.ryosukeue.DriveLog.processing`が予約されることを確認する。
3. Debuggerで次を実行し、OS task launchをsimulateする。

```text
expr -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.ryosukeue.DriveLog.processing"]
```

4. 古いpending日から最大3日が処理され、完了済み派生データが表示されることを確認する。
5. 処理中に次を実行してexpirationをsimulateする。

```text
expr -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.ryosukeue.DriveLog.processing"]
```

6. 現在処理が中断され、部分的な派生データが確定せず、次回ForegroundまたはBGTaskで再処理されることを確認する。
7. 外部電源を外した通常利用で、BGTaskに依存せずForeground起動時にpending日が1日処理されることを確認する。
8. SLC監視がbackground移行で停止しないことを確認する。

## Acceptance Criteria

- [ ] 実機でtask登録・予約を確認した。
- [ ] 充電中のsimulate launchでpending日処理を確認した。
- [ ] expirationで安全な中断と再実行を確認した。
- [ ] Foreground fallbackを確認した。
- [ ] background移行後もSLCが継続することを確認した。
- [x] Simulator Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 実機未実施項目を成功扱いにしていない。

## Decision / Deviations

- 現在の実行環境には署名済みiPhone操作とDebugger sessionがないため、実機5項目は未実施である。
- OSが実行時刻を保証しないため、通常待機での自動起動は合格条件にせず、Apple Debug simulate commandでhandlerを確認する。

## Verification Results

- Device: 未実施
- OS: 未実施
- Registration: 未確認
- Charging launch: 未確認
- Expiration: 未確認
- Foreground fallback on device: 未確認
- SLC continuity on device: 未確認
- Simulator regression: Unit Test 374件、UI Test 10件成功（2026-07-14）

## Files Expected to Change

- 本Issue文書のみ。

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

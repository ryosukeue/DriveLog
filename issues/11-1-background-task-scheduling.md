# [Platform] BackgroundTaskSchedulingを実装する

## Summary

BGProcessingTaskの登録、外部電源条件付き予約、取消をApple Frameworkの背後へ隠すPlatform基盤を実装する。

## Background

日別処理にはForeground fallbackがあるが、未処理日を充電中に処理するOS予約基盤が未実装である。

## Goal

Application層がBackgroundTasks型へ依存せず、登録・予約・取消を実行可能にする。

## Non-Goals

- pending日の処理Handler
- Lifecycleへの予約接続
- expiration時のApplication処理

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- DayProcessingCoordinator

## Scope

### Allowed Changes

- `issues/11-1-background-task-scheduling.md`
- `DriveLog/DriveLog/Platform/BackgroundTasks/BackgroundTaskScheduling.swift`
- `DriveLog/DriveLog/Platform/BackgroundTasks/SystemBackgroundTaskScheduler.swift`
- `DriveLog/DriveLogTests/Platform/BackgroundTaskSchedulingTests.swift`
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- `DriveLog/DriveLog/Info.plist`

### Forbidden Changes

- Application Coordinator、Lifecycle、UI変更
- Signing、Team、Bundle Identifier、Deployment Target変更
- 外部Package追加

## Requirements

1. 設計Signatureの`BackgroundTaskScheduling: Sendable`を定義する。
2. Production実装は`BGTaskScheduler`と`BGProcessingTaskRequest`を使用する。
3. task identifierは`com.ryosukeue.DriveLog.processing`とする。
4. Identifierを生成Info.plistの`BGTaskSchedulerPermittedIdentifiers`へ追加する。
5. `UIBackgroundModes`へ`processing`を追加する。
6. `requiresExternalPower`をRequestへ反映する。
7. Network接続を要求しない。
8. 同一Identifierのpending requestを予約前に取消す。
9. 取消操作は同一Identifierだけを対象にする。
10. ApplicationへBGTask型を漏らさない実行Task抽象を追加する。
11. Test Target内のFakeで登録回数、予約条件、失敗、取消を検証する。

## Privacy Requirements

- 外部通信、Analytics、個人情報Logを追加しない。

## Interface Contract

```swift
protocol BackgroundTaskScheduling: Sendable {
    func registerProcessingTask() throws
    func scheduleProcessingTask(requiresExternalPower: Bool) throws
    func cancelPendingProcessingTask()
}
```

## Implementation Constraints

- `BackgroundTasks` importはPlatform実装だけに置く。
- 実行時刻を保証するAPIを追加しない。
- `fatalError()`、force cast、force unwrapを追加しない。

## Acceptance Criteria

- [x] 登録、予約、取消がProtocol越しに利用できる。
- [x] 外部電源条件とnetwork不要条件が正しい。
- [x] permitted identifierが設定される。
- [x] Fake要件のUnit Testが成功する。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- Fakeの登録回数、予約条件、登録/予約失敗、取消回数。

## Decision / Deviations

- Applicationからexpiration/completionを扱えるよう、OS型を持たない`BackgroundProcessingTask`を補助Protocolとして追加する。
- Xcodeの生成Info.plistは任意の`INFOPLIST_KEY_*`を出力しないため、生成を維持しつつ配列キーだけをマージする最小Info.plistと同期GroupのResource除外を追加した。
- Build成果物でpermitted identifier配列と`UIBackgroundModes = processing`を確認した。
- 2026-07-14にUnit Test 369件、UI Test 10件が成功した。既存Swift 6 isolationおよびSimulator環境Warning以外に新規Warningはない。

## Files Expected to Change

- Allowed Changes記載の6ファイルのみ。

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

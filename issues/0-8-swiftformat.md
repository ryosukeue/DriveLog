# [Tooling] SwiftFormatを導入する

## Summary

Repository全体で再現可能なSwiftFormat Checkを実行できる状態を確定する。

## Background

`.swiftformat`は初期Repository作成時に導入済みで、インデント、カンマ、末尾空白、Swift versionが設定されている。Issue 0-8では既存設定が設計要件を満たすことと、全SwiftソースがCheckを通ることを確認する。

## Goal

`swiftformat --lint .`をローカルで実行でき、全Swiftソースが既存設定へ準拠する状態にする。

## Non-Goals

- SwiftLint設定の変更
- Build Phaseや外部PackageへのSwiftFormat追加
- 関係のないコードの大規模整形

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 0-7までのSwiftソースがSwiftFormat Checkを通ること。

## Scope

### Allowed Changes

- `issues/0-8-swiftformat.md`
- `.swiftformat`（検証で不足が判明した場合のみ）
- Issue 0-7までのSwiftソース（Check失敗箇所の最小整形のみ）

### Forbidden Changes

- Swiftコードの振る舞い変更
- `.swiftlint.yml`
- Xcode Project、Target、Scheme、Build Configuration
- Signing、Bundle Identifier、Development Team、Capability
- 外部Package、Build Phase
- 設計文書

## Requirements

1. Repository直下の`.swiftformat`を使用する。
2. 4スペースのインデントと末尾空白除去を設定する。
3. Swift 5.9として整形規則を評価する。
4. ローカルCheckは`swiftformat --lint .`で実行する。
5. 全既存SwiftソースがCheckを通る。
6. Check失敗がある場合のみ、対象Swiftファイルを最小整形する。
7. Swiftコードの振る舞いを変更しない。
8. 外部PackageやXcode Build Phaseを追加しない。

## Input

- Repository内のSwiftソースと`.swiftformat`

## Output

- 成功する`swiftformat --lint .`

## State Changes

- なし

## Error Handling

- Format違反がある場合、コマンドの非ゼロ終了を維持する。

## Privacy Requirements

- 個人情報を扱わない。

## UI Requirements

- なし

## Accessibility Requirements

- なし

## Processing Rules

- なし

## Data Model Rules

- なし

## Interface Contract

- なし

## Implementation Constraints

- 自動整形は違反ファイルだけに限定する。
- 関係のないコードを変更しない。
- ルールの大量無効化を行わない。

## Acceptance Criteria

- [ ] `.swiftformat`がRepository直下に存在する。
- [ ] `swiftformat --lint .`が成功する。
- [ ] Buildと全Testが成功する。
- [ ] SwiftLintが成功する。
- [ ] `git diff --check`が成功する。
- [ ] Swiftコードの振る舞い変更がない。
- [ ] 新規Warningと仕様外変更がない。

## Test Requirements

### Unit Tests

- 新規Testなし。既存全Testを実行する。

### Integration Tests

- なし

### UI Tests

- 既存UI Testが成功すること。

### Manual Tests

- `swiftformat --lint .`の終了コードを確認する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- `issues/0-8-swiftformat.md`

既存`.swiftformat`と全SwiftソースがすでにCheckを通るため、設定・ソース変更は不要と判断する。

## Files That Must Not Change

- `.swiftlint.yml`
- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- Signing関連ファイル

## Migration Requirements

- なし

## Performance Constraints

- なし

## Cancellation Behavior

- なし

## Logging Requirements

- なし

## Decisions

- `.swiftformat`は初期コミット`72ddba1`で既に導入済みであり、設計要件を満たすため変更しない。
- ローカル実行手順はこのIssueのCommandsへ記録する。

## Definition of Done

- [ ] GoalとAcceptance Criteriaを満たす。
- [ ] 全検証が成功する。
- [ ] 変更範囲が必要最小限である。

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
- Manual Test:

### Deviations

### Unresolved Issues

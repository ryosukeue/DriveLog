# [Tooling] SwiftLintを導入する

## Summary

Repository全体で危険なSwift記述と保守性上の問題を検出するSwiftLint設定を確定する。

## Background

`.swiftlint.yml`は初期Repository作成時に導入済みである。SwiftLintの標準ルールによりForce Cast、Force Try、長大関数・型・ファイル、循環的複雑度が検出され、設定でForce Unwrapも追加検出されている。

## Goal

`swiftlint lint --strict`をローカルで実行でき、全Swiftソースが危険記述と保守性ルールに違反しない状態にする。

## Non-Goals

- SwiftFormat設定の変更
- Xcode Build Phaseや外部PackageへのSwiftLint追加
- 警告回避を目的としたルールの大量無効化

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 0-8 SwiftFormat導入状態の確定

## Scope

### Allowed Changes

- `issues/0-9-swiftlint.md`
- `.swiftlint.yml`（検証で不足が判明した場合のみ）
- Issue 0-8までのSwiftソース（Lint違反の最小修正のみ）

### Forbidden Changes

- Swiftコードの振る舞い変更
- `.swiftformat`
- Xcode Project、Target、Scheme、Build Configuration
- Signing、Bundle Identifier、Development Team、Capability
- 外部Package、Build Phase
- ルールの大量無効化

## Requirements

1. Repository直下の`.swiftlint.yml`を使用する。
2. App、Unit Test、UI TestのSwiftソースを検査対象にする。
3. `.build`とDerivedDataを検査対象外にする。
4. Force CastとForce Tryを検出する。
5. Force Unwrapを検出する。
6. 長大関数、長大型、長大ファイル、循環的複雑度を検出する。
7. 未使用のParameter、Binding、Label等を標準Lintルールで検出する。
8. ローカルCheckは`swiftlint lint --strict`で実行する。
9. ルールの大量無効化やInline disableを追加しない。
10. 外部PackageやXcode Build Phaseを追加しない。

## Input

- Repository内のSwiftソースと`.swiftlint.yml`

## Output

- 成功する`swiftlint lint --strict`

## State Changes

- なし

## Error Handling

- Warningを含む違反がある場合、`--strict`により非ゼロ終了する。

## Privacy Requirements

- Lint対象へ実データを追加しない。

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

- 違反を隠すために設計を悪化させない。
- Rule disableは追加しない。
- 関係のないコードを変更しない。

## Acceptance Criteria

- [ ] `.swiftlint.yml`がRepository直下に存在する。
- [ ] 危険記述と長大コードの検出ルールが有効である。
- [ ] `swiftlint lint --strict`が成功する。
- [ ] Buildと全Testが成功する。
- [ ] SwiftFormat Checkが成功する。
- [ ] `git diff --check`が成功する。
- [ ] 新規Warningと仕様外変更がない。

## Test Requirements

### Unit Tests

- 新規Testなし。既存全Testを実行する。

### Integration Tests

- なし

### UI Tests

- 既存UI Testが成功すること。

### Manual Tests

- `swiftlint rules`で対象ルールの利用可能状態を確認する。
- `swiftlint lint --strict`の終了コードを確認する。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- `issues/0-9-swiftlint.md`

既存`.swiftlint.yml`が要件を満たし、全SwiftソースがStrict Lintを通るため、設定・ソース変更は不要と判断する。

## Files That Must Not Change

- `.swiftformat`
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

- `.swiftlint.yml`は初期コミット`72ddba1`で既に導入済みであり、標準ルールと`force_unwrapping` opt-inによりIssue要件を満たすため変更しない。
- `trailing_comma`の無効化はSwiftFormatのinline comma方針との競合を避ける既存の単一例外であり、大量無効化ではないため維持する。
- `unused_declaration`と`unused_import`はAnalyzerルールであり、通常の`lint --strict`契約とは別である。最終監査ではCompiler Warningと参照検索も併用する。

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

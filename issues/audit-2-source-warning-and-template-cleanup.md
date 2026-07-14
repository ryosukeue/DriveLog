# [Audit] Source Warningと初期テンプレートを除去する

## Summary

Clean test buildで検出されたSwift 6 isolation Warningと不要な`await`/`try`を解消し、未使用のXcode初期テンプレート`Item`を削除する。

## Required Documents

- [x] `docs/architecture.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Allowed Changes

- `issues/audit-2-source-warning-and-template-cleanup.md`
- `DriveLog/DriveLog/Item.swift`（削除）
- Warningに列挙されたDomain/Platform value型ファイル
- Warningに列挙されたUnit Testファイル

## Requirements

1. Sendable値型のEquatable準拠とproperty accessを`nonisolated`にする。
2. MainActor上の同期Test Double操作から不要な`await`を除く。
3. 非throwing concrete fake呼出しから不要な`try`を除く。
4. 未使用の初期テンプレート`Item`を削除する。
5. Production behavior、Schema、Project設定を変更しない。

## Acceptance Criteria

- [x] Clean test buildにSource Warningがない。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] `Item`初期テンプレートが残存しない。

## Decision / Deviations

- Apple toolchainのAppIntents metadata warningはSource Warningではないため環境由来として区別する。

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

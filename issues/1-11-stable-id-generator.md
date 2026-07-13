# [Domain] StableIDGeneratorを実装する

## Summary

MovementSegmentとStaySegmentへ、設計された丸め規則とSHA-256を使う決定的stableID生成を追加する。

## Goal

再処理後も同条件の区間を同じIDで識別し、Override再紐づけの第一候補にできるようにする。

## Non-Goals

- Override近似Matching
- Segment生成またはSwiftData保存
- SHA-256以外のID形式

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 1-1 Domain共通値

## Scope

### Allowed Changes

- `issues/1-11-stable-id-generator.md`
- `DriveLog/DriveLog/Domain/Identifiers/StableIDGenerating.swift`
- `DriveLog/DriveLog/Domain/Identifiers/SHA256StableIDGenerator.swift`
- `DriveLog/DriveLogTests/Domain/StableIDGeneratorTests.swift`

### Forbidden Changes

- 既存Domain Data、SwiftData Model、Mapper、Repository
- Processing、UI、Project設定
- Signing、CloudKit、外部Package

## Requirements

1. `StableIDGenerating: Sendable`を設計Signatureどおり定義する。
2. `SHA256StableIDGenerator`を状態を持たない`struct`として実装する。
3. Movement SeedをlocalDateKey、開始・終了時刻を1分へ丸めたUnix秒で作る。
4. Stay Seedへさらに緯度・経度を小数第4位へ丸めた固定小数文字列で加える。
5. SeedをUTF-8化しCryptoKit SHA-256の小文字64桁16進文字列にする。
6. Locale、TimeZone、端末設定へ依存しない。
7. 同じ丸め結果は同じID、異なるSeedは異なるIDになることを検証する。

## Acceptance Criteria

- [x] 同じ入力と同じ丸め範囲の入力が同じIDになる。
- [x] 開始・終了時刻、localDateKeyの差が反映される。
- [x] Stay座標の小数第4位丸め内外が反映される。
- [x] 出力が決定的な小文字64桁SHA-256である。
- [x] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規ソースWarningと仕様外変更がない。

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Decisions

- 「1分単位に丸める」はFoundation／Swift標準の最近接丸めとし、30秒境界は0から遠い整数分へ丸める。
- 座標SeedはPOSIX Localeの小数点と4桁固定表現を使用し、`-0.0`は`0.0`へ正規化する。

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
### Deviations
### Unresolved Issues

# [Data] SwiftData V1 Schemaを追加する

## Summary

`data-model.md`で固定された10個のV1永続ModelをSwiftData Modelとして追加する。

## Goal

生ログ、処理状態、派生データ、Override、Media CacheのV1 Fieldと一意性を永続化可能な形で定義する。

## Non-Goals

- VersionedSchema、Migration Plan、ModelContainer生成（Issue 1-7）
- Domain Mapper、Repository、PersistenceActor
- Relationship追加、CloudKit、外部Package

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 1-1〜1-5 Domain Data

## Scope

### Allowed Changes

- `issues/1-6-swiftdata-v1-models.md`
- `DriveLog/DriveLog/Data/Models/*.swift`（本Issueの10 Modelのみ）
- `DriveLog/DriveLogTests/Data/SwiftDataV1ModelTests.swift`

### Forbidden Changes

- Domain、Application、Shared、Platform、Feature、Processing
- Xcode初期テンプレート
- Project設定、Signing、Capability、CloudKit、外部Package

## Requirements

1. `data-model.md`記載の10 Modelを`@Model final class`として実装する。
2. Field名、型、Optional性をV1設計と一致させる。
3. 全Modelの`id`を一意にする。
4. `localDateKey`、`stableID`、`overrideKey`、`localIdentifier`の設計上の一意性を`@Attribute(.unique)`で表現する。
5. `deduplicationKey`と`visitMatchKey`は一意にしない。
6. EnumはModelへ直接保存せず設計通りRaw Valueを保存する。
7. Media本体、Thumbnail、Filename、Location Event ID列を保存しない。
8. Relationshipは任意仕様のためこのIssueでは追加せず、完全削除はlocalDateKey queryで保証する。
9. 初期値を隠す巨大Initializerは避け、全保存Fieldを明示的に注入可能にする。
10. Schema、Migration、Containerは追加しない。

## Acceptance Criteria

- [ ] 10 Modelと全V1 Fieldが存在する。
- [ ] 一意性と非一意Keyが設計通りである。
- [ ] 各Modelを生成して全Fieldを保持できる。
- [ ] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [ ] 新規Warning、TODO、仕様外変更がない。

## Test Requirements

- [ ] 全10 Modelの生成と必須・Optional Field保持
- [ ] 複数Motion flagの保持
- [ ] Location deduplicationKeyとVisit matchKeyの保持
- [ ] Mediaの位置なし・任意durationの保持

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- Issue文書、10 Modelファイル、Model Unit Test

## Files That Must Not Change

- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLog/ContentView.swift`
- `DriveLog/DriveLog/Item.swift`

## Migration Requirements

- VersionedSchemaとMigration PlanはIssue 1-7で追加する。
- 本IssueはDesigned V1 Fieldを変更しない。

## Privacy Requirements

- データは端末内だけに保存する。
- Logger、外部送信、CloudKitを追加しない。

## Decisions

- Optional仕様のRelationshipは追加せず、各ModelをlocalDateKeyで独立取得・完全削除できる構造を優先する。
- iOS 17互換性を維持し、より新しい`#Index` Macroは使用しない。

## Definition of Done

- [ ] Goal、Requirements、Acceptance Criteriaを満たす。
- [ ] Allowed Changes内だけを変更する。
- [ ] 全検証が成功する。

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

# [Privacy] Loggerと保存内容を監査する

## Summary

Loggerへ個人情報が流れず、SwiftDataへ保存する位置・経路・Media情報が設計済みV1 Schemaの必要最小限に限定されていることを監査する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/coding-rules.md`

## Scope

### Allowed Changes

- `issues/13-9-privacy-logger-storage-audit.md`
- Privacy違反が発見されたLogging、Model、Test

### Forbidden Changes

- Designed V1 Schemaの独自変更、Raw Log自動削除、Photos asset削除

## Requirements

1. Loggerへ座標、経路、PhotoKit identifier、Media filenameを渡さない。
2. LogEventを固定Caseと日付Key、件数、固定codeに限定する。
3. 関連値をprivateで出力する。
4. 写真・動画本体をSwiftDataへ保存しない。
5. V1 Schemaとの一致を確認する。

## Acceptance Criteria

- [x] Productionに`print`、`debugPrint`、`NSLog`がない。
- [x] Logger call siteに禁止データがない。
- [x] OSLog関連値がprivateである。
- [x] Media cacheに写真・動画本体やfilenameがない。
- [x] 保存内容がDesigned V1 Schemaと一致する。

## Decision / Deviations

- Production Swift全体を機械検索し、Logger実装1箇所とApplication call siteを監査した。
- 13 LogEvent Caseは固定eventのみで、文字列関連値と件数はすべて`privacy: .private`。座標・経路・identifier・filenameを受けるLogging APIはない。
- SwiftDataは設計どおりRaw座標、derived route data、Media localIdentifier/metadataを端末内へ保存するが、Media本体とfilenameは保存しない。これはPrivacy違反ではなくMVP機能に必要なDesigned V1 Schemaである。
- Schema Integration TestとLogging Testは直前の全Suiteで成功済み。修正を要する違反はなかった。

## Files Expected to Change

- `issues/13-9-privacy-logger-storage-audit.md`のみ。

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

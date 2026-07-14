# [Release] MVP Check Listを完了する

## Summary

設計文書、全PhaseのIssue、Production配線、Test結果を横断監査し、DriveLog MVPの自動検証可能な完了条件と実機確認残を確定する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Scope

### Allowed Changes

- `issues/13-17-mvp-check-list.md`
- 監査で発見した不具合は独立したAudit Issueで修正する。

### Forbidden Changes

- Signing、Team、Bundle Identifier、Deployment Target、Schemaの変更
- 実測していない実機項目の成功記録

## MVP Checklist

### Recording

- [x] Significant Location Change、Motion、Visit ProviderとRaw保存を実装
- [x] App launch／foreground／background lifecycleへProduction依存を接続
- [x] Raw Eventを自動削除せず保持
- [x] BGTask失敗時もforeground fallback可能
- [ ] 接続実機で長期Background記録を確認

### Processing

- [x] Sanitizing、日付境界分割、Segmentation、Stay Detection
- [x] 移動分類、Route simplification／label、日次集計
- [x] Revision、再処理、Override rematch
- [x] 1日想定上限データの性能Test

### Persistence and Deletion

- [x] Designed SwiftData Schema V1とMigration Plan
- [x] PersistenceActorによるSwiftData隔離
- [x] localDateKeyとUTC offsetを記録時に固定
- [x] 日付削除でRaw、Derived、Override、Media Cache、Processing Stateを完全削除
- [x] Photos assetを変更・削除しない

### UI and Correction

- [x] Calendar、Day Detail、Full Map、Callout、Media Grid
- [x] Photo／Video preview、Share、削除確認
- [x] Movement分類、Stay確定／非表示／自動へ戻す
- [x] Reprocessing、Empty、Error、Progress表示
- [x] Onboarding、段階的権限要求、拒否／Limited表示
- [x] iPhone SE〜Pro Max、Portrait、Light／Dark、Dynamic Type、VoiceOverの自動確認

### Privacy and Architecture

- [x] 外部server、login、analytics、third-party production dependencyなし
- [x] CloudKit／iCloud sync capabilityなし
- [x] Loggerへ座標、経路、PhotoKit identifier、filenameを出力しない
- [x] 写真・動画本体を永続化しない
- [x] Domain／Processingに禁止Apple Framework importなし
- [x] Productionに`fatalError()`、`try!`、`as!`、`print()`なし
- [x] Initial Xcode template model残存なし

### Quality

- [x] Debug Build成功
- [x] Release clean Build成功
- [x] Unit／Integration／UI／Performance Test成功
- [x] SwiftLint、SwiftFormat、Diff Check成功
- [x] Source Warningなし
- [x] Minimum iOS 17.0、iPhoneのみ、Portraitのみ
- [ ] 普通の外出、車移動、Media多用、深夜境界、TimeZone変更を接続実機で完了

## Acceptance Criteria

- [x] 自動検証可能なMVP要件をすべて満たす。
- [x] 発見したProduction lifecycle未接続、Source Warning、初期TemplateをAudit Issueで修正した。
- [x] Build、Test、Lint、Format、Diff Checkが成功する。
- [ ] 実機専用の長期・Background・TimeZone確認を完了する。

## Decision / Deviations

- PhotoKitのiCloud上のみの資産取得はIssue 8-1の明示仕様に従い、PhotoKit OS APIのnetwork accessだけを許可する。独自server通信やCloud同期はない。
- 実機専用項目は接続実機と現実の時間経過が必要なため未完了であり、成功扱いにしない。
- App Store archive、配布署名、Privacy回答、Store metadataはMVP code completion後の公開作業とする。

## Files Expected to Change

- `issues/13-17-mvp-check-list.md`のみ。

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

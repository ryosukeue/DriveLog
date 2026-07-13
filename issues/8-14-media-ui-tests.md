# [UI Test] Media主要導線を追加する

## Summary

決定的なDEBUG専用Photo Library Fixtureを使い、Day DetailのMedia Gridから写真・動画Preview、Error、地図Annotation／Clusterまでの主要導線をUI Testで検証する。

## Background

Phase 8の各機能はUnit Test済みだが、実Navigationを通したMedia導線はSimulator Photo Library状態に依存する。明示Launch Argumentとin-memory SwiftDataへ隔離したFixtureで、OS Photos UIを伴わない範囲を自動化する。

## Goal

写真・動画の表示、地図選択、Preview状態、基本Accessibilityが実App Navigation上で回帰しないことを保証する。

## Non-Goals

- OS Photos Picker／Limited Access管理画面の自動操作
- iCloud download、実動画デコード、共有先選択
- Screenshot／Screen Recording判定の重複UI Test（Unit Test済み）

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 8-1〜8-13
- 既存`-ui-testing-day-detail` in-memory Fixture

## Scope

### Allowed Changes

- `issues/8-14-media-ui-tests.md`
- `DriveLog/DriveLog/Application/AppContainer.swift`
- `DriveLog/DriveLog/DriveLogApp.swift`
- `DriveLog/DriveLogUITests/DriveLogUITests.swift`

### Forbidden Changes

- Release動作、SwiftData Schema、Domain／Processingルール変更
- Productionで有効なMock／Placeholder
- Photos Asset削除、外部通信
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. `-ui-testing-media`時だけin-memory Containerと既存日別Fixtureを使用する。
2. DEBUG buildだけで有効なPhoto Library Fixtureを注入する。
3. Fixtureは通常写真、動画、参照不能写真、位置あり／なしを含む。
4. Thumbnail、写真Preview、動画AVAsset、参照不能Errorを決定的に返す。
5. Production AppContainerはInitializer Injectionで任意Providerを受けられる。
6. UI TestでMedia Grid、写真／動画label、正方形セル導線を確認する。
7. 写真Preview、Metadata、Shareボタン、Navigation Backを確認する。
8. 動画Previewと参照不能Error／再試行を確認する。
9. Full MapのMedia AnnotationとClusterを確認し、AnnotationからPreviewへ遷移する。
10. Accessibility IdentifierとLabelを使用し、localIdentifierや座標をTest UIへ露出しない。

## Privacy / Isolation Requirements

- Fixtureは`#if DEBUG`かつ明示Launch Argument時だけ使用する。
- in-memory SwiftDataを使い、ユーザーデータへ書き込まない。
- localIdentifier、座標、ファイル名をLogger／Accessibilityへ出さない。
- 写真・動画本体を永続化せず、Photos Assetを削除しない。

## Acceptance Criteria

- [x] Media Gridから写真／動画Previewへ遷移できる。
- [x] 参照不能メディアがError／Retry表示になる。
- [x] 地図のMedia AnnotationからPreviewへ遷移できる。
- [x] 密集メディアのClusterが表示される。
- [x] FixtureがDEBUG・Launch Argument・in-memoryへ隔離される。
- [x] Build、Unit Test、UI Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- Calendar→Day Detail→Media Grid→Photo Preview→Back。
- Grid→Video Preview→Back→Unavailable Error／Retry。
- Day Detail→Full Map→Cluster／Media Annotation→Preview。
- 実PhotosのLimited Access、削除、iCloud、共有先は実機Manual Testへ残す。

## Decision / Deviations

- 実Photos DBをUI Testから操作せず、Platform ProtocolへDEBUG専用Fixtureを注入する。OS権限UIの不安定性を避けつつApplication／Feature／Navigationを通す。
- 動画FixtureはAVURLAssetによる表示状態を検証し、実デコード／標準Control操作は実機確認とする。

## Files Expected to Change

- Allowed Changes記載のIssue、Composition Root／DEBUG Fixture、UI Test。

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

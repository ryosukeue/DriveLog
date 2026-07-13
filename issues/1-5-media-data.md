# [Domain] Media Data型を追加する

## Summary

写真・動画の参照、表示適格性、地図配置をPhotoKit、UIKit、AVFoundation非依存のDomain値として追加する。

## Goal

Platform、Media Policy、UseCase、Presentation間でメディアMetadataだけを安全に受け渡せるようにする。

## Non-Goals

- PhotoKit取得、画像・動画本体、Thumbnail Cache
- Media Eligibility判定、地図配置計算
- SwiftData Cache Model、Repository、Mapper

## Required Documents

- [x] `docs/project-rules.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/data-model.md`
- [x] `docs/interfaces.md`
- [x] `docs/processing-rules.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`
- [x] `docs/implementation-plan.md`

## Dependencies

- Issue 1-1 `RouteCoordinate`

## Scope

### Allowed Changes

- `issues/1-5-media-data.md`
- `DriveLog/DriveLog/Domain/ValueObjects/MediaType.swift`
- `DriveLog/DriveLog/Domain/ValueObjects/MediaEligibility.swift`
- `DriveLog/DriveLog/Domain/Entities/MediaAssetReference.swift`
- `DriveLog/DriveLog/Domain/Entities/MediaPlacement.swift`
- `DriveLog/DriveLogTests/Domain/MediaDataTests.swift`

### Forbidden Changes

- PhotoKit、UIKit、AVFoundation実装
- SwiftData、Mapper、Repository、Processing、Feature
- 既存Domain型、Project設定、Signing、外部Package

## Requirements

1. 全型を`Sendable, Equatable`へ準拠させる。
2. `MediaType`はphotoとvideoを持つ。
3. `MediaEligibility`はeligibleとineligibleを持つ。
4. `MediaAssetReference`はlocalIdentifier、mediaType、任意のcreationDate・location・duration、screenshot・screen recording flagを保持する。
5. 写真・動画本体、Filename、UIImage、AVAsset、PHAssetを保持しない。
6. `MediaPlacement`はassetIdentifier、coordinate、任意の関連Movement stableIDを保持する。
7. 値型内でEligibility判定や配置計算を行わない。
8. DomainではFoundation以外をimportしない。

## Acceptance Criteria

- [ ] 4型が追加され全Case・Fieldを表現できる。
- [ ] 位置情報なし資産をReferenceで表現できる。
- [ ] Placementは位置情報を必須とする。
- [ ] 禁止Framework型をDomainへ漏らさない。
- [ ] Build、全Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [ ] 新規Warning、TODO、仕様外変更がない。

## Test Requirements

- [ ] MediaTypeとEligibilityの全Case・等価性
- [ ] Photo／Video、Optional metadata、除外flagの保持
- [ ] Placementの関連stableID有無
- [ ] 異なる値の非等価性とSendable準拠

## Commands

```bash
./scripts/build.sh
./scripts/test.sh
swiftlint lint --strict
swiftformat --lint .
git diff --check
```

## Files Expected to Change

- Allowed Changes記載の6ファイル

## Files That Must Not Change

- `DriveLog/DriveLog.xcodeproj/project.pbxproj`
- 既存Domain／Shared／Applicationファイル

## Privacy Requirements

- localIdentifier、座標をLoggerへ出力しない。
- Media本体やFilenameを保持・外部送信しない。

## Decisions

- Eligibility評価に必要なScreenshot／Screen Recording flagをReferenceへ含める。
- Cache固有のlocalDateKey、eligibility、lastValidatedAtはDomain参照型へ含めず、後続Data層で管理する。
- 関連区間は永続ModelのUUIDではなく再処理後も照合可能なMovement stableIDで表現する。

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

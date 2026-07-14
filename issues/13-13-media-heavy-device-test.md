# [Device] Media多用1日Testを実施する

## Summary

写真・動画・iCloud上のみ・Limited Photosを含むMedia多用日の取得、Grid、Map、Preview、Shareを実機確認する。

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/ui-spec.md`
- [x] `docs/test-plan.md`

## Scope

### Allowed Changes

- `issues/13-13-media-heavy-device-test.md`
- 実機で再現した不具合に直接関係する実装とTest

### Forbidden Changes

- Photos asset削除、Media本体永続化、実測なしの成功記録

## Requirements

1. 写真・動画・位置なし・iCloud上のみ・Limited選択変更を含める。
2. Screenshot/Screen Recording除外を確認する。
3. Grid、Map、Preview、Share、削除済みasset fallbackを確認する。
4. Photos assetが変更・削除されないことを確認する。

## Acceptance Criteria

- [ ] 接続実機と実Photos libraryで1日Testを完了する。
- [ ] 大量MediaでCrashせず、限定・削除変更を安全に扱う。
- [ ] Shareとvideo playbackを確認する。

## Decision / Deviations

- 実Photos library、iCloud download、Share Sheetの実機操作が必要なため自動実行不能。成功扱いにしない。
- Fake PhotoLibraryによるGrid/Map/Preview UI Test、eligibility/cache Unit/Integration Test、Memory metricは成功済み。

## Files Expected to Change

- 現時点では本Issue文書のみ。

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

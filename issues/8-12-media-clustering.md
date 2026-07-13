# [Map] Media Clusteringを実装する

## Summary

全画面地図で密集するメディアアノテーションをズームアウト時に件数クラスタへまとめ、選択時に含まれる範囲へズームする。

## Background

Issue 8-10／8-11で位置情報付きメディアの個別表示と配置が完成した。多数のサムネイルが同時に重なる場合も経路と地図操作を確認できるよう、MapKit標準Clusteringをメディアだけに適用する。

## Goal

地図縮尺に応じて密集メディアを読みやすいクラスタへ自動集約・展開できる。

## Non-Goals

- 独自クラスタリングアルゴリズム
- クラスタ内メディア一覧画面
- 区間／滞在アノテーションのクラスタリング

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 8-10 Media Annotation
- Issue 8-11 MediaPlacementCalculator

## Scope

### Allowed Changes

- `issues/8-12-media-clustering.md`
- `DriveLog/DriveLog/Features/Map/RouteMapAnnotationViews.swift`
- `DriveLog/DriveLog/Features/Map/RouteMapCoordinator+Annotations.swift`
- `DriveLog/DriveLogTests/Features/RouteMapAnnotationViewTests.swift`

### Forbidden Changes

- Domain、Processing、SwiftData Schema、PhotoKit処理の変更
- 区間／滞在のクラスタ化
- 独自メディア一覧Feature
- Project設定、Signing、Bundle Identifier、Team、Deployment Target変更
- 外部Package追加

## Requirements

1. 個別メディアViewだけへ固定`clusteringIdentifier`を設定する。
2. MapKitの画面上衝突判定により、ズームアウト時だけ密集メディアをまとめる。
3. クラスタは含まれるメディア件数を表示する。
4. クラスタに標準Marker表現を使用し、ライト／ダークで判別可能にする。
5. クラスタ選択時は全Member Annotationが見える範囲へ標準地図動作でズームする。
6. ズームイン時は個別サムネイルへ戻す。
7. 区間／滞在Viewには`clusteringIdentifier`を設定しない。
8. クラスタ件数以外のlocalIdentifier、座標、ファイル情報を表示・ログ出力しない。

## UI / Accessibility Requirements

- クラスタ表示は件数と標準Marker。
- Accessibility Labelは「N件の写真と動画」。
- Accessibility Identifierは`map.mediaCluster`。
- 選択領域はMapKit標準Markerの44pt以上。

## Error / Privacy Handling

- Memberが空の場合もクラッシュしない。
- 座標、経路、localIdentifierをLogger／Accessibilityへ出さない。
- 外部通信と永続化変更なし。

## Acceptance Criteria

- [x] メディアだけが共通Identifierでクラスタ対象になる。
- [x] クラスタが件数を表示し、選択でMember範囲へズームする。
- [x] 区間／滞在の既存操作へ影響しない。
- [x] Accessibility契約を満たす。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Test Requirements

- 個別メディアViewのclusteringIdentifier／collisionMode。
- クラスタViewの件数、Accessibility Label／Identifier。
- 非メディアViewがクラスタ対象外であること。
- 実縮尺での自動集約／展開はIssue 8-14と実機で確認する。

## Decision / Deviations

- 設計が許可する「標準クラスタ表示」を採用し、MapKitの衝突ベースClusteringへ委譲する。
- クラスタタップは独自一覧を作らず、`showAnnotations`による標準的な範囲ズームを優先する。
- 利用可能な`iPhone 17 (iOS 26.5)` SimulatorでUnit Test 324件、UI Test 6件が成功した。
- 実縮尺での自動集約／展開操作はIssue 8-14／最終実機確認対象とする。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtime、および既存型のSwift 6予告Warningは既存由来であり、本IssueのSource Code由来の新規Warningはない。

## Files Expected to Change

- Allowed Changes記載のIssue、Map Annotation UI／Coordinator、Unit Test。

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

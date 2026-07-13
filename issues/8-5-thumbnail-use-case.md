# [Application] Thumbnail UseCaseを実装する

## Summary

FeatureがPhotoKitを直接参照せず、要求サイズの写真・動画サムネイルをMainActor境界で取得できるUseCaseを追加する。

## Background

`PhotoLibraryProviding`はPhotoKitを隠蔽しているが、UIが直接Providerを呼ぶとApplication層を迂回する。スクロール時の同一要求を減らしつつ、画像を永続化しない薄いUseCaseが必要である。

## Goal

`localIdentifier`と`targetSize`から`UIImage`を非同期取得し、同一要求をメモリ内で再利用する。

## Non-Goals

- Media Grid UI
- Photo／Video Preview、Share Sheet
- サムネイルや画像本体のSwiftData／ファイル保存

## Required Documents

- [x] `docs/requirements.md`
- [x] `docs/architecture.md`
- [x] `docs/component-specs.md`
- [x] `docs/interfaces.md`
- [x] `docs/ui-spec.md`
- [x] `docs/coding-rules.md`
- [x] `docs/test-plan.md`

## Dependencies

- Issue 8-1 `PhotoLibraryProviding`

## Scope

### Allowed Changes

- `issues/8-5-thumbnail-use-case.md`
- `DriveLog/DriveLog/Application/Media/LoadMediaThumbnailUseCase.swift`
- `DriveLog/DriveLogTests/Application/LoadMediaThumbnailUseCaseTests.swift`
- `DriveLog/DriveLogTests/TestSupport/FakePhotoLibraryProvider.swift`

### Forbidden Changes

- PhotoKit ProviderのProduction実装変更
- SwiftData Schema、Repository、Project設定の変更
- Signing、Bundle Identifier、Team、Deployment Targetの変更
- 外部Package追加
- 画像の永続保存

## Requirements

1. `LoadMediaThumbnailUseCase`を設計どおり`@MainActor`、`AnyObject`のProtocolとして定義する。
2. `execute(localIdentifier:targetSize:) async throws -> UIImage`を実装する。
3. Production実装はInitializer Injectionされた`PhotoLibraryProviding`だけを呼ぶ。
4. localIdentifierと要求サイズの組み合わせをキーに`NSCache`へ保持する。
5. 同一キーの再要求はProviderを再度呼ばず、同一UIImageを返す。
6. localIdentifierまたはサイズが異なる要求は別キーとする。
7. 取得失敗をキャッシュせず、依存先Errorを保持する。
8. 空Identifier、0以下、非有限のサイズは`DriveLogError.invalidData`としProviderを呼ばない。
9. サムネイル、localIdentifier、メディア本体をSwiftDataやファイルへ保存しない。
10. `print()`、強制操作、自由文字列ログを追加しない。

## Input

- PhotoKit localIdentifier
- point単位のtargetSize

## Output

- 取得またはメモリキャッシュされた`UIImage`

## State Changes

- UseCaseインスタンス内の`NSCache`だけを更新する。

## Error Handling

- 入力不正は`DriveLogError.invalidData`。
- Providerの`DriveLogError`をそのまま返し、失敗結果は保存しない。

## Privacy Requirements

- localIdentifierや画像をログへ出力しない。
- 外部サーバーへ送信しない。
- 永続キャッシュを作らない。

## UI Requirements

- UI実装なし。UIKit型はApplicationのMainActor境界に限定する。

## Tests

- 初回要求がProviderへ渡る。
- 同一Identifier／サイズはメモリキャッシュを再利用する。
- Identifierまたはサイズが異なる場合は別要求となる。
- 不正入力ではProviderを呼ばない。
- Provider失敗をキャッシュせず再試行できる。

## Acceptance Criteria

- [x] 設計どおりのMainActor ProtocolとProduction実装がある。
- [x] 同一要求をNSCacheから返す。
- [x] 異なる要求を誤って共有しない。
- [x] 失敗や不正入力を安全に扱う。
- [x] 画像を永続保存しない。
- [x] Build、Test、SwiftLint、SwiftFormat、Diff Checkが成功する。
- [x] 新規Warningと仕様外変更がない。

## Decision / Deviations

- NSCacheの自動破棄性を利用し、公開された手動キャッシュ消去APIは設計にないため追加しない。
- AppIntents metadata skip、SimulatorのLLDB／Accessibility Runtimeメッセージ、および既存型のSwift 6予告Warningは既存の環境・コード由来であり、このIssueのSource Code由来の新規Warningはない。既存の予告Warningは最終監査で横断修正する。

## Files Expected to Change

- `issues/8-5-thumbnail-use-case.md`
- `DriveLog/DriveLog/Application/Media/LoadMediaThumbnailUseCase.swift`
- `DriveLog/DriveLogTests/Application/LoadMediaThumbnailUseCaseTests.swift`
- `DriveLog/DriveLogTests/TestSupport/FakePhotoLibraryProvider.swift`

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

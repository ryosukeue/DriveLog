# Issue Template

## 1. 目的

この文書は、DriveLogの実装Issueを作成し、Codexへ渡す際の共通テンプレートを定義する。

各Issueは、原則として1つの明確な目的だけを持つ。

Codexへ依頼するときは、このテンプレートを複製し、未記入欄を埋めてから渡す。

## 2. 基本ルール

- 1 Issueにつき1つの主目的
- 変更範囲を明示する
- 変更禁止範囲を明示する
- 受入条件を具体化する
- 必要なテストを先に定義する
- 関係する設計文書を指定する
- 実装後の報告形式を固定する
- 「ついでの改善」を禁止する
- 仕様が曖昧な場合は推測で拡張しない
- コンパイルエラー、テスト失敗、未完成TODOを残さない

## 3. Issue作成時の粒度

良いIssue例：

- LocationEventModelをV1 Schemaへ追加する
- RawEventRepositoryのLocation保存を実装する
- LocationSanitizerの重複除外を実装する
- Calendar画面へ月別距離を表示する
- 日付完全削除UseCaseを実装する
- 区間Calloutから分類Overrideを保存する

悪いIssue例：

- アプリ全体を作る
- 地図周りを全部実装する
- データ層を完成させる
- バグを全部直す
- コードをきれいにする
- パフォーマンスを改善する

1 Issueで変更対象が広すぎる場合は、設計、Model、Repository、UseCase、UI、Testへ分割する。

## 4. コピー用テンプレート

以下をそのまま複製して使用する。

---

# [Issue Title]

## Summary

<!--
このIssueで達成することを1〜3文で書く。
実装方法ではなく、完了後に何が可能になるかを書く。
-->

## Background

<!--
なぜこの変更が必要かを書く。
既存実装、前提Issue、仕様上の位置づけを簡潔に書く。
-->

## Goal

<!--
このIssueの主目的を1つだけ書く。
-->

## Non-Goals

<!--
このIssueでは実装しないことを書く。
関連しそうでも範囲外のものを明示する。
-->

- 
- 
- 

## Required Documents

実装前に次を読むこと。

- [ ] `docs/vision.md`
- [ ] `docs/requirements.md`
- [ ] `docs/architecture.md`
- [ ] `docs/component-specs.md`
- [ ] `docs/data-model.md`
- [ ] `docs/interfaces.md`
- [ ] `docs/processing-rules.md`
- [ ] `docs/ui-spec.md`
- [ ] `docs/coding-rules.md`
- [ ] `docs/test-plan.md`

このIssueに直接関係しない文書も、ArchitectureとCoding Rulesの確認のために読むこと。

## Dependencies

<!--
先に完了している必要があるIssue、型、Protocol、Featureを書く。
なければ「なし」と書く。
-->

- 

## Scope

### Allowed Changes

<!--
変更を許可するディレクトリ、ファイル、型を書く。
新規ファイルも書く。
-->

- 
- 
- 

### Forbidden Changes

<!--
このIssueで変更してはいけないものを書く。
-->

- Architectureの変更
- 既存Protocolの責務変更
- 外部ライブラリ追加
- 仕様外Feature追加
- 関係のないファイルの整形
- 
- 

## Requirements

<!--
実装要件を、観測可能な形で列挙する。
「適切に」「いい感じに」など曖昧な表現を避ける。
-->

1. 
2. 
3. 
4. 

## Input

<!--
この処理が受け取る値、状態、イベントを書く。
UI Issueの場合はユーザー操作を書く。
-->

- 

## Output

<!--
生成・保存・表示・通知する結果を書く。
-->

- 

## State Changes

<!--
SwiftData、ViewModel State、Processing Stateなどの変更を書く。
変更しない場合は「なし」。
-->

- 

## Error Handling

<!--
想定エラーと、呼び出し側へ返す結果を書く。
クラッシュさせないこと。
-->

- 
- 

## Privacy Requirements

<!--
座標、メディア、ログ、外部通信に関する条件を書く。
-->

- 正確な緯度・経度をLoggerへ出力しない
- PhotoKit localIdentifierをLoggerへ出力しない
- 外部サーバーへ送信しない
- 
- 

## UI Requirements

<!--
UI変更がない場合は「なし」。
ui-spec.mdから必要部分を具体的に転記する。
-->

- 

## Accessibility Requirements

<!--
UI変更がない場合は「なし」。
-->

- Accessibility Label:
- Accessibility Identifier:
- Dynamic Type:
- VoiceOver:
- Minimum tap area:

## Processing Rules

<!--
処理ロジックがない場合は「なし」。
processing-rules.mdの対象ルールと閾値を書く。
-->

- 

## Data Model Rules

<!--
Model変更がない場合は「なし」。
data-model.mdの対象Model、Property、Index、Relationshipを書く。
-->

- 

## Interface Contract

<!--
使用または実装するProtocolと関数Signatureを書く。
interfaces.mdと矛盾させない。
-->

```swift
// Required protocol or function signatures
```

## Implementation Constraints

- Swift Concurrencyを使用する
- Initializer Injectionを使用する
- ViewからRepositoryを直接呼ばない
- ViewModelからSwiftDataを直接呼ばない
- DomainへApple Frameworkをimportしない
- `fatalError()`、`try!`、`as!`を追加しない
- `print()`を追加しない
- 未完成TODOを残さない
- 新規Warningを増やさない
- 
- 

## Acceptance Criteria

<!--
すべてYes/Noで判定できる形にする。
-->

- [ ] 
- [ ] 
- [ ] 
- [ ] Buildが成功する
- [ ] 対象Unit Testが成功する
- [ ] 既存Testが失敗しない
- [ ] 新規Warningがない
- [ ] SwiftLintが成功する
- [ ] SwiftFormat Checkが成功する
- [ ] 仕様外の変更が含まれていない
- [ ] 未完成TODOが残っていない

## Test Requirements

### Unit Tests

<!--
条件と期待結果を列挙する。
-->

- [ ] 
- [ ] 
- [ ] 

### Integration Tests

<!--
RepositoryやSwiftData変更がない場合は「なし」。
-->

- [ ] 

### UI Tests

<!--
UI変更がない場合は「なし」。
-->

- [ ] 

### Manual Tests

<!--
実機確認が不要な場合は「なし」。
-->

- [ ] 

## Test Fixtures

<!--
必要なFake、Spy、Stub、固定日時、架空座標を書く。
-->

- Clock:
- TimeZone:
- Coordinates:
- Repository:
- Provider:
- Other:

## Commands

<!--
実際のScheme名・Destinationが決まった後で具体化する。
-->

```bash
# Build
xcodebuild build \
  -project DriveLog.xcodeproj \
  -scheme DriveLog \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Test
xcodebuild test \
  -project DriveLog.xcodeproj \
  -scheme DriveLog \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# SwiftLint
swiftlint

# SwiftFormat check
swiftformat --lint .
```

## Files Expected to Change

<!--
予想されるファイルを書く。
Codexは完了報告時に実際との差分を説明する。
-->

- 
- 
- 

## Files That Must Not Change

- 
- 
- 

## Migration Requirements

<!--
SwiftData Schema変更がない場合は「なし」。
-->

- Schema version:
- Migration Plan:
- Existing data behavior:
- Rollback behavior:

## Performance Constraints

<!--
性能条件がない場合は「通常操作でMain Threadを長時間占有しない」だけでよい。
-->

- MainActor上で重い処理をしない
- 全期間データを取得しない
- 
- 

## Cancellation Behavior

<!--
長時間処理がない場合は「なし」。
-->

- 

## Logging Requirements

<!--
発生させるLogEventを書く。
自由文字列ログを要求しない。
-->

- 
- 

## Definition of Done

- [ ] Goalを満たしている
- [ ] Non-Goalsへ踏み込んでいない
- [ ] Required Documentsに従っている
- [ ] Acceptance Criteriaをすべて満たす
- [ ] Test Requirementsをすべて満たす
- [ ] Build成功
- [ ] 新規Warningなし
- [ ] 個人情報をログへ出していない
- [ ] 変更範囲が最小限
- [ ] 実装説明と未解決事項が報告されている

## Completion Report Format

実装完了後、次の形式で報告すること。

### Summary

<!--
実装したことを3〜6行で説明。
-->

### Changed Files

<!--
ファイル単位で変更理由を書く。
-->

- `path/to/File.swift`
  - 

### Tests Added

- 
- 

### Verification

- Build:
- Unit Tests:
- Integration Tests:
- UI Tests:
- SwiftLint:
- SwiftFormat:
- Manual Test:

### Deviations

<!--
Issue記載と異なる点。
なければ「なし」。
-->

### Unresolved Issues

<!--
未解決事項。
なければ「なし」。
未完成実装をここへ逃がして完了扱いにしてはいけない。
-->

---

## 5. Codexへ渡すプロンプト形式

Issue本文の前に、次の指示を付ける。

```text
以下のIssueだけを実装してください。

実装前にIssueのRequired Documentsを読み、Architecture、Interfaces、Coding Rulesに従ってください。

Issueで許可されていない変更は行わないでください。
必要に見えても、Non-GoalsまたはForbidden Changesに含まれる内容は実装しないでください。

仕様に矛盾や不足がある場合は、独自仕様を追加せず、作業を止めて矛盾点を報告してください。

実装後は、Issue内のCompletion Report Formatで報告してください。
Build、Test、SwiftLint、SwiftFormat Checkを実行し、失敗した状態で完了扱いにしないでください。
```

その後に完成したIssue本文を貼る。

## 6. Issueタイトル規則

推奨形式：

```text
[Layer] Verb object
```

例：

```text
[Data] Add V1 SwiftData schema
[Data] Implement raw location event storage
[Processing] Sanitize duplicate location events
[Processing] Split movement segments
[Application] Process one local date
[UI] Show monthly calendar
[Map] Add movement segment callout
[Media] Refresh PhotoKit cache
[Test] Add day deletion integration tests
```

日本語で管理する場合も、対象Layerを先頭に付ける。

```text
[Processing] 重複位置点を除外する
[UI] 月間カレンダーを表示する
```

## 7. 推奨ラベル

GitHub等でIssue管理する場合の推奨ラベル：

```text
layer:application
layer:data
layer:domain
layer:platform
layer:presentation
layer:processing

type:feature
type:bug
type:refactor
type:test
type:docs
type:chore

priority:blocker
priority:high
priority:normal
priority:low

status:ready
status:blocked
status:in-progress
status:review
```

1 IssueへLayerラベルを複数付けすぎない。

複数Layerへ大きくまたがる場合はIssue分割を検討する。

## 8. Issue分割判断

次のいずれかに当てはまる場合は分割する。

- 変更予定ファイルが10件を大きく超える
- Model、Repository、UseCase、UIを同時に新規実装する
- Acceptance Criteriaが15件を大きく超える
- Unit TestとUI Testの両方が大規模になる
- 1回の変更でArchitecture境界を複数新設する
- Codexが変更範囲を説明しにくい
- Review時に一部だけ戻せない

分割例：

```text
悪い：
[Media] 写真機能を全部実装する

良い：
[Platform] PhotoKit資産取得Providerを実装する
[Data] MediaAssetCache Repositoryを実装する
[Application] Media Cache更新UseCaseを実装する
[UI] 日別詳細へ4列グリッドを追加する
[UI] 写真プレビューを追加する
[UI] 動画プレビューを追加する
[Application] 1件共有UseCaseを実装する
```

## 9. Bug Issue用追加項目

Bug修正Issueでは次を追加する。

```markdown
## Reproduction Steps

1.
2.
3.

## Actual Result

## Expected Result

## Reproducibility

- Always / Sometimes / Once
- Device:
- OS:
- App state:
- Permission state:

## Regression Test

- [ ] 修正前に失敗するTestを追加
- [ ] 修正後に成功することを確認
```

OS依存で自動再現できない場合は、Manual Test手順を具体的に書く。

## 10. Refactor Issue用追加項目

Refactor Issueでは次を追加する。

```markdown
## Behavior Preservation

このIssueでは外部動作を変更しない。

維持するもの：

- Public Interface
- User-visible behavior
- Persistence format
- stableID
- Override behavior
- Existing tests
```

受入条件には次を含める。

- [ ] 既存Testが変更前後で同じ結果
- [ ] Snapshotや保存形式を変更しない
- [ ] Feature追加を含めない
- [ ] RefactorとBug Fixを混在させない

## 11. Data Model Issue用追加項目

SwiftData Model変更時は次を必須にする。

```markdown
## Schema Impact

- Current schema:
- New schema:
- Added models:
- Changed properties:
- Changed relationships:
- Index changes:
- Delete rules:
- Migration behavior:
```

受入条件：

- [ ] Migration Plan更新
- [ ] 既存データ読込Test
- [ ] 空Database起動Test
- [ ] 保存・取得Test
- [ ] 削除Test
- [ ] Feature層へPersistentModelを公開しない

## 12. UI Issue用追加項目

UI Issueでは次を必須にする。

```markdown
## Screen States

- Loading:
- Loaded:
- Empty:
- Error:
- Reprocessing:
- Permission denied:

## Device Sizes

- iPhone SE equivalent:
- iPhone 15:
- Pro Max equivalent:

## Appearance

- Light:
- Dark:
- Dynamic Type:
- VoiceOver:
```

受入条件：

- [ ] `ui-spec.md`に従う
- [ ] Accent Colorは赤
- [ ] Dynamic Type対応
- [ ] Accessibility Identifier追加
- [ ] MainActor上で重い処理をしない
- [ ] ViewからRepositoryを呼ばない

## 13. Processing Issue用追加項目

Processing Issueでは次を必須にする。

```markdown
## Rules and Thresholds

- Rule:
- Threshold:
- Boundary behavior:
- Invalid input behavior:
- Cancellation behavior:
- Determinism requirement:
```

受入条件：

- [ ] `ProcessingConfiguration`を使用
- [ ] 閾値をハードコードしない
- [ ] MainActorへ依存しない
- [ ] SwiftDataへ依存しない
- [ ] 同じ入力で同じ結果
- [ ] 境界値Testあり
- [ ] 0件、1件、異常値Testあり

## 14. Repository Issue用追加項目

Repository Issueでは次を必須にする。

```markdown
## Persistence Operations

- Insert:
- Fetch:
- Update:
- Replace:
- Delete:
- Deduplication:
- Transaction:
```

受入条件：

- [ ] PersistenceActor内で実行
- [ ] SwiftData Modelを外部へ返さない
- [ ] 日付範囲を明示したQuery
- [ ] save回数を過剰に増やさない
- [ ] Integration Testあり
- [ ] 日付削除時の挙動確認

## 15. Issueレビュー前チェック

IssueをCodexへ渡す前に、人間が確認する。

- Goalが1つか
- Non-Goalsが書かれているか
- Allowed Changesが具体的か
- Forbidden Changesが具体的か
- Requirementsが曖昧でないか
- Acceptance CriteriaがYes/Noで判定できるか
- 必要なTestが列挙されているか
- Interface Signatureが既存文書と一致するか
- Processing閾値が文書と一致するか
- UI仕様が文書と一致するか
- 個人情報をFixtureへ要求していないか
- 実機確認が必要か判断されているか
- Completion Report Formatが残っているか

## 16. Codex完了報告レビュー

Codexの完了報告では次を確認する。

- Changed FilesがAllowed Changes内か
- Forbidden Changesへ触れていないか
- Build結果が具体的か
- Test結果が具体的か
- 実行していない項目を成功扱いしていないか
- Deviationsが隠されていないか
- 未解決事項をTODOでコードへ残していないか
- 新しい外部依存がないか
- Warningが増えていないか
- 仕様と異なる独自改善がないか

「おそらく動く」「実行できなかったが問題ない」は完了条件を満たさない。

## 17. 最小Issue例

```markdown
# [Processing] 低精度位置点を除外する

## Summary

水平精度がMVP閾値を超える位置点を、派生処理の対象から除外する。

## Goal

LocationSanitizerが`horizontalAccuracy > 500m`の位置点を除外できる。

## Non-Goals

- 生ログ削除
- 重複判定
- 座標ジャンプ判定
- 閾値変更UI

## Allowed Changes

- `Processing/LocationSanitizer.swift`
- `Processing/ProcessingConfiguration.swift`
- `DriveLogTests/Processing/LocationSanitizerTests.swift`

## Forbidden Changes

- SwiftData Model
- Repository
- UI
- 外部ライブラリ

## Requirements

1. `horizontalAccuracy == 500m`は有効とする
2. `horizontalAccuracy > 500m`は除外する
3. 除外理由は`poorAccuracy`とする
4. 入力配列を変更しない
5. 結果順序をtimestamp昇順にする

## Acceptance Criteria

- [ ] 500mが有効
- [ ] 500.1mが除外
- [ ] 除外理由が`poorAccuracy`
- [ ] 入力が不変
- [ ] Unit Test成功
- [ ] Build成功
- [ ] Warningなし
```

この程度まで範囲を絞ると、Codexが変更対象を判断しやすい。

## 18. MVP完了条件

- すべての実装Issueがこのテンプレートを基準に作成される
- GoalとNon-Goalsが明示されている
- Allowed ChangesとForbidden Changesが明示されている
- Acceptance Criteriaが客観的に判定できる
- Test Requirementsが事前に定義されている
- Codexが変更範囲外の作業をしない
- 実装後の報告形式が統一されている
- Build、Test、Lint、Formatの結果を確認できる
- 未完成TODOを残したIssueを完了扱いにしない
- Bug修正にRegression Testが付く
- Data、UI、Processing、Repositoryの追加項目を使い分けられる

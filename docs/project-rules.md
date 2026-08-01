# Project Rules

## 実機フィードバックによる優先ルール（2026-08-01）

この節は後続のMovement表示に関する旧記述より優先する。

- Production UIは徒歩系Movementだけを非表示とし、車両系と`other`のMovementを日別・月間の地図、距離、時間へ表示する。分類変更UIは引き続き表示しない。

## 実機フィードバックによる優先ルール（2026-07-15）

この節は後続の旧記述「月送りは左右スワイプのみ」「Significant Location Changeのみ」より優先する。

- Locationは非充電時SLCを基本とし、車両系Activityを候補として短時間の標準Locationで実移動を確認した後だけ単一Managerの走行Modeへ昇格する。充電中/満充電だけでは高精度Modeへ切り替えず、走行確定後の補助情報として扱う。車両系Activity終了後は短い猶予を置いてSLCへ戻し、常時高精度は禁止する。
- Calendarは縦方向の連続月Sectionとし、横Swipe月送りを使用しない。
- Movement分類変更と詳細統計はProduction UIへ表示しない。既存Schema/Overrideデータは削除しない。
- Stay修正と位置情報付きMedia Annotationは維持する。

## 1. 目的

この文書は、DriveLog Repository全体で常に適用する最上位の作業ルールを定義する。

Codexを含む実装者は、Issueへ着手する前にこの文書を読む。

この文書は詳細仕様を再掲するものではなく、各設計文書の読み方、変更時の行動、禁止事項、完了条件を短く固定するためのものである。

## 2. プロジェクト概要

DriveLogは、iPhone上で移動履歴を低消費電力で自動記録し、日単位で経路、移動区間、滞在、写真・動画を振り返るアプリである。

MVPの前提：

- iPhoneのみ
- iOS 17以降
- SwiftUI
- SwiftData
- Significant Location Change
- Core Motion
- CLVisit
- PhotoKit
- オンデバイス処理
- サーバーなし
- ログインなし
- 広告なし
- サブスクリプションなし
- iCloud同期なし
- 高精度GPSの無条件常時取得なし
- AI画像解析なし

## 3. 文書の優先順位

仕様を判断するときは、次の順で参照する。

1. 現在のIssue
2. `project-rules.md`
3. `vision.md`
4. `requirements.md`
5. `architecture.md`
6. `component-specs.md`
7. `data-model.md`
8. `interfaces.md`
9. `processing-rules.md`
10. `ui-spec.md`
11. `coding-rules.md`
12. `test-plan.md`
13. `implementation-plan.md`
14. `issue-template.md`

### 優先順位の解釈

- Issueは作業範囲と受入条件を定義する
- Project Rulesは全作業共通の禁止事項と手順を定義する
- Requirementsは何を実現するかを定義する
- ArchitectureとInterfacesは責務と依存方向を定義する
- Data Modelは保存形式を定義する
- Processing Rulesは判定ロジックと閾値を定義する
- UI Specは表示と操作を定義する
- Coding Rulesは実装方法を定義する
- Test Planは検証方法を定義する
- Implementation Planは実装順を定義する

文書間に矛盾がある場合、独自解釈で実装しない。

矛盾箇所、影響範囲、選択肢を報告する。

## 4. 作業開始前の必須手順

Issue着手前に次を行う。

1. Issue全文を読む
2. Required Documentsを読む
3. Allowed Changesを確認する
4. Forbidden Changesを確認する
5. 関連Protocolと既存実装を確認する
6. 関連Testを確認する
7. 変更予定ファイルを列挙する
8. 依存方向がArchitectureに従うことを確認する
9. 仕様に不足や矛盾がないか確認する
10. Buildが開始前に通るか確認する

開始前からBuildが失敗している場合は、その事実を記録する。

Issueと無関係な既存不具合を勝手に修正しない。

## 5. 変更範囲

Issueで許可された範囲だけを変更する。

### 原則

- 1 Issueにつき1つの主目的
- 変更ファイルを最小限にする
- 無関係な整形をしない
- 無関係な命名変更をしない
- 無関係なリファクタをしない
- 仕様外機能を追加しない
- 将来機能のための過剰な抽象化をしない

### 範囲外変更が必要な場合

次を報告し、独自判断で続行しない。

- 必要な変更理由
- 変更対象ファイル
- Architectureへの影響
- Data Modelへの影響
- Testへの影響
- Issue分割の必要性

## 6. Architectureルール

依存方向：

```text
Presentation / Feature
        ↓
Application / UseCase
        ↓
Domain Protocol / Data
        ↓
Data・Platform Implementation
```

### 必須

- Viewは表示と操作受付だけを担当する
- ViewModelはUseCaseを呼ぶ
- UseCaseは処理を組み合わせる
- Repositoryは保存・取得を担当する
- Platform ServiceはApple Frameworkとの接続を担当する
- Processingは判定・計算を担当する
- DomainはOS固有型を知らない
- AppContainerはComposition Rootだけを担当する
- 依存はInitializer Injectionで渡す

### 禁止

- ViewからRepositoryを呼ぶ
- ViewModelからSwiftDataを直接呼ぶ
- ViewModelからPhotoKitを直接呼ぶ
- DomainへCore Locationをimportする
- DomainへCore Motionをimportする
- DomainへPhotoKitをimportする
- DomainへMapKitをimportする
- DomainへSwiftDataをimportする
- Platform ServiceからSwiftDataへ直接保存する
- RepositoryへUIロジックを入れる
- ProcessingへOS APIを入れる
- 巨大な汎用Managerへ責務を集約する
- 独自Singletonを作る
- Service Locatorを導入する

## 7. データルール

### 生ログ

- Location、Motion、Visitは生ログとして保存する
- 通常処理で生ログを変更しない
- 通常処理で生ログを削除しない
- 日付完全削除時だけ削除する
- 派生データは生ログから再生成可能にする

### 日付

- 各イベントへ記録時のTimeZone identifierを保存する
- 各イベントへ記録時のUTC offsetを保存する
- 各イベントへ`localDateKey`を保存する
- `localDateKey`形式は`YYYY-MM-DD`
- 過去ログを現在のTimeZoneで再分類しない
- 日付境界で区間を分割する

### Revision

- 単純なprocessed Boolを使わない
- `rawRevision`と`processedRevision`を使用する
- Raw Event追加時にrawRevisionを更新する
- processedRevisionが追いついていない日は再処理対象
- 処理中にrawRevisionが変わった場合は再処理対象へ残す

### Override

- 自動判定とユーザー修正を分離する
- 再処理でOverrideを削除しない
- stableID一致を優先する
- 近似再紐づけはProcessing Rulesに従う
- 複数候補がある場合は自動適用しない

### Media

- 写真・動画本体をSwiftDataへ保存しない
- Thumbnailを永続保存しない
- PhotoKit localIdentifierと最小メタデータだけを保存する
- PhotoKit側で削除された参照はCacheから削除する
- 日付削除でPhotos資産を削除しない

## 8. Processingルール

判定値をコードへ直接散在させない。

すべて`ProcessingConfiguration`へ集約する。

MVP主要値：

```text
重複：30秒以内かつ10m以内
最大水平精度：500m
最大妥当速度：250km/h
連続区間最大Gap：90分
最小区間距離：100m
滞在最小時間：3分
自動滞在候補：5分
滞在半径：150m
有効移動日：合計1km以上
経路簡略化：30m
MediaとRouteの関連付け：500m
```

### 必須

- 同じ入力と設定から同じ結果を生成する
- 空入力を正常に扱う
- 位置点1件を正常に扱う
- 全位置点除外を正常に扱う
- キャンセル時に途中結果を保存しない
- 日全体の平均速度を生成しない
- 最高速度を生成しない
- 自動automotiveを自家用車と断定しない

## 9. UIルール

MVPの主要画面：

```text
月間カレンダー
→ 日別詳細
→ 全画面地図
→ 写真・動画プレビュー
```

### 必須

- Accent Colorは赤
- ダークモードは端末設定に従う
- 今日の日付は青丸
- 月送りは左右スワイプのみ
- Calendarは日付と距離だけを表示
- 有効移動日のみ日別詳細へ遷移
- Day DetailはMap、Summary、Detail、Media Gridの順
- Media Gridは原則4列
- 区間と滞在はMap Callout
- Mediaは全画面Preview
- LoadingはProgressView
- 再集計中も既存データを表示
- 日付削除は右上Menuと確認Dialog
- iPhone SE相当からPro Maxへ対応
- Dynamic Type対応
- VoiceOver対応
- Portraitのみ

### 禁止

- タブバー追加
- FAB追加
- Settings画面追加
- Bottom Sheetによる区間・滞在詳細
- Snapshot Test前提のUI実装
- 位置情報なしMediaの地図仮配置
- 航空写真切替追加
- 横画面対応追加

## 10. Privacyルール

DriveLogの個人データは端末内で処理する。

### 禁止

- 位置情報を外部送信する
- 写真・動画を外部送信する
- Analytics SDKを追加する
- 広告SDKを追加する
- Crash Reportへ座標を含める
- Loggerへ正確な緯度・経度を出す
- Loggerへ経路を出す
- LoggerへPhotoKit localIdentifierを出す
- Loggerへ写真・動画名を出す
- テストFixtureへ個人の実移動履歴を入れる
- 共有一時ファイルを残す

日付キー、処理件数、固定エラーコードはログへ出してよい。

## 11. Codingルール

### 使用するもの

- Swift Concurrency
- async/await
- AsyncStream
- Actor
- @MainActor
- Initializer Injection
- Logger / OSLog
- SwiftFormat
- SwiftLint

### 原則禁止

- `fatalError()`
- `preconditionFailure()`
- `try!`
- `as!`
- 不要な強制アンラップ
- `print()`
- `debugPrint()`
- `NSLog()`
- 独自Completion Handler
- Semaphore
- Blocking Wait
- `Thread.sleep`
- 無条件の`DispatchQueue.main.async`
- `@unchecked Sendable`
- `nonisolated(unsafe)`
- Warningの無視
- Deprecated APIの新規使用

必要な例外は、理由と安全性をコメントする。

### サイズ

- 300行超で分割を検討する
- 500行超の本番Swiftファイルは禁止
- 通常関数は30〜40行以内を目安とする
- 100行超の通常関数は禁止

## 12. 外部依存

サードパーティライブラリを独自追加しない。

追加が必要な場合は、次を提示する。

- 追加理由
- 標準Frameworkで代替できない理由
- ライセンス
- 保守状況
- Binary Size
- Privacyへの影響
- 削除可能性
- Test方法

承認前にPackage Dependencyを追加しない。

## 13. SwiftData変更

Model変更時は必ず次を行う。

1. `data-model.md`を確認
2. Schema Versionへの影響を確認
3. Migration Planを更新
4. Data Mapperを更新
5. Integration Testを追加
6. 空Database起動を確認
7. 既存データ読込を確認
8. Delete Ruleを確認
9. 日付削除への影響を確認

Feature層へPersistentModelを公開しない。

Model変更だけで済むIssueにUI変更を混ぜない。

## 14. OS Framework変更

### Core Location

- Significant Location Changeを基本とする
- 車両系Activityを候補としてGPSの実移動を確認した後だけ走行Modeを開始する
- 充電状態だけでは高精度GPSを開始しない
- Background受信を保証しない
- 強制終了後の記録を保証しない
- DelegateをPlatform層へ閉じる

### Core Motion

- 全raw flagを保存する
- 1つのprimary categoryへ潰さない
- 権限拒否でLocation記録を止めない

### CLVisit

- 到着だけの未完了Visitを扱う
- 出発判明後に同一Visitを更新する
- Visit未発生を失敗扱いにしない

### PhotoKit

- Screenshotを除外する
- Screen Recordingを除外する
- その他は確実に除外できない限り残す
- Limited Accessを通常状態として扱う
- 削除済みAssetでクラッシュしない

### BGTask

- 実行時刻を保証しない
- Foreground fallbackを必須とする
- Expiration時に途中結果を保存しない
- BGTaskが動かなくてもアプリを利用可能にする

## 15. Testルール

新規ロジックにはTestを追加する。

### 必須対象

- Processing
- UseCase
- Repository主要操作
- stableID
- Date / TimeZone
- Route Encoding
- Override Matching
- Media Eligibility
- Day Deletion
- Error Conversion

### Repository変更

SwiftDataのインメモリIntegration Testを追加する。

### UI変更

主要導線をUI Testする。

Snapshot TestはMVPで必須にしない。

### 不具合修正

1. 修正前に失敗するRegression Testを追加
2. 修正を実装
3. Test成功を確認
4. 関連Testを再実行

### 禁止

- 不安定TestをSkipして完了扱い
- 無条件sleep
- 実時計依存
- 実Photo Library依存
- 実位置情報依存
- 実行順依存
- Testを通すための仕様変更
- 理由のない既存Test削除

## 16. 作業中のルール

- 変更は小さく保つ
- 各段階でBuild可能な状態を保つ
- コンパイルエラーを長時間放置しない
- 既存の公開Interfaceを理由なく変更しない
- 新規Protocolを作る前に既存Protocolを確認する
- 同じロジックを複製しない
- 未使用コードを残さない
- Debug専用コードをReleaseへ含めない
- 個人座標をSample Dataへ入れない
- TODOで必須実装を隠さない
- 仕様外改善を実装しない

## 17. 仕様不足・矛盾時の行動

次の場合は推測で実装しない。

- 文書間で数値が異なる
- Interface Signatureが文書と既存コードで異なる
- IssueのAcceptance CriteriaとRequirementsが矛盾する
- Data Modelに必要Propertyがない
- UI Specに状態が定義されていない
- Privacy要件に抵触する可能性がある
- Migrationが必要か判断できない
- 変更範囲外の修正が必要

報告内容：

```text
矛盾箇所
影響するファイル
実装を続けた場合のリスク
考えられる選択肢
推奨案
```

仕様が明確な範囲まで実装可能なら、その範囲だけ完了させ、残りを明示する。

## 18. Buildと検証

Issue完了前に、対象環境で次を実行する。

```text
Build
Unit Test
Integration Test
対象UI Test
SwiftLint
SwiftFormat Check
```

実行できなかった項目は、成功扱いにしない。

次を記録する。

- 実行Command
- 使用Scheme
- 使用Destination
- 成功件数
- 失敗件数
- Warning件数
- 未実行理由

実機確認が必要なIssueでは、Manual Test結果も記録する。

## 19. 完了条件

次をすべて満たすまで完了扱いにしない。

- IssueのGoalを満たす
- Non-Goalsへ踏み込んでいない
- Acceptance Criteriaを満たす
- Allowed Changes内に収まる
- Build成功
- 必要なTest成功
- 既存Test成功
- 新規Warningなし
- SwiftLint成功
- SwiftFormat Check成功
- 未完成TODOなし
- 外部依存追加なし
- Architecture違反なし
- Privacy違反なし
- 仕様外機能なし
- 変更内容を説明できる
- 未解決事項を隠していない

## 20. 完了報告

実装後は次の形式で報告する。

```markdown
## Summary

## Changed Files

## Tests Added

## Verification

- Build:
- Unit Tests:
- Integration Tests:
- UI Tests:
- SwiftLint:
- SwiftFormat:
- Manual Test:

## Deviations

## Unresolved Issues
```

### 報告上の禁止

- 実行していないTestを成功と書く
- Warningを無視する
- Deviationsを省略する
- 未完成実装を隠す
- 「おそらく動く」で完了扱いにする
- 変更ファイルを省略する

## 21. Gitルール

Conventional Commitsを使用する。

```text
feat:
fix:
refactor:
test:
docs:
chore:
perf:
build:
ci:
```

例：

```text
feat(calendar): show daily movement distance
fix(processing): reject implausible location jump
test(data): add complete day deletion coverage
```

1コミットへ無関係な変更を混ぜない。

生成物、DerivedData、個人設定、署名情報、個人FixtureをCommitしない。

## 22. Codex用開始指示

CodexへIssueを渡すときは、Issue本文の前に次を付ける。

```text
このIssueだけを実装してください。

最初にdocs/project-rules.mdとIssue内のRequired Documentsを読んでください。

Allowed Changes以外は変更しないでください。
Forbidden Changes、Non-Goalsに含まれる内容は実装しないでください。
ついでのリファクタや仕様外改善を行わないでください。

文書、Issue、既存コードに矛盾がある場合は、独自解釈で仕様を追加せず、矛盾点と影響範囲を報告してください。

実装後はBuild、必要なTest、SwiftLint、SwiftFormat Checkを実行し、IssueのCompletion Report Formatで報告してください。
失敗、Warning、未実行項目、仕様との差異を隠さないでください。
```

## 23. Codex用最終チェック

完了報告前に自己確認する。

### Scope

- Issue外の変更をしていないか
- 無関係な整形をしていないか
- 独自機能を追加していないか

### Architecture

- ViewがRepositoryを呼んでいないか
- ViewModelがSwiftDataを触っていないか
- DomainがApple Frameworkへ依存していないか
- Repositoryが判定ロジックを持っていないか
- Platformが保存処理を持っていないか

### Data

- Raw Eventを変更していないか
- Overrideを失っていないか
- localDateKeyを再計算していないか
- Media本体を保存していないか
- Photos資産を削除していないか

### Safety

- Force Unwrapを追加していないか
- `try!`を追加していないか
- `as!`を追加していないか
- `fatalError()`を追加していないか
- `print()`を追加していないか
- 個人情報をLoggerへ出していないか

### Quality

- Build成功か
- Test成功か
- Warningなしか
- Lint成功か
- Format Check成功か
- 未完成TODOなしか
- 変更理由を説明できるか

## 24. MVP外の機能

次をIssueへ明示的に追加しない限り実装しない。

- iCloud同期
- サーバー同期
- ログイン
- 位置共有
- SNS機能
- ランキング
- 自転車専用分類
- 地点名
- Memo
- 無条件の高精度GPS切替
- 道路Map Matching
- 住所逆引き
- AI画像解析
- AI分類
- 複数Media共有
- Settings画面
- Tab Bar
- Widget
- Watch App
- iPad対応
- 横画面
- 航空写真切替
- 日全体平均速度
- 最高速度
- Trash
- Restore
- 自動Raw Log削除

## 25. 最終原則

DriveLogでは、機能数より次を優先する。

1. 生ログを失わない
2. 誤判定を断定しない
3. ユーザー修正を維持する
4. 個人データを外へ出さない
5. バックグラウンド処理に依存しすぎない
6. OS制約を無視しない
7. 責務境界を崩さない
8. 同じ入力から同じ結果を作る
9. 小さなIssueで安全に積み上げる
10. 動作確認していないものを完成扱いにしない

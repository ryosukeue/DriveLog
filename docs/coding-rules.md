# Coding Rules

## 1. 目的

この文書は、DriveLogの実装規約を定義する。

目的は次のとおり。

- 責務境界を維持する
- AIによる過剰変更を防ぐ
- 実装品質を一定に保つ
- テスト可能性を維持する
- コンパイル可能な状態を保つ
- 将来の変更範囲を狭くする

この文書は、実装時に他の設計文書と同等に優先して参照する。

## 2. 基本原則

- 1つの型は1つの主責務だけを持つ
- Viewは表示に専念する
- ViewModelはUseCaseを呼ぶ
- UseCaseは処理の流れを組み立てる
- Repositoryは保存・取得を担当する
- ServiceはApple Frameworkとの接続を担当する
- Processingは判定・計算を担当する
- DomainはOS固有APIへ依存しない
- 生ログは、ユーザーによる日付削除以外で変更しない
- 派生データは生ログから再生成可能にする
- ユーザー修正は自動判定と分離する
- 同じ処理を複数回実行しても重複しない
- バックグラウンド処理が必ず動く前提にしない

## 3. 対象言語と環境

- Swift
- SwiftUI
- iOS 17以降
- SwiftData
- Swift Concurrency
- Xcode標準ツール
- サードパーティライブラリは原則追加しない

新しい外部依存を追加する場合は、理由、代替案、ライセンス、保守性、バイナリサイズへの影響を文書化し、承認を得る。

Codexが独自判断で外部ライブラリを追加してはならない。

## 4. レイヤー別ルール

# 4.1 Presentation / View

Viewの責務は表示とユーザー操作の受け取りだけとする。

許可：

- ViewModelの状態表示
- Navigation
- Button、Menu、Alert、Sheet
- 標準的な表示フォーマット
- 軽微なレイアウト分岐
- Accessibility設定

禁止：

- SwiftData直接操作
- `ModelContext`取得
- Core Location直接操作
- Core Motion直接操作
- PhotoKit直接操作
- MapKitデータ生成
- 距離計算
- 区間分割
- 滞在判定
- 自動分類
- stableID生成
- 日付キー生成
- Repository直接呼び出し
- 長い非同期処理

View内で複雑な計算が必要になった場合は、ViewModel、Formatter、Builder、UseCaseへ移動する。

# 4.2 ViewModel

ViewModelの責務は次とする。

- UseCase呼び出し
- UI状態管理
- 画面遷移用データ管理
- ユーザー操作の受付
- ユーザー向けエラーへの変換
- MainActor上の状態更新

禁止：

- SwiftData直接操作
- PhotoKit直接操作
- Core Location直接操作
- Core Motion直接操作
- `CLLocationManager`生成
- `PHAsset`検索
- 距離計算
- 滞在判定
- 区間分割
- MapScene生成ロジック
- 日別処理パイプライン実装

ViewModelは原則`@MainActor`とする。

依存するUseCaseはInitializer Injectionで受け取る。

# 4.3 UseCase

UseCaseの責務は、1つのユーザー操作またはアプリ操作を完了させること。

例：

- 月間カレンダー取得
- 日別詳細取得
- 日別処理
- 分類修正
- 滞在修正
- 日付削除
- メディアキャッシュ更新

許可：

- Repositoryの組み合わせ
- Processingの呼び出し
- エラー変換
- トランザクション単位の調整
- ログ出力

禁止：

- SwiftUI View生成
- UIKit表示
- `MKMapView`直接操作
- `UIActivityViewController`直接表示
- ビジネスルールの重複実装
- Repository内部実装への依存

UseCase名は動詞から始める。

例：

- `LoadCalendarMonthUseCase`
- `DeleteDayLogUseCase`
- `RefreshMediaCacheUseCase`

# 4.4 Repository

Repositoryの責務はデータ保存・取得・置換・削除だけとする。

許可：

- SwiftData Query
- ModelとDomain Dataの変換
- 一意性維持
- 重複保存防止
- 日付単位のトランザクション
- rawRevision更新
- Visitの同一候補更新

禁止：

- UIロジック
- ViewModel状態更新
- 自動分類
- 滞在判定
- 経路簡略化
- 地図用Callout生成
- 写真サムネイル生成
- 権限要求

Repository ProtocolはSwiftData Modelを公開しない。

# 4.5 Platform Service

ServiceはApple Frameworkとの橋渡しだけを担当する。

例：

- Core Location
- Core Motion
- CLVisit
- PhotoKit
- BGTaskScheduler
- UIActivityViewController
- MapKit

許可：

- DelegateからAsyncStreamへの変換
- OS型からDomain Dataへの変換
- OS権限状態取得
- OSイベント受信

禁止：

- SwiftData直接保存
- 日別集計
- 移動分類
- 滞在判定
- Repository操作
- UI状態保持
- 画面遷移

Platform Serviceは、受信イベントを保存せず、上位へ通知する。

保存はUseCaseまたはCoordinator経由でRepositoryが行う。

# 4.6 Processing

Processing Componentは、入力から出力を生成する判定・計算を担当する。

例：

- LocationSanitizer
- MovementSegmenter
- StayDetector
- MovementClassifier
- RouteSimplifier
- RouteLabelPlacementService
- DaySummaryBuilder

方針：

- 純粋関数に近づける
- SwiftDataへ直接アクセスしない
- MainActorへ依存しない
- OS APIへ依存しない
- 入力と設定が同じなら結果を同じにする
- Clockが必要な場合は注入する
- 閾値をハードコードしない
- `ProcessingConfiguration`を使用する

## 5. Dependency Injection

依存性注入はInitializer Injectionを使用する。

例：

```swift
final class CalendarViewModel {
    private let loadCalendarMonth: any LoadCalendarMonthUseCase

    init(loadCalendarMonth: any LoadCalendarMonthUseCase) {
        self.loadCalendarMonth = loadCalendarMonth
    }
}
```

禁止：

- グローバル変数
- 独自Singleton
- `static let shared`
- Service Locator
- View内での具体実装生成
- UseCase内部でのRepository具体実装生成

Apple Frameworkが提供するSingleton APIを内部で使う場合でも、上位層にはProtocol経由で公開する。

`AppContainer`はComposition Rootとしてのみ使用する。

ViewへAppContainer全体を渡さない。

## 6. Access Control

基本方針：

- 最小限の公開範囲にする
- 原則`internal`
- 型内部の実装は`private`
- 継承を想定しない型は`final`
- Framework化しない限り`public`を使わない
- テストのためだけにアクセス範囲を広げない

推奨：

```text
ViewModel依存：private
ViewModel状態：private(set)
UseCase依存：private
Repository内部ModelContext：private
Helper関数：private
```

テスト対象の純粋ロジックは、別型またはinternal APIとして分離する。

## 7. Swift Concurrency

非同期処理はSwift Concurrencyを使用する。

優先：

- `async`
- `await`
- `Task`
- `AsyncStream`
- `Actor`
- `@MainActor`

原則禁止：

- `DispatchQueue.main.async`
- 独自Completion Handler
- Semaphore
- Blocking Wait
- `Thread.sleep`
- `NSLock`の直接利用

例外：

Apple Frameworkの都合でDispatchQueueが必要な場合は、Platform層内部に限定し、理由をコメントする。

### Task

Viewから非同期処理を開始する場合は、SwiftUIの`.task`またはViewModel内の管理されたTaskを使用する。

長時間Taskは保持し、必要に応じてキャンセルする。

```swift
private var loadTask: Task<Void, Never>?
```

不要になったTaskを放置しない。

### Cancellation

時間のかかる処理はキャンセルを確認する。

```swift
try Task.checkCancellation()
```

キャンセルは`DriveLogError.cancelled`または`CancellationError`として通常失敗と区別する。

### Actor

SwiftDataアクセスはPersistenceActorへ集約する。

同じ責務のために複数Actorを独自作成しない。

## 8. MainActor

MainActorを付ける対象：

- ViewModel
- UI状態
- UIKit表示
- Share Sheet
- UIImage表示
- AVPlayerのUI管理
- MKMapView更新

MainActorを付けない対象：

- Repository Protocol
- Processing
- 距離計算
- 区間分割
- 滞在判定
- stableID生成
- Route Encoding
- 日別サマリー生成

安易に型全体へ`@MainActor`を付けてコンパイルエラーを回避しない。

## 9. Error Handling

### 9.1 禁止

本番コードで次を使用しない。

- `fatalError()`
- `preconditionFailure()`
- 強制アンラップによるクラッシュ
- `try!`
- `as!`
- 意味のない`catch {}`

ユーザー権限不足、データなし、PhotoKit資産削除、BGTask未実行は異常終了条件ではない。

### 9.2 assertionFailure

開発時しか発生しない設計違反には`assertionFailure()`を使用してよい。

例：

```swift
assertionFailure("Unexpected route payload version")
```

その後も安全なフォールバックを返す。

### 9.3 DriveLogError

上位層へ公開するエラーは`DriveLogError`へ変換する。

元エラーをそのままUIへ渡さない。

ユーザー向け文言はPresentation層で生成する。

### 9.4 Optional

Optionalが正当な状態を表す場合は、エラーへ変換しない。

例：

- speedが取得できない
- VisitのdepartureDateが未確定
- メディアに位置情報がない
- 日別集計がまだない

### 9.5 Resultの扱い

`async throws`で表現できる処理に`Result`を重ねない。

Stream内で成功・失敗をイベントとして扱う場合だけ、列挙型または`AsyncThrowingStream`を使用する。

## 10. Logging

ログはAppleの`Logger`、`OSLog`を使用する。

禁止：

- `print()`
- `debugPrint()`
- `NSLog()`
- 自由文字列による座標出力
- PhotoKit localIdentifier出力
- 写真・動画ファイル名出力

Logging Protocolを経由し、`LogEvent`を使用する。

ログレベル：

- debug：開発中の詳細状態
- info：正常な重要イベント
- error：失敗、再試行対象

### Privacy

正確な緯度・経度、経路、メディア内容、ユーザー分類内容をログに残さない。

日付キーと件数はログへ残してよい。

エラーコードは個人情報を含まない固定値にする。

## 11. Naming

### 型

PascalCaseを使用する。

```text
DayAggregateData
LocationMonitoringService
LoadDayDetailUseCase
```

### 変数・関数

camelCaseを使用する。

```text
localDateKey
loadDayDetail()
isReprocessing
```

### Boolean

状態が分かる接頭辞を使用する。

- `is`
- `has`
- `can`
- `should`

例：

```text
isVisible
hasValidMovement
canOpenDetail
shouldRetry
```

曖昧な名前は禁止。

```text
flag
data
value
temp
item
manager
helper
```

ただし文脈上明確なローカル変数は例外とする。

### Protocol

責務に応じて接尾辞を使用する。

- `Providing`
- `Repository`
- `Building`
- `Calculating`
- `Detecting`
- `Classifying`
- `Scheduling`
- `Managing`
- `UseCase`

### 具体実装

技術または保存方式を名前へ含める。

```text
CoreLocationProvider
PhotoKitLibraryProvider
SwiftDataRawEventRepository
DefaultMapSceneBuilder
```

### SwiftData Model

永続モデルには`Model`を付ける。

```text
LocationEventModel
MovementSegmentModel
```

Domain Dataと永続Modelを同名にしない。

## 12. File Organization

原則として、主要な型は1ファイル1型とする。

例外：

- 小さな関連Enum
- 小さなValue Object
- Preview用補助型
- テスト専用Fixture

ファイル名は主要型名と一致させる。

```text
CalendarViewModel.swift
LocationSanitizer.swift
DriveLogError.swift
```

### ファイル行数

- 300行を超えたら分割を検討する
- 500行を超える本番Swiftファイルは禁止
- 生成コードは例外
- Markdown文書は対象外

行数を減らすためだけに不自然な分割をしない。

責務単位で分割する。

## 13. Function Size

1関数は原則30〜40行以内を目安とする。

長くなる場合は次を確認する。

- 複数責務が混在していないか
- 分岐が多すぎないか
- 別の型へ移動すべき処理ではないか
- 純粋関数へ分割できないか

禁止：

- 100行を超える通常関数
- 深いネスト
- 巨大な`switch`
- 1関数内で取得、加工、保存、UI更新をすべて行うこと

Guard Clauseを優先する。

## 14. Comments

コメントは「なぜ」を説明するために使用する。

良い例：

```swift
// SLCは位置点が粗いため、500m未満へ厳しくすると有効点を失いやすい。
```

悪い例：

```swift
// 距離を計算する
let distance = ...
```

公開Protocolや重要なDomain RuleにはDoc Commentを付けてよい。

コメントが実装と矛盾した場合は、実装変更時に必ず更新する。

不要な日本語・英語の二重コメントは避ける。

## 15. TODO / FIXME / HACK

形式を統一する。

```swift
// TODO: 実機ログ確認後に閾値を再評価する。
// FIXME: iOS 17で限定アクセス変更後に一覧更新が遅れる。
// HACK: MapKitのCallout制約回避。削除条件をIssue #123に記載。
```

人名を必須にしない。

TODOには、可能ならIssue番号または削除条件を記載する。

禁止：

- 完了条件不明のTODO
- ビルドを通すだけのTODO
- 実装漏れをTODOで隠す
- `TODO: later`
- `TODO: fix`

MVPの必須機能をTODOのまま完了扱いにしない。

## 16. Force Unwrap and Cast

原則禁止：

```swift
value!
try!
object as!
```

例外：

- コンパイル時に必ず存在することが明白なテストコード
- AppleテンプレートのPreview
- 起動時固定リソースで、欠落がビルド設定ミスを示す場合

例外使用時は理由をコメントする。

本番データ、権限、PhotoKit、位置情報には使用しない。

## 17. Data Conversion

SwiftData ModelをFeatureへ直接渡さない。

変換方向：

```text
SwiftData Model
→ Data Mapper
→ Domain Data
→ Presentation Data
```

Mapperでビジネス判定を行わない。

単位変換、表示文字列生成はFormatterまたはPresentation用Mapperへ分離する。

## 18. Date and Time

禁止：

- `Date()`の直接乱用
- `TimeZone.current`の直接乱用
- 現在タイムゾーンによる過去イベント再分類
- 手書きの`YYYY-MM-DD`文字列連結

使用：

- `Clock`
- `TimeZoneProviding`
- `LocalTimeContextProviding`
- 専用Formatter

DateFormatterを大量生成しない。

必要なら共有Formatterを値型ラッパーまたは専用Formatting Componentにまとめる。

## 19. Units

DomainとPersistenceではSI単位を使用する。

- 距離：m
- 時間：s
- 速度：m/s

UIでのみ次へ変換する。

- km
- 分
- 時間
- km/h

変数名へ単位を含める。

良い例：

```text
distanceMeters
durationSeconds
speedMetersPerSecond
```

悪い例：

```text
distance
time
speed
```

## 20. Collection Handling

大量データを一度にMainActorへ渡さない。

日付単位、月単位で取得する。

Repository Queryは対象範囲を明示する。

禁止：

- 全期間のLocationEventを毎回取得
- Calendar表示のために生ログを取得
- メディアグリッド表示のために写真本体を全件読み込み
- Viewのbody内で重いmap/filter/sortを繰り返す

## 21. SwiftData Rules

- `ModelContext`はPersistenceActor内に閉じる
- Viewで`@Query`を使用しない
- FeatureがPersistentModelを知らない構造にする
- 日別置換はトランザクション的に行う
- 保存は必要な単位でまとめる
- ループ内で毎回saveしない
- 派生データの途中状態を保存しない
- Schema Versioningを維持する
- Model変更時はMigration Planを更新する

MVPでCloudKit連携を有効にしない。

## 22. PhotoKit Rules

- `PHAsset`をDomainへ渡さない
- localIdentifierだけを参照IDとして保存する
- 写真・動画本体をSwiftDataへ保存しない
- サムネイルを永続保存しない
- 共有用ファイルは一時保存とし、完了・キャンセル後に削除する
- 削除済み資産でクラッシュしない
- 限定アクセスを通常状態として扱う
- スクリーンショット・画面収録以外を過剰に除外しない

## 23. Core Location and Motion Rules

- SLCだけを使用する
- 高精度GPSを開始しない
- ViewやViewModelからManagerを生成しない
- Delegate処理をPlatform層に閉じる
- 受信コールバックで重い処理をしない
- 受信時は保存要求とdirty化だけを行う
- Core Motion権限失敗で位置記録を停止しない
- CLVisitが来ないことをエラー扱いにしない

## 24. Map Rules

- MapSceneを経由する
- Domain Dataを直接MKMapViewへ渡さない
- PreviewとFullで描画ロジックを共有する
- Callout生成をViewModelへ埋め込まない
- ポリライン選択判定はMap Platform層へ閉じる
- 地図上の位置情報なしメディア仮配置は禁止
- 地図表示のために道路補正APIを呼ばない

## 25. UI Rules

- iOS標準コンポーネントを優先する
- Accent Colorは赤
- ダークモードは端末設定に従う
- 横向き対応を追加しない
- タブバーを追加しない
- 設定画面を追加しない
- FABを追加しない
- Skeleton UIを追加しない
- Bottom Sheetを区間・滞在詳細へ使わない
- 区間・滞在詳細はCalloutを使用する
- メディアグリッドは原則4列
- Dynamic Typeを無効化しない
- 固定高さで文字を切らない

## 26. Formatter and Lint

SwiftFormatとSwiftLintを導入する。

### SwiftFormat

目的：

- インデント
- 空白
- 改行
- 一貫したコード形式

### SwiftLint

目的：

- 危険な記述の検出
- 長すぎる型・関数の検出
- Force Cast、Force Tryの検出
- 未使用コードの検出

導入時は、警告を大量に無効化しない。

ルール違反を避けるために設計を悪化させない。

設定ファイル：

```text
.swiftformat
.swiftlint.yml
```

Codexがルールを無効化する場合は、理由をコメントと変更説明へ記載する。

## 27. Build Warnings

新規警告を残さない。

禁止：

- 警告を無視して完了
- `@unchecked Sendable`で安易に抑制
- `nonisolated(unsafe)`で安易に抑制
- 未使用変数を`_`で隠して未完成処理を残す
- Deprecated APIの新規使用

既存警告がある場合は、変更によって増えていないことを確認する。

## 28. Sendable

Concurrency境界を越えるData型は可能な限り`Sendable`にする。

参照型を`Sendable`にする必要がある場合は、可変状態と同期方法を確認する。

`@unchecked Sendable`は原則禁止。

使用する場合は次を明記する。

- なぜ安全か
- 可変状態がどこで保護されるか
- 代替案がなぜ不適切か

## 29. Testing Rules

### 必須

新規追加または変更時にUnit Testが必要な対象：

- UseCase
- Processing Component
- Repositoryの重要Query
- stableID生成
- Route Encoding
- 日付キー生成
- Override再紐づけ
- 日付削除
- メディア判定
- エラー変換

### UI Test

主要ユーザーフローだけを対象とする。

- カレンダーから日別詳細
- 全画面地図
- Callout
- メディアプレビュー
- 日付削除
- 権限拒否表示

### 不要

MVPではSnapshot Testを必須としない。

単純なComputed Propertyだけのために過剰なテストを増やさない。

### Test Naming

テスト名は条件と期待結果が分かる形式とする。

```swift
func test_processDay_whenDistanceIsBelowOneKilometer_marksDayInvalid()
```

### Test Independence

- 実行順に依存しない
- 現在時刻に依存しない
- 現在タイムゾーンに依存しない
- 実際のPhoto Libraryに依存しない
- 実際の位置情報に依存しない
- ネットワークに依存しない

## 30. Preview and Sample Data

SwiftUI Previewは本番Repositoryを使用しない。

Preview用の固定データを使用する。

Previewデータは次へ配置する。

```text
Shared/PreviewSupport/
```

本番ターゲットへ個人の位置データや写真情報を含めない。

## 31. Git Rules

Conventional Commitsを使用する。

形式：

```text
type(scope): summary
```

例：

```text
feat(calendar): add monthly movement distance display
fix(processing): prevent duplicate location insertion
refactor(data): split raw and derived repositories
test(stay): add traffic-stop classification cases
docs(architecture): update media placement policy
chore(lint): add SwiftLint configuration
```

使用するtype：

- `feat`
- `fix`
- `refactor`
- `test`
- `docs`
- `chore`
- `perf`
- `build`
- `ci`

1コミットへ無関係な変更を混ぜない。

大規模変更前にリファクタだけのコミットを分ける。

生成物、DerivedData、個人用設定をコミットしない。

## 32. Branch and Change Scope

1 Issueにつき1つの主目的とする。

変更範囲をIssueに記載する。

Codexは、Issueで許可された範囲外のファイルを原則変更しない。

範囲外変更が必要な場合は、実装前に理由と対象ファイルを提示する。

ついでのリファクタは禁止。

## 33. Codex向け必須ルール

Codexは実装開始前に次を読む。

1. `vision.md`
2. `requirements.md`
3. `architecture.md`
4. `component-specs.md`
5. `data-model.md`
6. `interfaces.md`
7. `processing-rules.md`
8. `ui-spec.md`
9. `coding-rules.md`
10. 対象Issue

### 禁止

- 既存Architectureを独自変更する
- DomainへApple Frameworkをimportする
- ViewからRepositoryを直接呼ぶ
- ViewModelからSwiftDataを直接呼ぶ
- 外部ライブラリを勝手に追加する
- 高精度GPSを追加する
- iCloud同期を追加する
- 設定画面を追加する
- タブバーを追加する
- 仕様外の機能を追加する
- 未完成コードをTODOで残す
- コンパイルエラーを残す
- テスト失敗を残す
- 警告を増やす
- 既存テストを理由なく削除する
- テストを通すために仕様を変える
- 巨大な汎用Managerを作る
- 同じロジックを複数箇所へ複製する
- Issueと無関係なファイルを整形する
- 既存のユーザー修正保存方式を変更する
- stableIDルールを独自変更する
- 位置情報なしメディアを地図へ仮配置する

### 必須

- 変更前に関連ファイルを確認する
- 既存Protocolを優先して使用する
- 変更範囲を最小化する
- 新規ロジックへテストを追加する
- Buildを実行する
- Testを実行する
- 変更内容をファイル単位で説明する
- 未解決事項を明示する
- 仕様矛盾がある場合は推測で実装せず報告する

## 34. 完了条件

Issueを完了とみなす条件：

- 要求された機能が実装されている
- Architectureの依存方向を守っている
- Buildが成功する
- 既存Testが成功する
- 必要な新規Testが追加されている
- 新規Warningがない
- Force Unwrap、Force Try、Force Castを増やしていない
- `print()`を追加していない
- 仕様外の依存を追加していない
- TODOで未完成部分を残していない
- 変更範囲がIssueに一致している
- 関連文書と実装が矛盾していない

## 35. レビュー時チェックリスト

### Responsibility

- Viewにロジックが入っていないか
- ViewModelがRepositoryを直接呼んでいないか
- Repositoryに判定処理が入っていないか
- Serviceが保存処理をしていないか
- ProcessingがOS APIへ依存していないか

### Safety

- 強制アンラップがないか
- エラーを握り潰していないか
- 個人情報をログへ出していないか
- キャンセルを無視していないか
- MainActorで重い処理をしていないか

### Data

- 生ログを変更していないか
- Overrideを失う処理になっていないか
- 日付キーを現在タイムゾーンで再計算していないか
- 派生データの途中状態を保存していないか
- 日付削除で写真・動画を削除していないか

### UI

- 赤Accent Colorに従っているか
- Dynamic Typeで切れないか
- SE相当からPro Maxまで破綻しないか
- Callout仕様に従っているか
- 権限拒否時に設定導線があるか

### Quality

- 型や関数が大きすぎないか
- 命名が責務を表しているか
- 重複ロジックがないか
- テストが条件と期待結果を表しているか
- 変更と無関係な整形が含まれていないか

## 36. MVP完了条件

- レイヤーごとの責務がコード上で分離されている
- Initializer Injectionだけで依存が渡されている
- 独自Singletonが存在しない
- Swift Concurrencyを基本としている
- `fatalError()`、`try!`、`as!`を本番コードで使用していない
- `print()`を使用していない
- Loggerが個人情報を記録しない
- ViewとViewModelがSwiftDataへ直接依存しない
- DomainがApple Frameworkへ依存しない
- SwiftFormatとSwiftLintが導入されている
- 500行を超える本番Swiftファイルがない
- 新規UseCaseとProcessingにUnit Testがある
- Conventional Commitsを使用できる
- Codexが変更範囲と設計文書に従って実装できる

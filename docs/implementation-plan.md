# Implementation Plan

## Phase 14: 実機フィードバック改善（完了）

- [x] 14-1 Polyline/Location段階診断と不要分断修正
- [x] 14-2 充電中限定の高精度Location Mode
- [x] 14-3 Media Annotation表示修正と診断
- [x] 14-4 Movement分類変更UI削除（Schema互換維持）
- [x] 14-5 Stay Override UI整理
- [x] 14-6 詳細統計UI削除
- [x] 14-7 Calendar縦連続Scroll
- [x] 14-8 地図/写真中心のUI整理
- [x] 14-9 Integration監査と実機Checklist

## Phase 17: 車両系Activityと充電補助の記録Mode統合

- [x] 17-1 車両移動検知と記録Modeを統合する
- [x] 17-2 車両ActivityをGPS移動で確認してから記録を確定する

### Phase 17方針

非充電時のSignificant Location Changeを基本にし、Core Motionの車両系Activityを候補として標準Locationで実移動を確認した後だけ走行Modeへ昇格する。充電中／満充電だけでは高精度Modeへ切り替えず、走行確定後の補助情報として扱う。Activity終了後は3分の猶予を置き、短時間停止やActivityの揺れで経路を不要に分断しない。外部BLEビーコン、OBD-II、CarPlay、専用GPSはMVPへ追加しない。

## 1. 目的

この文書は、DriveLog MVPを安全に実装するためのPhase構成、Issue分割、依存関係、完了条件、Codexへ渡す順序を定義する。

実装は一度に全体を作らず、土台、記録、処理、表示、補助機能の順に積み上げる。

各Issueは`issue-template.md`を使用し、Codexへは原則1回につき1 Issueだけ渡す。

## 2. 実装方針

全体の順序は次とする。

```text
プロジェクト基盤
→ Domain / Data Model
→ Platform監視
→ 生ログ保存
→ Processing
→ 日別処理
→ カレンダー
→ 日別詳細
→ 全画面地図
→ 写真・動画
→ ユーザー修正
→ 日付削除
→ バックグラウンド処理
→ オンボーディング
→ 品質仕上げ
```

### 基本原則

- 下位層から上位層へ実装する
- 1 Issueにつき1つの主責務
- Model、Repository、UseCase、UIを同時に大規模実装しない
- 既存Protocolを先に定義し、その後具体実装を作る
- 各Processing ComponentへUnit Testを同時に追加する
- SwiftData変更にはIntegration Testを付ける
- UIは内部処理が完成してから追加する
- BGTaskはForeground fallback完成後に追加する
- 実機確認が必要なPhaseは完了条件に含める
- Phase途中でもBuild可能な状態を保つ

## 3. Codexへ渡す単位

Codexへは原則1 Issueだけ渡す。

推奨規模：

- 変更ファイル：1〜5件程度
- 新規型：1〜3個程度
- 1 Protocolまたは1 UseCase単位
- Unit Testを同じIssueに含める
- UIと内部処理は別Issue
- 大規模MigrationとFeature実装は別Issue

1 Issueで10件を大きく超えるファイル変更が見込まれる場合は分割する。

## 4. Phase共通完了条件

各Phaseは次を満たすまで次へ進まない。

- Build成功
- 対象Unit Test成功
- 対象Integration Test成功
- 既存Test成功
- 新規Warningなし
- SwiftLint成功
- SwiftFormat Check成功
- 未完成TODOなし
- Phaseで定義したInterfaceが確定
- 仕様外の変更なし
- 実機確認が必要な場合は完了
- 完了報告が`issue-template.md`形式に従っている

## 5. Phase 0：プロジェクト基盤

### 目的

DriveLogの最小構成、依存注入、共通エラー、ログ、時刻依存、Lint環境を整える。

Xcode Project自体は人間が作成する。

### 前提

- iOS 17+
- iPhoneのみ
- SwiftUI App Lifecycle
- SwiftData有効
- Portraitのみ
- App名、Module名は仮で`DriveLog`
- Accent Colorは赤

### Issue一覧

#### 0-1 `[Foundation] プロジェクト設定を確認する`

内容：

- Deployment TargetをiOS 17以上へ設定
- iPhoneのみ
- Portraitのみ
- Accent Colorを赤へ設定
- 不要なCapabilityを追加しない
- CloudKitを無効
- 外部ライブラリなし

完了条件：

- iPhone 15 Simulatorで起動
- 横向きにならない
- 赤Accent Colorが反映
- Warningなし

#### 0-2 `[Foundation] フォルダ構成を作成する`

作成：

```text
Application/
Features/
Domain/
Data/
Platform/
Processing/
Shared/
```

補助構成：

```text
Shared/Errors/
Shared/Logging/
Shared/Time/
Shared/Formatting/
Shared/PreviewSupport/
```

空のPlaceholder型を大量に作らない。

#### 0-3 `[Foundation] DriveLogErrorを実装する`

対象：

- `DriveLogError`
- `PermissionKind`
- エラー変換用最低限Helper
- Unit Test

`interfaces.md`の定義に従う。

#### 0-4 `[Foundation] Logging ProtocolとOSLog実装を追加する`

対象：

- `Logging`
- `LogEvent`
- `OSLogLogger`
- `SpyLogger`

確認：

- `print()`なし
- 座標、メディアIDなし
- イベント順序Test

#### 0-5 `[Foundation] ClockとTimeZone Providerを実装する`

対象：

- `Clock`
- `SystemClock`
- `TimeZoneProviding`
- `SystemTimeZoneProvider`
- Fake実装
- Unit Test

#### 0-6 `[Foundation] LocalTimeContextProviderを実装する`

対象：

- `RecordedTimeContext`
- `LocalTimeContextProviding`
- `DefaultLocalTimeContextProvider`
- `localDateKey`
- TimeZone、DST Test

#### 0-7 `[Foundation] AppContainerの骨格を作成する`

対象：

- Composition Root
- Initializer Injection
- FeatureへContainer全体を渡さない構造
- 空のSingletonを作らない

この段階では未実装依存をProtocol Placeholderで埋めすぎない。

#### 0-8 `[Tooling] SwiftFormatを導入する`

対象：

- `.swiftformat`
- ローカル実行手順
- 既存コードの最小整形

#### 0-9 `[Tooling] SwiftLintを導入する`

対象：

- `.swiftlint.yml`
- Force Cast、Force Try、長大関数等の検出
- ルール大量無効化禁止

### Phase 0完了条件

- プロジェクトが起動する
- AppContainerがComposition Rootとして存在
- Error、Logging、Clock、TimeZoneが差し替え可能
- SwiftLint、SwiftFormat Checkが実行可能
- DomainへApple Framework依存なし

## 6. Phase 1：DomainとSwiftData V1

### 目的

Domain Data、永続Model、Migration、Mapper、PersistenceActor、Route Encoding、stableIDを作る。

### Issue一覧

#### 1-1 `[Domain] 共通位置・時刻Valueを追加する`

対象例：

- `RouteCoordinate`
- `LocationEventData`
- `MotionEventData`
- `VisitEventData`
- Unit Test

Core LocationやCore Motion型を使用しない。

#### 1-2 `[Domain] 日別集計Data型を追加する`

対象：

- `DayAggregateData`
- `DayProcessingStateData`
- `LocalMonth`
- `CalendarDayData`

#### 1-3 `[Domain] MovementSegment Data型を追加する`

対象：

- `MovementSegmentData`
- `AutomaticMovementType`
- `UserMovementClassification`
- `ClassificationConfidence`

#### 1-4 `[Domain] StaySegmentとOverride Data型を追加する`

対象：

- `StaySegmentData`
- `ClassificationOverrideData`
- `StayOverrideData`
- `StayOverrideAction`

#### 1-5 `[Domain] Media Data型を追加する`

対象：

- `MediaAssetReference`
- `MediaPlacement`
- `MediaType`
- `MediaEligibility`

UIKit、PhotoKit、AVFoundationをimportしない。

#### 1-6 `[Data] SwiftData V1 Schemaを追加する`

対象Model：

- LocationEventModel
- MotionEventModel
- VisitEventModel
- DayProcessingStateModel
- DayAggregateModel
- MovementSegmentModel
- StaySegmentModel
- ClassificationOverrideModel
- StayOverrideModel
- MediaAssetCacheModel

`data-model.md`に従う。

#### 1-7 `[Data] Schema VersionとMigration Planを追加する`

対象：

- V1 Schema
- Migration Plan
- ModelContainer生成
- 起動Integration Test

#### 1-8 `[Data] Data Mapperを実装する`

対象：

- Model → Domain Data
- Domain Data → Model
- Mapper Test

ビジネス判定を含めない。

#### 1-9 `[Data] PersistenceActorを実装する`

対象：

- SwiftDataアクセスの集約
- ModelContextの隔離
- In-memory Test Container

#### 1-10 `[Shared] RouteEncodingを実装する`

対象：

- binary PropertyList
- formatVersion
- encode/decode
- invalid payload Test

#### 1-11 `[Domain] StableIDGeneratorを実装する`

対象：

- Movement stableID
- Stay stableID
- SHA-256
- 丸め
- Determinism Test

### Phase 1完了条件

- V1 Schemaで起動できる
- 全Model保存・取得可能
- MapperがDomainへSwiftData Modelを漏らさない
- Route Dataが保存・復元可能
- stableIDが決定的
- In-memory Integration Test環境がある

## 7. Phase 2：生ログ記録

### 目的

Core Location、Core Motion、CLVisitから生イベントを受け、SwiftDataへ保存できる状態にする。

### Issue一覧

#### 2-1 `[Data] RawEventRepository Protocolを実装する`

対象：

- Protocol
- Save Result
- RawDayEvents
- In-memory Fake

#### 2-2 `[Data] LocationEvent保存Repositoryを実装する`

確認：

- Insert
- 近似重複無視
- rawRevision更新
- localDateKey取得
- Integration Test

#### 2-3 `[Data] MotionEvent保存Repositoryを実装する`

確認：

- 全Motion flag保存
- confidence保存
- rawRevision更新
- Integration Test

#### 2-4 `[Data] Visit保存・更新Repositoryを実装する`

確認：

- 到着だけ保存
- 同一Visit出発更新
- 座標近似判定
- rawRevision更新

#### 2-5 `[Platform] LocationProvidingを実装する`

対象：

- CoreLocationProvider
- SLC
- Delegate → AsyncStream
- State
- Error変換
- Fake Provider
- Conversion Test

高精度GPSを追加しない。

#### 2-6 `[Platform] MotionProvidingを実装する`

対象：

- CoreMotionProvider
- AsyncStream
- 全flag変換
- confidence
- 権限拒否
- Fake Provider

#### 2-7 `[Platform] VisitProvidingを実装する`

対象：

- CLVisit監視
- arrival/departure
- AsyncStream
- Fake Provider

#### 2-8 `[Platform] PermissionManagingを実装する`

対象：

- Location
- Motion
- Photos
- 状態更新
- 設定アプリ導線
- Fake

UIはまだ作らない。

#### 2-9 `[Application] 生イベント保存Coordinatorを実装する`

責務：

- Provider Stream購読
- RawEventRepository保存
- markDirty
- Logging
- 個別失敗の分離

#### 2-10 `[Application] StartMonitoringUseCaseを実装する`

確認：

- Location開始
- Motion拒否でもLocation継続
- Visit失敗でもLocation継続
- 重複開始防止

#### 2-11 `[Application] AppLifecycleCoordinator基礎を実装する`

対象：

- Launch
- Foreground
- Background
- 監視状態確認
- 通常BackgroundでSLCを停止しない

### 実機確認

- 位置権限「常に許可」
- 徒歩でLocationEvent保存
- MotionEvent保存
- Visit受信可能性
- Background移行
- 再起動後監視状態
- Motion拒否でも位置保存

### Phase 2完了条件

- 実機を持って歩くとRaw Eventが保存される
- MotionとVisitが独立して失敗可能
- 生イベント受信時に重い処理をしない
- rawRevisionが更新される
- UIなしでもTestまたはDebug表示で保存確認可能

## 8. Phase 3：Processing基礎

### 目的

生ログから決定的な派生結果を生成する純粋処理群を実装する。

### Issue一覧

#### 3-1 `[Processing] ProcessingConfigurationを追加する`

全閾値を1箇所へ集約する。

#### 3-2 `[Processing] LocationSanitizerの無効座標除外を実装する`

対象：

- 範囲外
- NaN
- 負精度
- 未来時刻
- Unit Test

#### 3-3 `[Processing] 重複位置点除外を実装する`

対象：

- 30秒
- 10m
- 精度優先
- Boundary Test

#### 3-4 `[Processing] 水平精度除外を実装する`

対象：

- 500m
- 500m超
- rejected reason

#### 3-5 `[Processing] 座標ジャンプ除外を実装する`

対象：

- 250km/h
- A-B-C判定
- 精度比較
- Test

#### 3-6 `[Processing] 現地日付境界分割を実装する`

保存済みlocalDateKeyを使用する。

#### 3-7 `[Processing] MovementSegmenterを実装する`

対象：

- 90分Gap
- 日付境界
- CLVisit
- Motion変化
- 最小100m
- 最小2点

#### 3-8 `[Processing] StayDetector基礎を実装する`

対象：

- 3分
- 5分
- 150m
- CLVisit
- automotive→walking

#### 3-9 `[Processing] 渋滞・信号除外を実装する`

対象：

- automotive→stationary→automotive
- walkingなし
- CLVisitなし

#### 3-10 `[Processing] MovementClassifierを実装する`

対象：

- automotiveLike
- walkingLike
- other
- Motion占有率
- 速度・距離Fallback
- confidence

#### 3-11 `[Processing] 区間距離・平均速度を実装する`

対象：

- 距離合計
- 2分
- 100m
- 2点
- day-wide averageなし

#### 3-12 `[Processing] RouteSimplifierを実装する`

対象：

- Douglas-Peucker
- 30m
- 10点未満は未処理
- 始点・終点保持

#### 3-13 `[Processing] RouteLabelPlacerを実装する`

対象：

- 50%
- fallback順
- ラベルFormat

#### 3-14 `[Processing] OverrideMatcherを実装する`

対象：

- stableID
- Movement近似条件
- Stay近似条件
- 複数候補拒否

#### 3-15 `[Processing] DaySummaryBuilderを実装する`

対象：

- 距離
- 時間
- 開始・終了
- 区間数
- 滞在
- 代表分類
- valid day判定

#### 3-16 `[Processing] DefaultDayProcessorを実装する`

処理順を統合する。

SwiftData保存は行わない。

### Phase 3完了条件

- 全ComponentがMainActor非依存
- SwiftData非依存
- OS Framework非依存
- 全境界値Test成功
- 同じ入力から同じ結果
- 空入力、1点、全除外でも成功

## 9. Phase 4：日別処理と派生保存

### 目的

Raw Eventから日別派生データを生成し、世代管理付きで保存する。

### Issue一覧

#### 4-1 `[Data] ProcessingStateRepositoryを実装する`

対象：

- rawRevision
- processedRevision
- pending
- processing
- completed
- failed
- Integration Test

#### 4-2 `[Data] DerivedDataRepositoryの取得を実装する`

対象：

- Aggregate
- Movement
- Stay
- 月別Aggregate

#### 4-3 `[Data] DerivedData一括置換を実装する`

対象：

- 既存削除
- 新規保存
- 途中失敗時旧データ維持
- Integration Test

#### 4-4 `[Data] OverrideRepositoryを実装する`

対象：

- Classification
- Stay
- Upsert
- 日付取得
- 再処理後維持

#### 4-5 `[Application] ProcessDayUseCaseを実装する`

流れ：

1. state確認
2. raw取得
3. Override取得
4. media count取得
5. processor実行
6. derived置換
7. revision更新

#### 4-6 `[Application] 日別二重処理防止を実装する`

対象：

- 同日同時実行1回
- 別日処理
- priority

#### 4-7 `[Application] DayProcessingCoordinatorを実装する`

対象：

- userVisible
- normal
- background
- pending日
- limit
- cancellation

#### 4-8 `[Application] Foreground fallbackを実装する`

起動・Foreground時に未処理日を処理する。

#### 4-9 `[Test] 日別処理統合Fixtureを追加する`

対象：

- 徒歩
- 車
- 滞在
- 日付境界
- rawRevision変更
- cancellation

### Phase 4完了条件

- Raw EventからDayAggregate生成
- Movement、Stay保存
- processedRevision更新
- Override維持
- 同日二重処理なし
- 中断時に途中状態を保存しない
- Foregroundで未処理日を処理できる

## 10. Phase 5：月間カレンダー

### 目的

最初のユーザー向け画面として、月別の移動日と距離を表示する。

### Issue一覧

#### 5-1 `[Application] LoadCalendarMonthUseCaseを実装する`

対象：

- 月別Aggregate取得
- 有効日だけ距離
- 空月
- エラー

#### 5-2 `[UI] CalendarViewModelを実装する`

対象：

- 月状態
- loading
- loaded
- empty
- error
- swipe
- 日選択

#### 5-3 `[UI] 月間Calendar Layoutを実装する`

対象：

- locale
- first weekday
- 日付セル
- 今日の青丸
- 赤選択
- iPhoneサイズ対応

#### 5-4 `[UI] 日別距離表示を追加する`

対象：

- 日付＋距離
- 無効日は距離なし
- 写真枚数等は表示しない

#### 5-5 `[UI] 左右スワイプ月移動を実装する`

矢印ボタンは追加しない。

#### 5-6 `[UI] Calendar Empty・Error状態を実装する`

対象：

- ProgressView
- 空月
- 再試行

#### 5-7 `[UI Test] Calendar主要導線を追加する`

### Phase 5完了条件

- 月間Calendarが表示
- 有効移動日に距離
- 今日が青丸
- 左右スワイプ
- 無効日は遷移不可
- 有効日から日別詳細用Routeへ遷移可能

## 11. Phase 6：日別詳細

### 目的

当日の地図プレビュー、基本サマリー、詳細統計を表示する。

メディアは後Phaseで追加する。

### Issue一覧

#### 6-1 `[Application] LoadDayDetailUseCase基礎を実装する`

対象：

- Aggregate
- Movement
- Stay
- isReprocessing
- mediaは空でもよい

#### 6-2 `[Map] MapSceneBuilder基礎を実装する`

対象：

- ポリライン
- Stay Annotation
- 初期領域
- Mediaなし

#### 6-3 `[UI] DayDetailViewModelを実装する`

対象：

- load state
- reprocessing
- error
- delete未実装

#### 6-4 `[UI] Day Detail Map Previewを実装する`

対象：

- 上部約60%
- タップ可能
- PreviewではCalloutなし

#### 6-5 `[UI] 基本サマリーを実装する`

順序：

1. 距離
2. 移動時間
3. 開始
4. 終了
5. メディア枚数
6. 仮分類

メディア枚数は0でも表示可能。

#### 6-6 `[UI] 詳細統計を実装する`

対象：

- 区間数
- 滞在数
- 滞在時間
- 記録点数
- 除外点数
- 分類別時間

#### 6-7 `[UI] 再集計・空・エラー状態を実装する`

#### 6-8 `[UI Test] 日別詳細基礎導線を追加する`

### Phase 6完了条件

- CalendarからDay Detailへ遷移
- 地図Preview
- Summary
- 詳細統計
- 再集計中も既存データ表示
- iPhone SE〜Pro Maxで破綻なし

## 12. Phase 7：全画面地図

### 目的

当日の経路、区間、滞在を詳細に操作できる地図を実装する。

### Issue一覧

#### 7-1 `[Map] MKMapView Wrapperを実装する`

対象：

- SwiftUI Bridge
- MapScene描画
- lifecycle
- update差分

#### 7-2 `[Map] 移動ポリライン描画を実装する`

対象：

- 区間別
- タップ領域
- 選択状態

#### 7-3 `[Map] 区間ラベルを実装する`

対象：

- `32分・18.4km`
- タップ選択

#### 7-4 `[Map] 滞在Annotationを実装する`

対象：

- 滞在時間
- 選択

#### 7-5 `[Map] 現在地ボタンを実装する`

#### 7-6 `[Map] MapKit標準コンパスを設定する`

#### 7-7 `[Map] 区間Calloutを実装する`

表示：

- 開始
- 終了
- 時間
- 距離
- 平均速度
- 仮分類
- ユーザー分類

分類変更操作は後Phaseで接続してよい。

#### 7-8 `[Map] 滞在Calloutを実装する`

表示：

- 到着
- 出発
- 滞在時間
- 判定状態

修正操作は後Phaseで接続してよい。

#### 7-9 `[UI] RouteMapViewModelを実装する`

対象：

- 選択対象
- Callout
- MapScene
- 空白タップ

#### 7-10 `[UI Test] Map Callout導線を追加する`

### Phase 7完了条件

- PreviewからFull Mapへ遷移
- ポリライン、ラベル、Stay表示
- 区間Callout
- Stay Callout
- 1度に1つのCallout
- 現在地ボタン
- コンパス
- Map上の操作がMain Threadを長時間占有しない

## 13. Phase 8：写真・動画

### 目的

PhotoKitから対象日の写真・動画を取得し、グリッド、地図、プレビュー、共有へ接続する。

### Issue一覧

#### 8-1 `[Platform] PhotoLibraryProvidingを実装する`

対象：

- authorization
- fetch assets
- thumbnail
- photo preview
- video asset
- shareable resource
- library change
- Fake

#### 8-2 `[Media] MediaEligibilityEvaluatorを実装する`

対象：

- Screenshot除外
- Screen Recording除外
- その他原則eligible
- Test

#### 8-3 `[Data] MediaCacheRepositoryを実装する`

対象：

- localIdentifier
- 日付別
- upsert
- replace
- remove deleted
- Integration Test

#### 8-4 `[Application] RefreshMediaCacheUseCaseを実装する`

対象：

- DateInterval
- Eligibility
- Cache置換
- media count
- 削除済み除去

#### 8-5 `[Application] Thumbnail UseCaseを実装する`

対象：

- UIImage
- MainActor境界
- メモリキャッシュ
- 永続保存なし

#### 8-6 `[UI] 日別詳細へ4列Media Gridを追加する`

対象：

- 正方形
- creationDate順
- 動画表示
- 空状態
- Dynamic Type時3列許容

#### 8-7 `[UI] Photo Previewを実装する`

#### 8-8 `[UI] Video Previewを実装する`

対象：

- AVPlayer
- 標準Control
- 遷移時停止

#### 8-9 `[Application] ShareMediaUseCaseを実装する`

対象：

- 1件
- 一時ファイル
- 標準Share Sheet
- cleanup

#### 8-10 `[Map] Media Annotationを実装する`

位置情報付きだけ表示。

#### 8-11 `[Processing] MediaPlacementCalculatorを実装する`

対象：

- 500m
- 最短区間
- 時刻優先
- 位置なし除外

#### 8-12 `[Map] Media Clusteringを実装する`

ズームアウト時のみ。

#### 8-13 `[Platform] Photo Library Change反映を実装する`

対象：

- 削除
- 限定アクセス変更
- Cache refresh

#### 8-14 `[UI Test] Media主要導線を追加する`

### 実機確認

- 通常写真
- 動画
- 位置あり
- 位置なし
- Screenshot除外
- Screen Recording除外
- Limited Photos
- iCloud上のみ
- Share Sheet
- 削除済み資産

### Phase 8完了条件

- 4列Grid
- Photo Preview
- Video Playback
- 1件共有
- 位置付きだけMap表示
- Clustering
- 削除・限定アクセス変更でクラッシュしない
- 写真本体をSwiftDataへ保存しない

## 14. Phase 9：ユーザー修正

### 目的

移動分類と滞在表示をユーザーが修正し、再処理後も可能な限り維持する。

### Issue一覧

#### 9-1 `[Application] UpdateClassificationUseCaseを実装する`

対象：

- car
- train
- bus
- walk
- other
- upsert
- 自動値保持

#### 9-2 `[Application] UpdateStayOverrideUseCaseを実装する`

対象：

- confirm
- hide
- automatic

#### 9-3 `[Map] 区間Calloutへ分類Menuを追加する`

#### 9-4 `[Map] 滞在Calloutへ修正操作を追加する`

#### 9-5 `[Application] Override適用済みDisplay Dataを実装する`

#### 9-6 `[Processing] 再処理後Override再紐づけを接続する`

対象：

- stableID
- 近似
- 複数候補拒否

#### 9-7 `[UI] 成功時Hapticを追加する`

対象：

- 分類
- Stay修正

#### 9-8 `[Test] Override統合Testを追加する`

### Phase 9完了条件

- Calloutから分類変更
- Stay confirm/hide/automatic
- 自動判定値は保持
- 再処理後もOverride維持
- 誤候補複数時は自動適用しない
- 成功時だけ軽いHaptic

## 15. Phase 10：日付完全削除

### 目的

指定日のRaw、Derived、Override、State、Media Cacheを完全削除する。

Photos資産は削除しない。

### Issue一覧

#### 10-1 `[Data] DayDeletionRepositoryを実装する`

削除対象：

- Location
- Motion
- Visit
- Aggregate
- Movement
- Stay
- Classification Override
- Stay Override
- Processing State
- Media Cache

#### 10-2 `[Test] 日付完全削除Integration Testを追加する`

確認：

- 指定日だけ削除
- 他日維持
- orphan cleanup
- partial deletionなし
- Photos API未使用

#### 10-3 `[Application] DeleteDayLogUseCaseを実装する`

#### 10-4 `[UI] 日別詳細右上Delete Menuを追加する`

#### 10-5 `[UI] 削除確認Dialogを追加する`

説明：

- 記録削除
- Photosは残る
- 取り消し不可

#### 10-6 `[UI] 削除成功・失敗遷移を実装する`

成功：

- Haptic
- Calendarへ戻る
- 距離消失

失敗：

- Alert
- Detail維持

### 実機確認

- Override作成後削除
- Photos資産維持
- 再起動後も削除済み
- 他日維持

### Phase 10完了条件

- 指定日の全関連データ削除
- 写真・動画維持
- 他日影響なし
- 部分削除状態なし
- UIから安全に実行可能

## 16. Phase 11：バックグラウンド処理

### 目的

BGProcessingTaskを追加し、未処理日を充電中に処理できるようにする。

Foreground fallbackを常に維持する。

### Issue一覧

#### 11-1 `[Platform] BackgroundTaskSchedulingを実装する`

対象：

- register
- schedule
- cancel
- Fake

#### 11-2 `[Application] BGTask実行Handlerを実装する`

対象：

- pending日
- limit
- cancellation
- expiration

#### 11-3 `[Application] Background移行時予約を接続する`

#### 11-4 `[Application] 充電中優先条件を設定する`

#### 11-5 `[Application] Expiration時の安全な中断を実装する`

#### 11-6 `[Test] BGTask Coordinator Unit Testを追加する`

#### 11-7 `[Device] BGTask実機確認手順を実施する`

### Phase 11完了条件

- BGTask登録
- 予約
- expirationキャンセル
- 途中データ未保存
- pending日再処理
- BGTask未実行でもForegroundで処理
- OSが実行時刻を保証しない前提を維持

## 17. Phase 12：オンボーディングと権限UI

### 目的

初回起動時に必要な説明と権限取得導線を表示する。

### Issue一覧

#### 12-1 `[UI] Onboarding画面を実装する`

内容：

- アプリ説明
- 位置
- Motion
- Photos
- 端末内処理
- 外部送信なし

#### 12-2 `[UI] 位置権限要求フローを接続する`

段階的要求。

#### 12-3 `[UI] Motion権限要求フローを接続する`

#### 12-4 `[UI] Photos権限要求フローを接続する`

#### 12-5 `[UI] 権限拒否表示を実装する`

対象：

- 説明
- 設定を開く
- 残り機能へ進む

#### 12-6 `[UI] Limited Photos状態を実装する`

#### 12-7 `[UI Test] Onboarding主要導線を追加する`

### Phase 12完了条件

- 初回説明
- 権限要求
- 拒否時設定導線
- 一部権限拒否でも利用可能
- Privacy説明
- Dynamic Type、VoiceOver対応

## 18. Phase 13：品質仕上げ

### 目的

MVPリリース前の表示、性能、Privacy、長期利用、実機挙動を確認する。

### Issue一覧

#### 13-1 `[Quality] iPhone SEレイアウトを修正する`

#### 13-2 `[Quality] iPhone 15基準レイアウトを確認する`

#### 13-3 `[Quality] Pro Maxレイアウトを確認する`

#### 13-4 `[Quality] Light / Dark Modeを確認する`

#### 13-5 `[Accessibility] Dynamic Typeを確認する`

#### 13-6 `[Accessibility] VoiceOver Labelを確認する`

#### 13-7 `[Performance] 日別処理負荷を確認する`

対象：

- 1,000 Location
- 100 Movement
- 100 Stay
- 1,000 Media Cache

#### 13-8 `[Performance] MapとGridのメモリ負荷を確認する`

#### 13-9 `[Privacy] Loggerと保存内容を監査する`

#### 13-10 `[Privacy] 外部通信がないことを確認する`

#### 13-11 `[Device] 普通の外出1日Testを実施する`

#### 13-12 `[Device] 車移動1日Testを実施する`

#### 13-13 `[Device] Media多用1日Testを実施する`

#### 13-14 `[Device] 日付境界Testを実施する`

#### 13-15 `[Device] TimeZone変更Testを実施する`

#### 13-16 `[Release] Release Buildを確認する`

#### 13-17 `[Release] MVP Check Listを完了する`

### Phase 13完了条件

- SE〜Pro Max
- Light / Dark
- Dynamic Type
- VoiceOver
- 実機SLC
- Motion
- Photos
- BGTask fallback
- 日付削除
- Privacy
- 長期Test
- Release Build
- Crashなし

## 19. 推奨Issue総数

初期計画では約60〜75 Issueを想定する。

内訳の目安：

| Phase | Issue数 |
|---|---:|
| Phase 0 | 9 |
| Phase 1 | 11 |
| Phase 2 | 11 |
| Phase 3 | 16 |
| Phase 4 | 9 |
| Phase 5 | 7 |
| Phase 6 | 8 |
| Phase 7 | 10 |
| Phase 8 | 14 |
| Phase 9 | 8 |
| Phase 10 | 6 |
| Phase 11 | 7 |
| Phase 12 | 7 |
| Phase 13 | 17 |

実装中に統合可能な小Issueはまとめてよいが、変更範囲が不明瞭になる統合はしない。

## 20. 最初に作るIssue

最初の実装Issueは次とする。

```text
[Foundation] プロジェクト設定を確認する
```

ただし、Xcode Projectを人間が作成済みであることが前提。

次に進む順序：

```text
0-1 Project Settings
→ 0-2 Folder Structure
→ 0-3 DriveLogError
→ 0-4 Logging
→ 0-5 Clock / TimeZone
→ 0-6 LocalTimeContext
→ 0-7 AppContainer
→ 0-8 SwiftFormat
→ 0-9 SwiftLint
```

## 21. 実装開始前チェック

Codexへ最初のIssueを渡す前に確認する。

- Xcode Projectが作成済み
- iOS 17+
- iPhone Target
- SwiftUI App
- SwiftData利用可能
- Git Repository初期化済み
- docsディレクトリへ全設計文書配置済み
- Buildが通る
- Scheme名が確定
- Simulator名が確認済み
- CodexがRepository全体を読める
- 外部ライブラリが入っていない

## 22. Phase間依存関係

```text
Phase 0
  ↓
Phase 1
  ↓
Phase 2 ───────────────┐
  ↓                    │
Phase 3                │
  ↓                    │
Phase 4                │
  ↓                    │
Phase 5                │
  ↓                    │
Phase 6                │
  ↓                    │
Phase 7                │
  ↓                    │
Phase 8                │
  ↓                    │
Phase 9                │
  ↓                    │
Phase 10               │
  ↓                    │
Phase 11 ← Foreground fallback
  ↓
Phase 12
  ↓
Phase 13
```

Phase 12のOnboardingは早期に仮画面を作ってもよいが、完成は監視・権限処理が確定した後に行う。

## 23. 並行実装

原則として直列で進める。

並行可能な例：

- Phase 3の独立Processing Component
- Phase 5のCalendar LayoutとUseCase Test
- Phase 8のPhoto Provider FakeとMedia Eligibility
- Phase 13のAccessibilityとPrivacy監査

並行禁止に近いもの：

- Schema変更とRepository実装
- Protocol変更と複数Feature実装
- MapScene仕様未確定の状態でMap UI
- Overrideルール未完成の状態でCallout保存
- Foreground fallback未完成の状態でBGTaskだけ実装

## 24. 仕様変更時の手順

実装中に仕様変更が必要になった場合：

1. 関連設計文書を更新
2. 影響するInterfaceを確認
3. Data Model影響を確認
4. Processing Rule影響を確認
5. Test Planを更新
6. Implementation PlanのIssue順を更新
7. 既存IssueのAcceptance Criteriaを更新
8. Codexへ変更後Issueを渡す

コードだけ先に変更しない。

## 25. Blocker条件

次の場合は後続Issueへ進まない。

- Build失敗
- Test失敗
- 新規Warning
- SchemaとData Model文書の不一致
- Protocolと具体実装の不一致
- DomainへApple Framework依存
- SwiftData ModelがFeatureへ漏れている
- Raw Eventが失われる
- Overrideが再処理で消える
- 日付境界が現在TimeZone依存
- Photos資産を削除する可能性
- BGTaskがないと処理できない構造
- 高精度GPSを継続使用
- 個人情報をLoggerへ出力
- 未完成TODOで完了扱い

## 26. MVP完了判定

MVP完了には次をすべて満たす。

### Recording

- SLC記録
- Motion記録
- Visit記録
- Background復帰
- Raw Event保持

### Processing

- Sanitizing
- Segmentation
- Stay Detection
- Classification
- Route Simplification
- Day Summary
- Revision管理
- Foreground fallback

### UI

- Calendar
- Day Detail
- Full Map
- Callout
- Media Grid
- Photo Preview
- Video Preview
- Share
- Delete
- Onboarding
- Permission Error

### User Correction

- Movement Classification Override
- Stay Confirm
- Stay Hide
- Automatic Restore
- Reprocessing Rematch

### Privacy

- On-device only
- No login
- No server
- No image AI
- No media copy persistence
- No sensitive logs
- Complete date deletion

### Quality

- Build成功
- Test成功
- Warningなし
- SE〜Pro Max
- Light / Dark
- Dynamic Type
- VoiceOver
- 実機長期Test
- Release Build

## 27. MVP後へ延期する項目

次はMVPへ追加しない。

- iCloud Sync
- Server Sync
- Login
- Social機能
- 位置共有
- 高精度GPS自動切替
- 道路Map Matching
- 住所逆引き
- 滞在地点名
- Memo
- 複数Media共有
- 自転車専用分類
- Settings画面
- 地図航空写真切替
- iPad対応
- 横画面
- Watch App
- Widget
- AI画像解析
- AI移動分類
- 日全体平均速度
- 最高速度
- Trash / Restore
- 自動Raw Log削除

## 28. 完了後の次作業

この文書完成後の次の設計文書は`project-rules.md`とする。

`project-rules.md`では、CodexがRepository全体で常に守る最上位ルール、文書優先順位、変更前後の手順、禁止事項、完了報告を短くまとめる。

その後、Phase 0の各Issueを`issue-template.md`から実際に作成する。

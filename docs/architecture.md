# Architecture

## 実機フィードバックによるLocation補足（2026-07-15）

Power stateはPlatform Protocolへ隔離し、ApplicationのMonitoring coordinatorが`lowPower`と`chargingHighAccuracy`を選ぶ。Battery通知に加えて現在状態を定期照合し、通知欠落や一時的な切替失敗から自己修復する。単一`CLLocationManager`内でSLCとstandard updateを排他的に停止/開始し、Providerを重複起動しない。高精度Modeは充電中だけで、Best accuracy、50m distance filter、automotive navigation、約60秒のemit filterを使用する。

Mediaの表示可否は`MapScene`を正とし、Map描画時に別のMedia snapshotとの再照合でAnnotationを破棄しない。Thumbnail取得に失敗してもfallback Annotationを維持する。

## 1. 対象環境

- アプリ仮称：`DriveLog`
- iPhone専用
- iOS 17以降
- SwiftUI
- SwiftData
- オンデバイス完結
- 外部サーバーなし
- サードパーティ製フレームワークは原則使用しない
- 縦向き表示のみ
- iPhone SE相当からPro Maxまで対応
- Dynamic Type対応
- Xcodeプロジェクト自体は人間側で作成する

## 2. アーキテクチャ方針

アプリ全体は、1つのアプリ内で機能を分離するモジュラーモノリスとする。

画面はMVVMを基本とし、処理を次の層へ分ける。

```text
Presentation
SwiftUI View / ViewModel
        ↓
Application
UseCase / Processing Pipeline
        ↓
Domain
Entity / Policy / Classification Rule
        ↓
Data / Platform
SwiftData / Core Location / Core Motion / PhotoKit / MapKit
```

基本原則は次のとおり。

- ViewからCore Location、Core Motion、PhotoKit、SwiftDataを直接操作しない
- OS固有機能はServiceまたはRepositoryの背後に隠す
- 取得した生ログは、ユーザーによる日付削除を除き変更しない
- 集計結果は生ログから再生成可能にする
- ユーザー修正は自動分類結果と分離して保存する
- バックグラウンド処理が実行されなくてもアプリを利用可能にする
- 日付は記録時の現地時間で固定する
- 高精度GPSの連続追跡は実装しない
- 判定閾値はPolicyまたはProcessing Rulesへ分離する

## 3. システム構成

```text
Core Location SLC ─┐
CLVisit ───────────┼→ Raw Event Recorder → Raw Event Store
Core Motion ───────┘                          ↓
                                           Dirty Day
                                               ↓
                                   Day Processing Pipeline
                                               ↓
                                Derived Data / Day Summary
                                               ↓
                         Calendar / Day Detail / Route Map

PhotoKit ─→ Photo Repository ─→ Media Eligibility ─→ Media Placement
                                      ↓                    ↓
                                  Media Grid           Route Map
                                      ↓
                               Media Preview / Share
```

Significant Location Changeは、大きな位置変化のみを通知する低消費電力の位置情報サービスとして扱う。密なGPS軌跡ではなく、取得できた観測点を時刻順に結んだ推定経路として表示する。

## 4. モジュール構成

### Application

アプリ起動、依存関係生成、ライフサイクル、バックグラウンドタスク登録を担当する。

```text
Application/
├── DriveLogApp.swift
├── AppContainer.swift
└── AppLifecycleCoordinator.swift
```

### Features

画面単位の機能を配置する。

```text
Features/
├── Onboarding/
├── Calendar/
├── DayDetail/
├── RouteMap/
└── MediaPreview/
```

### Domain

OSや保存方式に依存しないモデル、Protocol、判定規則を配置する。

```text
Domain/
├── Entities/
├── ValueObjects/
├── Repositories/
├── UseCases/
└── Policies/
```

主なDomain要素は次のとおり。

- DayLog
- MovementSegment
- StaySegment
- MovementClassification
- UserClassification
- RouteCoordinate
- DaySummary
- MediaAssetReference
- MediaPlacement
- LocalDayKey
- RecordedTimeZone

### Data

SwiftDataへの保存と取得を担当する。

```text
Data/
├── Models/
├── Repositories/
├── PersistenceActor/
└── Mappers/
```

### Platform

Appleフレームワークとの接続を担当する。

```text
Platform/
├── Location/
├── Motion/
├── Visits/
├── Photos/
├── BackgroundTasks/
├── Maps/
└── Sharing/
```

### Processing

生ログから日別データを生成する。

```text
Processing/
├── DayProcessingPipeline.swift
├── LocationSanitizer.swift
├── MovementSegmenter.swift
├── StayDetector.swift
├── MovementClassifier.swift
├── RouteSimplifier.swift
├── RouteLabelPlacementService.swift
└── DaySummaryBuilder.swift
```

## 5. 日付・タイムゾーン設計

日付グループは記録時の現地時間で固定する。

各生イベントには次を保存する。

- UTC基準のイベント時刻
- 記録時のタイムゾーン識別子
- 記録時のUTCオフセット秒
- 記録時の現地日付キー

日付キーは、イベント取得時に生成し、現在の端末タイムゾーン変更後も再計算しない。

日付をまたぐ移動区間や滞在区間は、現地日付キーの境界で分割する。

## 6. データ保存構造

### 生データ

取得した事実を保存する。ユーザーによる日付削除以外では変更しない。

#### LocationEvent

- ID
- 緯度
- 経度
- 取得時刻
- 水平精度
- 速度
- 作成日時
- タイムゾーン識別子
- UTCオフセット秒
- 現地日付キー

#### MotionEvent

- ID
- 開始時刻
- 終了時刻
- automotive
- walking
- running
- cycling
- stationary
- unknown
- confidence
- タイムゾーン識別子
- UTCオフセット秒
- 現地日付キー

#### VisitEvent

- ID
- 緯度
- 経度
- 到着推定時刻
- 出発推定時刻
- 水平精度
- タイムゾーン識別子
- UTCオフセット秒
- 現地日付キー

### 派生データ

生データから再生成できるデータを保存する。

#### DayAggregate

- 現地日付キー
- 総移動距離
- 総移動時間
- 開始時刻
- 終了時刻
- 記録点数
- 除外点数
- メディア枚数
- 代表仮分類
- 移動あり／なし
- 移動区間数
- 滞在地点数
- 総滞在時間
- 車っぽい移動時間
- 徒歩っぽい移動時間

日全体の平均速度と最高速度は保存しない。

#### MovementSegment

- ID
- 現地日付キー
- 開始時刻
- 終了時刻
- 距離
- 移動時間
- 推定平均速度
- 仮分類
- 表示用経路データ
- ポリラインラベル位置

#### StaySegment

- ID
- 現地日付キー
- 代表座標
- 到着推定時刻
- 出発推定時刻
- 推定滞在時間
- 自動判定結果
- 表示対象かどうか

### ユーザー修正

自動判定を上書きするデータとして分離する。

#### ClassificationOverride

- 対象移動区間ID
- ユーザー指定分類
- 更新日時

#### StayOverride

- 対象滞在ID
- 立ち寄り確定
- 非表示
- 自動判定へ戻す状態
- 更新日時

ユーザー修正によって生ログを変更しない。集計を再実行しても修正結果が失われない構造にする。

## 7. 処理状態管理

単純な`processed`フラグだけでは不十分とする。

一度処理済みにした日へ新しい位置ログが追加された場合、再処理が必要になるため、次の世代情報を保存する。

```text
DayProcessingState

dateKey
rawRevision
processedRevision
status
lastAttemptDate
lastSuccessfulDate
```

状態は次のように判定する。

```text
rawRevision == processedRevision
→ 処理済み

rawRevision > processedRevision
→ 未処理または再処理が必要
```

処理中に中断された場合も、派生データを途中状態で確定させない。日付単位で全処理が成功した後に、派生データと`processedRevision`をまとめて更新する。

`processing`はプロセスをまたぐLockとして扱わない。アプリ終了やOSによる中断で`processing`のまま残っても、`rawRevision > processedRevision`なら次回のForeground fallbackまたはBackground処理で再試行対象とする。同一プロセス内の重複実行は`DayProcessingGate`でまとめる。

Processing Algorithmの互換性Versionは端末内Preferenceへ整数だけを保存する。Version更新時は完了済み日の`processedRevision`を1世代戻して`pending`へし、既存Raw Eventと派生データを残したまま日別再処理へ渡す。Invalidationの保存に成功するまでVersionを進めず、再処理結果は従来どおり日付単位で原子的に置換する。

## 8. 位置情報記録フロー

```text
SLCによる位置変化を受信
↓
イベント時点の現地タイムゾーン情報を取得
↓
値の最低限の妥当性確認
↓
LocationEventとして保存
↓
対象日のrawRevisionを増加
↓
バックグラウンド処理を予約
↓
終了
```

位置情報受信時には、距離計算、区間分割、写真検索、地図生成を行わない。

Core MotionとCLVisitも独立したイベントとして保存し、位置ログ受信時に無理に結合しない。

## 9. 日別処理パイプライン

処理は現地日付キー単位で、次の順番で実行する。

1. 生ログ取得
2. 時刻順に並べ替え
3. 不正値・低精度点の除外
4. 不自然な座標ジャンプの除外
5. 日付境界での分割
6. 移動区間の分割
7. 滞在候補の抽出
8. Core Motion・CLVisitとの統合
9. 移動状態の仮分類
10. 距離・時間・区間平均速度の集計
11. 表示用経路の間引き
12. ポリラインラベル位置の計算
13. 派生データ保存

各処理は入力と出力を明確にした独立コンポーネントとし、後から判定方法だけを交換可能にする。

## 10. バックグラウンド処理

日別処理は次の優先順位で実行する。

1. 充電中のバックグラウンド処理
2. アプリ起動後の未処理日処理
3. 日別詳細を開いた際の対象日処理

`BGProcessingTaskRequest`では外部電源接続を実行条件に指定する。ただし、処理時刻はiOSが決定するため、バックグラウンド処理だけには依存しない。

処理は次の条件を満たすようにする。

- 日付単位で再実行可能
- 同じ処理を複数回実行しても結果が重複しない
- キャンセル時に未完成データを確定しない
- 古い未処理日から順番に処理する
- UI表示が必要な日を優先できる

## 11. SwiftDataと並行処理

SwiftDataへの読み書きは`PersistenceActor`へ集約する。

`ModelActor`を利用してModelContextへのアクセスを直列化し、位置情報コールバック、バックグラウンド処理、画面表示が同時にDBを操作しないようにする。

```text
Location Service ─┐
Motion Service ───┼→ PersistenceActor → SwiftData
Visit Service ────┤
Day Processor ────┤
UI UseCase ───────┘
```

重い集計はMainActor上で実行しない。

## 12. 地図構成

地図へ直接Domainモデルを渡さず、表示専用の`MapScene`へ変換する。

```text
MapScene

polylines
movementLabels
stayAnnotations
mediaAnnotations
initialRegion
```

地図表示は`RouteMapView`という共通コンポーネントにまとめる。

- 日別詳細画面：操作を制限したプレビューモード
- 拡大地図画面：全操作が可能なフルモード

写真・動画クラスタリング、独自コールアウト、ポリラインやラベルのタップ判定が必要なため、内部実装は`MKMapView`をSwiftUIへラップする方式を採用する。

地図へ配置するメディアは位置情報を持つものだけとする。

## 13. 写真・動画構成

写真・動画本体やサムネイルをSwiftDataへ永続保存しない。

```text
PhotoKit
↓
PhotoLibraryRepository
↓
MediaEligibilityPolicy
├── Day Media Grid
└── MediaPlacementService
      ↓
   MapScene
```

### PhotoLibraryRepository

- 指定日の写真・動画を取得する
- PhotoKitの参照を返す
- 権限状態を管理する
- サムネイルとプレビュー用データを提供する

### MediaEligibilityPolicy

表示対象メディアを判定する。

- スクリーンショットを除外
- 画面収録を除外
- その他のメディアは、メタデータだけで確実に除外できない限り残す
- AIや画像解析は使用しない

### MediaPlacementService

位置情報を持つ写真・動画だけを地図へ配置する。

```text
位置情報あり
→ メディア座標を使用

位置情報なし
→ 地図へ配置しない
→ 日別グリッドには表示可能
```

### MediaPreview / ShareService

写真は画像プレビュー、動画は動画再生に対応する。

共有時だけ必要な写真・動画データを一時取得し、iOS標準共有シートへ渡す。

共有終了後またはキャンセル後に一時ファイルを削除する。

## 14. データ削除構成

日付削除は`DeleteDayLogUseCase`を通して行う。

```text
DayDetailFeature
↓
DeleteDayLogUseCase
↓
PersistenceActor
↓
指定日の関連データを完全削除
```

削除対象は指定日の生ログ、派生データ、ユーザー修正、処理状態とする。

日付をまたぐ区間は事前に日付境界で分割されている前提とし、指定日側だけを削除する。

Apple Photosライブラリ内の写真・動画は削除しない。

## 15. 権限管理

権限処理は`PermissionCoordinator`へ集約する。

管理対象は次のとおり。

- 位置情報
- モーション
- 写真

各FeatureはOSの権限APIを直接呼ばず、抽象化された権限状態だけを受け取る。

権限不足でも利用できる画面は表示し、利用不能な機能だけを無効化する。

## 16. 依存関係管理

外部DIライブラリは使用しない。

`AppContainer`でService、Repository、UseCaseを生成し、Initializer Injectionで渡す。

```text
AppContainer
├── PersistenceActor
├── PermissionCoordinator
├── LocationMonitoringService
├── MotionActivityService
├── VisitMonitoringService
├── PhotoLibraryRepository
├── DayProcessingPipeline
├── DayProcessingCoordinator
├── BackgroundTaskCoordinator
├── DeleteDayLogUseCase
└── ShareService
```

Domain層はCore Location、Core Motion、PhotoKit、SwiftDataを直接importしない。

## 17. フォルダ構成

```text
DriveLog/
├── Application/
│   ├── DriveLogApp.swift
│   ├── AppContainer.swift
│   └── AppLifecycleCoordinator.swift
│
├── Features/
│   ├── Onboarding/
│   ├── Calendar/
│   ├── DayDetail/
│   ├── RouteMap/
│   └── MediaPreview/
│
├── Domain/
│   ├── Entities/
│   ├── ValueObjects/
│   ├── Repositories/
│   ├── UseCases/
│   └── Policies/
│
├── Data/
│   ├── Models/
│   ├── Repositories/
│   ├── PersistenceActor/
│   └── Mappers/
│
├── Platform/
│   ├── Location/
│   ├── Motion/
│   ├── Visits/
│   ├── Photos/
│   ├── BackgroundTasks/
│   ├── Maps/
│   └── Sharing/
│
├── Processing/
│   ├── DayProcessingPipeline.swift
│   ├── LocationSanitizer.swift
│   ├── MovementSegmenter.swift
│   ├── StayDetector.swift
│   ├── MovementClassifier.swift
│   ├── RouteSimplifier.swift
│   ├── RouteLabelPlacementService.swift
│   └── DaySummaryBuilder.swift
│
└── Shared/
    ├── Extensions/
    ├── Logging/
    ├── Formatting/
    └── Utilities/
```

## 18. UIレイアウト方針

- 固定端末サイズを前提にしない
- iPhone SE相当からPro Maxまで破綻しない
- 縦向きのみ対応する
- Dynamic Typeに対応する
- 4列メディアグリッドを基本とし、小型画面や文字サイズ拡大時はレイアウト調整を許可する
- カレンダーは端末のCalendar、Locale、先頭曜日設定に従う
- Apple純正アプリに近い標準UIを基本とする

## 19. テスト方針

位置情報や日時へ直接依存しないよう、次をProtocol化する。

- LocationProviding
- MotionProviding
- VisitProviding
- PhotoLibraryProviding
- Clock
- TimeZoneProviding
- DayLogRepository
- BackgroundTaskScheduling

テストでは、保存済み座標列とモーション情報を入力し、次の結果を検証する。

- 現地日付キー
- 日付境界での区間分割
- 除外される位置点
- 総移動距離
- 1km未満の日の除外
- 移動区間
- 区間ごとの推定平均速度
- 滞在地点
- 仮分類
- 日別サマリー
- ポリラインラベル位置
- 日付削除後の関連データ消去
- 写真・動画選別
- 位置情報付きメディアだけの地図配置

実機でしか十分に確認できないバックグラウンド位置取得、PhotoKit、動画再生、BGTaskはDomain処理から分離する。

実機検証の基準端末はiPhone 15とする。

## 20. 主要な設計判断

### SLCだけを使用する

高精度GPSへの切り替えは実装負荷に対してMVPで得られる効果が小さいため、採用しない。

### 生ログと派生データを分離する

分類や閾値を変更しても、過去の生ログから再集計できるようにする。

### 記録時の現地日付を固定する

旅行後にタイムゾーンが変わっても、記録時の日付表示が変わらないようにする。

### ユーザー修正を別保存する

自動分類を再実行しても、ユーザーが指定した「車」「電車」などの結果を失わない。

### バックグラウンド処理に依存しすぎない

充電中処理を優先するが、アプリ起動時と詳細表示時にも補完する。

### 地図実装を1つにまとめる

プレビュー地図と拡大地図で別の描画ロジックを持たず、同じ`RouteMapView`をモード違いで使用する。

### 位置情報のないメディアは地図へ仮配置しない

誤配置を避け、位置情報付きメディアだけを地図へ表示する。位置情報がないメディアは日別グリッドに残す。

### 動画を写真と同じ参照モデルで扱う

PhotoKitの参照を共通化し、動画はサムネイル、再生、共有だけを追加する。

### 日全体の平均速度と最高速度を持たない

SLCの粗い位置点では誤解を招きやすいため、推定平均速度は移動区間ごとにだけ表示する。

### 判定ロジックを独立させる

滞在時間、半径、速度、位置精度などの閾値を画面やDB処理へ埋め込まず、Policyとして交換可能にする。

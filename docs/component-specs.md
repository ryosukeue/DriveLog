# Component Specifications

## 0. 共通方針

すべてのコンポーネントは次の原則に従う。

- ViewからCore Location、Core Motion、PhotoKit、SwiftDataを直接操作しない
- 取得した生ログは、ユーザーによる日付削除を除き変更しない
- 集計結果は生ログから再生成可能にする
- ユーザー修正は自動判定結果と分離して保存する
- 権限不足や取得失敗でクラッシュしない
- 重い集計処理はMainActor上で実行しない
- バックグラウンド処理の実行を前提にしすぎない
- 同じ処理を複数回実行してもデータが重複しない
- 日付境界は記録時の現地タイムゾーンと現地日付キーを使用する
- 判定閾値は画面や保存処理へ直接埋め込まず、設定値として分離する
- 高精度GPSの連続追跡は実装しない
- iPhone SE相当からPro Maxまでの縦向き表示とDynamic Typeに対応する

---

# 1. PermissionCoordinator

## 目的

位置情報、モーション、写真の権限状態を一元管理する。

## 責務

- 現在の権限状態を取得する
- 権限要求を実行する
- 位置情報の「常に許可」への移行を案内する
- 権限変更を各画面へ通知する
- 拒否時に設定アプリを開く導線を提供する

## 管理する権限

- 位置情報
- モーションとフィットネス
- 写真ライブラリ

## 入力

- 初回起動
- ユーザーによる許可ボタン操作
- アプリのフォアグラウンド復帰
- OS上での権限変更

## 出力

```swift
struct PermissionState {
    let location: LocationPermissionState
    let motion: MotionPermissionState
    let photos: PhotoPermissionState
}
```

## 失敗時

- 権限がなくてもアプリを終了しない
- 利用できない機能と理由を表示する
- 写真権限がなくても移動ログは閲覧できる
- モーション権限がなくても位置記録は継続する

## 完了条件

- 初回説明画面から権限要求できる
- 現在の権限状態を画面へ反映できる
- 拒否状態でもクラッシュしない
- 設定アプリへの導線が動作する

---

# 2. LocalTimeContextProvider

## 目的

各イベント取得時の現地タイムゾーン情報と現地日付キーを生成する。

## 責務

- 現在のタイムゾーン識別子を取得する
- UTCオフセット秒を取得する
- イベント時刻から現地日付キーを生成する
- 日付キーを後から現在のタイムゾーンで再計算しない

## 出力

```swift
struct RecordedTimeContext {
    let timeZoneIdentifier: String
    let utcOffsetSeconds: Int
    let localDateKey: String
}
```

## 完了条件

- 旅行中でも記録時の現地日付キーを生成できる
- タイムゾーン変更後も既存イベントの日付キーが変わらない
- 日付境界のテストが可能である

---

# 3. LocationMonitoringService

## 目的

Significant Location Changeを利用して、低消費電力で位置変化を監視し、生の位置イベントを保存する。

## 使用技術

- Core Location
- Significant Location Change Monitoring

## 責務

- SLC監視を開始する
- OSから受信した位置情報を最低限検証する
- 記録時の現地時間情報を付与する
- LocationEventとして保存する
- 対象日を再集計対象にする
- 必要に応じてバックグラウンド処理を予約する

## 行わない処理

- 高精度GPSの連続追跡
- 距離計算
- 滞在判定
- 移動区間分割
- 写真・動画取得
- ポリライン生成
- 車両分類

## 保存データ

```swift
struct LocationEventData {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let horizontalAccuracy: Double
    let speed: Double?
    let createdAt: Date
    let timeZoneIdentifier: String
    let utcOffsetSeconds: Int
    let localDateKey: String
}
```

## 最低限の受信時検証

次の場合は保存しない。

- 緯度または経度が不正
- タイムスタンプが大幅に未来
- 水平精度が負値
- 同一内容のイベントが重複している

精度が悪い位置点は受信時には保存してよい。最終的な除外は日別処理で行う。

## 失敗時

- 保存失敗を個人情報を含まないログへ記録する
- 次の位置イベント受信は継続する
- 位置取得エラーだけで監視を停止しない
- ユーザーによるアプリ強制終了後の自動再開は保証しない

## 完了条件

- バックグラウンド受信位置を端末内へ保存できる
- 保存時に重い処理を行わない
- 同一イベントを重複保存しない
- 新規ログ追加時に対象日を未処理状態へ戻せる
- 現地時間情報を保存できる

---

# 4. MotionActivityService

## 目的

Core Motionから移動状態を取得し、位置ログとは独立した生イベントとして保存する。

## 責務

- モーション権限を確認する
- 利用可能な移動状態を取得する
- 記録時の現地時間情報を付与する
- MotionEventとして保存する
- 対象日を再集計対象にする

## 保存する状態

- automotive
- walking
- running
- cycling
- stationary
- unknown
- confidence

## 保存データ

```swift
struct MotionEventData {
    let startDate: Date
    let endDate: Date?
    let activityType: MotionActivityType
    let confidence: MotionConfidence
    let timeZoneIdentifier: String
    let utcOffsetSeconds: Int
    let localDateKey: String
}
```

## 方針

- automotiveは「車」ではなく「車両系」として扱う
- 複数状態が同時に成立する場合を許容する
- confidenceが低いイベントも保存する
- 最終分類時にconfidenceを考慮する

## 失敗時

- 権限がない場合は停止する
- 位置情報記録には影響を与えない
- 取得不能時はunknownとして扱える設計にする

## 完了条件

- モーションイベントを時系列で保存できる
- モーション権限なしでも他機能が動作する
- 日別処理から該当時間帯の状態を取得できる
- 現地時間情報を保存できる

---

# 5. VisitMonitoringService

## 目的

CLVisitから推定到着時刻、出発時刻、滞在位置を取得し、滞在判定の補助情報として保存する。

## 責務

- Visit Monitoringを開始する
- 記録時の現地時間情報を付与する
- VisitEventを保存する
- 到着のみ判明している未完了Visitを扱う
- 出発時刻更新時に同一Visitを更新する
- 対象日を再集計対象にする

## 保存データ

```swift
struct VisitEventData {
    let latitude: Double
    let longitude: Double
    let arrivalDate: Date?
    let departureDate: Date?
    let horizontalAccuracy: Double
    let timeZoneIdentifier: String
    let utcOffsetSeconds: Int
    let localDateKey: String
}
```

## 方針

- CLVisitを滞在判定の優先証拠の一つとして扱う
- CLVisitが取得できなくても滞在判定を継続する
- CLVisitだけで全停止を検出できるとは仮定しない

## 完了条件

- 到着・出発時刻を保存できる
- 未完了Visitを後から更新できる
- 日別滞在判定で参照できる
- 現地時間情報を保存できる

---

# 6. PersistenceActor

## 目的

SwiftDataへのすべての読み書きを直列化し、競合を防ぐ。

## 責務

- 生イベントの保存
- 派生データの保存
- ユーザー修正の保存
- 日付単位のデータ取得
- 処理状態の更新
- 日付単位の派生データ置換
- 日付単位の完全削除

## 管理対象

- LocationEvent
- MotionEvent
- VisitEvent
- DayAggregate
- MovementSegment
- StaySegment
- ClassificationOverride
- StayOverride
- DayProcessingState

## 必須操作

```swift
protocol DayLogRepository {
    func saveLocationEvent(_ event: LocationEventData) async throws
    func saveMotionEvent(_ event: MotionEventData) async throws
    func saveVisitEvent(_ event: VisitEventData) async throws

    func rawEvents(for localDateKey: String) async throws -> RawDayEvents
    func aggregate(for localDateKey: String) async throws -> DayAggregate?
    func aggregates(in month: DateInterval) async throws -> [DayAggregate]

    func markDirty(localDateKey: String) async throws
    func replaceDerivedData(
        for localDateKey: String,
        result: DayProcessingResult
    ) async throws

    func deleteDay(localDateKey: String) async throws
}
```

## トランザクション方針

日別処理結果は、処理成功後にまとめて確定する。

途中まで作成したMovementSegmentやStaySegmentを表示対象にしない。

日付削除は、対象日の関連データを一括削除し、部分的な削除状態を残さない。

## 完了条件

- 同時アクセスでSwiftDataが競合しない
- 日付単位で派生データを安全に置換できる
- 生ログとユーザー修正を維持したまま再集計できる
- 指定日の関連データを完全削除できる

---

# 7. DayProcessingCoordinator

## 目的

未処理日を判定し、DayProcessingPipelineを日付単位で実行する。

## 責務

- 未処理日の取得
- 処理優先順位の決定
- 日別処理の開始・中断・再開
- 処理世代の整合性確認
- 完了後の状態更新

## 処理優先順位

1. ユーザーが現在開いている日
2. 当日
3. 前日
4. 古い未処理日

## 状態

```swift
enum ProcessingStatus {
    case pending
    case processing
    case completed
    case failed
}
```

## 世代管理

```swift
struct DayProcessingRevision {
    let rawRevision: Int
    let processedRevision: Int
}
```

`rawRevision > processedRevision`の場合は再処理する。

## 中断時

- 派生データを確定しない
- 状態をpendingまたはfailedへ戻す
- 次回同じ日を最初から再処理する

## 完了条件

- 未処理日を正しく検出できる
- 同じ日を重複処理しない
- 途中停止後に再実行できる
- 新しい生ログ追加後に再集計できる

---

# 8. DayProcessingPipeline

## 目的

指定日の生ログから、日別サマリー、移動区間、滞在区間、表示用経路を生成する。

## 入力

```swift
struct RawDayEvents {
    let locations: [LocationEventData]
    let motions: [MotionEventData]
    let visits: [VisitEventData]
    let classificationOverrides: [ClassificationOverride]
    let stayOverrides: [StayOverride]
}
```

## 処理順

1. LocationSanitizer
2. LocalDayBoundarySplitter
3. MovementSegmenter
4. StayDetector
5. MovementClassifier
6. RouteSimplifier
7. RouteLabelPlacementService
8. DaySummaryBuilder
9. ユーザー修正の適用
10. 永続化

## 出力

```swift
struct DayProcessingResult {
    let aggregate: DayAggregateData
    let movements: [MovementSegmentData]
    let stays: [StaySegmentData]
}
```

## 有効移動なしの扱い

次の条件では、その日を移動日として扱わない。

- 有効位置点が不足している
- 合計有効移動距離が1km未満
- 位置誤差のみと判断される
- 有効な移動区間を生成できない

## 完了条件

- 同じ入力から同じ結果を生成できる
- 各処理コンポーネントを独立して交換できる
- 1km未満の日を移動日から除外できる
- ユーザー修正を維持できる

---

# 9. LocalDayBoundarySplitter

## 目的

日付をまたぐ移動区間や滞在区間を、記録時の現地日付境界で分割する。

## 入力

- 時系列の位置イベント
- モーションイベント
- Visitイベント
- 各イベントの現地日付キー

## 出力

- 現地日付キーごとのイベント列
- 日付境界で分割された区間候補

## 方針

- 現在の端末タイムゾーンでは再計算しない
- 各イベントに保存された現地日付キーを使用する
- 日付削除時に指定日側だけを削除可能にする

## 完了条件

- 日付をまたぐ移動を日付ごとに分割できる
- タイムゾーン変更後も既存の所属日が変わらない
- 日付削除で隣接日のデータを消さない

---

# 10. LocationSanitizer

## 目的

位置ログから、距離計算や経路描画に不適切な点を除外する。

## 入力

- 時系列のLocationEvent

## 出力

```swift
struct SanitizedLocations {
    let accepted: [LocationEventData]
    let rejected: [RejectedLocation]
}
```

## 除外条件

MVP初期値は次のとおり。

```text
maximumHorizontalAccuracy = 500m
maximumPlausibleSpeed = 250km/h
duplicateDistance = 10m
duplicateTimeInterval = 30秒
```

次の場合は除外する。

- 水平精度が設定値を超える
- 隣接点間の推定速度が物理的に不自然
- 同時刻付近に同一座標が重複
- 座標が無効
- 時系列が不正

Significant Location Changeは点が粗いため、精度基準を厳しくしすぎない。

## 完了条件

- 明らかな座標ジャンプを除外できる
- 除外件数と理由を記録できる
- 元の生ログを変更しない

---

# 11. MovementSegmenter

## 目的

有効位置点を、連続した移動区間へ分割する。

## 入力

- SanitizedLocations
- MotionEvent
- VisitEvent

## 出力

- MovementSegmentCandidate
- GapCandidate

## 分割条件

次の要素を組み合わせて区間を分割する。

- 位置点間の時間差
- 停止候補
- CLVisitの到着・出発
- automotive、walkingなどの状態変化
- 現地日付境界

MVP初期値案：

```text
maximumContinuousGap = 90分
```

長時間位置点が存在しない場合は、同一移動区間として接続しない。

## 方針

- 取得点が粗いため、経路の連続性を断定しない
- 移動区間間の空白はStayDetectorへ渡す
- 日付をまたぐ移動は現地日付境界で分割する

## 完了条件

- 一日のログを複数移動区間へ分割できる
- 前後区間の開始・終了時刻を保持できる
- 区間ごとの距離計算に必要な座標を保持できる

---

# 12. StayDetector

## 目的

移動区間間の停止を、信号待ち・渋滞・立ち寄り候補へ分類する。

## 入力

- 移動区間候補
- 位置点間の空白
- MotionEvent
- VisitEvent

## 出力

```swift
struct StaySegmentData {
    let id: UUID
    let localDateKey: String
    let coordinate: Coordinate
    let estimatedArrival: Date
    let estimatedDeparture: Date
    let duration: TimeInterval
    let confidence: StayConfidence
    let source: StayDetectionSource
    let isVisible: Bool
}
```

## MVP判定基準

### 3分未満

原則として表示しない。

### 3分以上5分未満

次のいずれかがある場合のみ滞在候補とする。

- automotiveからwalkingへ変化
- automotiveからstationaryを経てwalkingへ変化
- CLVisitが取得されている
- ユーザーが立ち寄りとして確定した

### 5分以上

滞在候補とする。

ただし、次の条件では信号・渋滞候補として非表示にできる。

- automotiveからstationaryを経てautomotiveへ戻る
- walkingが確認されない
- CLVisitが存在しない
- 前後の座標が同一移動方向上に近い

## 停止地点の空間条件

MVP初期値：

```text
stayRadius = 150m
```

停止中の観測位置が概ね半径150m以内に収まる場合、同一滞在地点として扱う。

## 代表座標

優先順位は次のとおり。

1. CLVisitの座標
2. 停止中位置点の精度加重平均
3. 最後に確認できた移動位置
4. 次の移動開始位置との中間

## ユーザー修正

ユーザーは次を指定できる。

- 立ち寄りとして確定
- 非表示
- 自動判定へ戻す

地点名やメモは保存しない。

## 完了条件

- 3分未満の停止を原則非表示にできる
- 3〜5分停止を状態遷移で判定できる
- 5分以上を滞在候補にできる
- ユーザー修正を再集計後も維持できる

---

# 13. MovementClassifier

## 目的

移動区間を「車っぽい移動」「徒歩っぽい移動」「その他」へ仮分類する。

## 入力

- MovementSegmentCandidate
- 該当時間帯のMotionEvent
- 距離
- 移動時間
- 推定平均速度
- 停止回数

## 自動分類

### 車っぽい移動

次の情報を総合する。

- automotiveの占有時間
- automotiveのconfidence
- 推定平均速度
- 移動距離
- 区間継続時間

### 徒歩っぽい移動

次の情報を総合する。

- walkingの占有時間
- runningの占有時間
- 低い推定平均速度
- 短い位置点間距離

### その他

- cyclingが中心
- unknownが中心
- 複数状態が混在
- 信頼できる情報が不足

## 出力

```swift
struct MovementClassificationResult {
    let automaticType: AutomaticMovementType
    let confidence: ClassificationConfidence
    let evidence: [ClassificationEvidence]
}
```

## ユーザー分類

ユーザー指定分類は移動区間ごとに、自動分類とは別に保存する。

- 車
- 電車
- バス
- 徒歩
- その他

表示時はユーザー分類を優先する。

## 完了条件

- モーション情報なしでも分類結果を返せる
- 自動分類とユーザー分類を分離できる
- 区間単位で分類を修正できる
- 分類根拠をデバッグ時に確認できる

---

# 14. RouteSimplifier

## 目的

地図描画に必要な形状を保ちながら、位置点を間引く。

## 入力

- 移動区間の有効座標

## 出力

- 表示用座標列

## 方針

- 元データは変更しない
- 表示用データだけを簡略化する
- 短い区間は間引かない
- 地図のズームレベルに依存しない基本形状を保存する

MVP初期値案：

```text
simplificationTolerance = 30m
```

## 完了条件

- 長い経路の描画点数を削減できる
- 開始点と終了点を維持できる
- 元の経路形状を著しく崩さない

---

# 15. RouteLabelPlacementService

## 目的

移動区間の「時間・距離」ラベルを、ポリライン上の見やすい位置へ配置する。

## 入力

- 表示用ポリライン
- 区間距離
- 区間時間

## 出力

```swift
struct RouteLabel {
    let movementSegmentID: UUID
    let coordinate: Coordinate
    let text: String
}
```

## ラベル例

```text
32分・18.4km
1時間12分・54.8km
```

## 配置方法

単純な配列中央ではなく、経路距離の50%地点を基準にする。

候補地点が急カーブ、他ラベル、滞在ポイント、メディアアノテーションと重なる場合は、40〜60%の範囲で移動させる。

## 完了条件

- 1移動区間につき原則1ラベルを生成する
- 経路距離の中央付近へ配置できる
- ラベルタップ対象となる区間IDを保持できる

---

# 16. DaySummaryBuilder

## 目的

一日の移動区間と滞在区間から、カレンダーと詳細画面用の日別サマリーを生成する。

## 出力項目

- 総移動距離
- 総移動時間
- 開始時刻
- 終了時刻
- 記録点数
- 除外位置点数
- 写真・動画枚数
- 移動区間数
- 滞在地点数
- 総滞在時間
- 車っぽい移動時間
- 徒歩っぽい移動時間
- 代表仮分類
- 有効移動の有無

日全体の平均速度と最高速度は生成しない。

## 有効移動日の判定

MVP初期値：

```text
minimumValidDayDistance = 1km
minimumValidMovementSegments = 1
```

基準未満の日は、カレンダー上で移動日として表示しない。

## 完了条件

- カレンダー用の距離を生成できる
- 1km未満の日を除外できる
- 詳細画面用の統計を生成できる
- 日全体の平均速度や最高速度を生成しない

---

# 17. BackgroundTaskCoordinator

## 目的

充電中を優先して、未処理日の集計をバックグラウンドで実行する。

## 責務

- BGProcessingTaskを登録する
- 外部電源を要求する
- 未処理日が存在する場合にタスクを予約する
- システムからの終了要求へ対応する
- 処理終了後、必要なら次回タスクを再予約する

## 方針

- 実行タイミングはiOSへ委ねる
- 充電開始直後の実行を保証しない
- バックグラウンド処理だけに依存しない
- 古い未処理日から処理する
- 終了要求時に現在の日付処理を中断する

## フォールバック

- アプリ起動時に未処理日を軽く処理する
- 日別詳細表示時に対象日を優先処理する

## 完了条件

- 未処理日がある場合にタスク予約できる
- 中断後に再実行できる
- バックグラウンドタスク未実行でもUIから補完できる

---

# 18. PhotoLibraryRepository

## 目的

Apple Photosライブラリから、指定日の写真と動画を参照取得する。

## 責務

- 指定日のPHAssetを取得する
- 写真権限状態を返す
- 写真・動画サムネイルを要求サイズで取得する
- 写真プレビュー用データを取得する
- 動画再生用アセットを取得する
- 写真・動画本体を永続保存しない

## 入力

- 日付範囲
- 必要サムネイルサイズ
- PHAsset識別子

## 出力

```swift
struct MediaAssetReference {
    let localIdentifier: String
    let mediaType: MediaType
    let creationDate: Date?
    let location: Coordinate?
    let duration: TimeInterval?
}
```

## キャッシュ

- サムネイルはメモリキャッシュ可能
- 写真・動画本体は永続キャッシュしない
- メモリ警告時に破棄できる

## 完了条件

- 指定日の写真・動画を取得できる
- 写真と動画のサムネイルを取得できる
- 限定アクセスへ対応できる
- 写真権限拒否時に空結果と状態を返せる

---

# 19. MediaEligibilityPolicy

## 目的

写真ライブラリ内のメディアから、移動日記へ表示する対象を選別する。

## 採用対象

- 静止画
- 動画
- 撮影日時を持つメディア

## 確実に除外する対象

- スクリーンショット
- 画面収録

## 方針

- ダウンロード画像や他アプリ保存画像を無理に除外しない
- メタデータだけで確実に除外できないメディアは表示対象に残す
- AIや画像内容の解析を使用しない

## 出力

```swift
enum MediaEligibility {
    case eligible
    case ineligible
}
```

## 完了条件

- スクリーンショットを除外できる
- 画面収録を除外できる
- その他の不確実なメディアを誤って大量除外しない
- 判定ロジックを後から交換できる

---

# 20. MediaPlacementService

## 目的

位置情報を持つ対象メディアを、その日の地図へ配置する。

## 入力

- 対象MediaAssetReference
- 日別の有効位置点
- 移動区間

## 配置規則

### 位置情報あり

メディアの撮影位置を使用する。

記録経路から一定距離以内の場合は、関連する移動区間IDを保持する。

MVP初期値案：

```text
maximumRouteMediaDistance = 500m
```

### 位置情報なし

地図へ配置しない。

撮影時刻による仮配置は行わない。

日別詳細のメディアグリッドには表示可能とする。

## 出力

```swift
struct MediaPlacement {
    let assetIdentifier: String
    let coordinate: Coordinate
    let relatedMovementSegmentID: UUID?
}
```

## 完了条件

- 位置情報付き写真・動画を地図へ配置できる
- 位置情報なしメディアを地図へ配置しない
- グリッド表示対象と地図表示対象を分離できる

---

# 21. CalendarFeature

## 目的

移動した日と日別移動距離を、月表示カレンダーで確認できるようにする。

## 画面表示

- 月表示カレンダー
- 日付
- 移動した日の総移動距離
- 前月・次月操作

## データ取得

指定月のDayAggregateだけを取得する。

生位置ログは読み込まない。

## 表示規則

- 有効移動がある日のみ距離を表示する
- 1km未満の日は移動日として扱わない
- 移動なしの日はマーカーを表示しない
- 移動なしの日は日別詳細へ遷移しない
- 週の開始曜日は端末設定に従う
- 未処理日は必要に応じて処理を予約する
- 移動日をタップするとDayDetailFeatureへ遷移する

## 完了条件

- 月単位で高速に表示できる
- 移動なしの日を視覚的に除外できる
- 月送りできる
- 端末の先頭曜日設定に従える
- 移動日だけ日別詳細へ遷移できる

---

# 22. DayDetailFeature

## 目的

選択日の地図、基本サマリー、詳細統計、写真・動画グリッドを表示する。

## 初期レイアウト

- 上部約60%：地図プレビュー
- 下部約40%：基本サマリー
- 全体を縦スクロール可能にする
- 固定ピクセル値ではなく画面サイズに適応する

## 基本サマリー

- 総移動距離
- 総移動時間
- 開始時刻
- 終了時刻
- 写真・動画枚数
- 代表仮分類

## 詳細統計

- 移動区間数
- 滞在地点数
- 総滞在時間
- 記録点数
- 除外位置点数
- 車っぽい移動時間
- 徒歩っぽい移動時間

## メディアグリッド

- 画面最下部へ表示する
- 原則4列とする
- 各セルは正方形とする
- 写真と動画を表示する
- 動画セルには再生マークまたは再生時間を重ねる
- 小型画面やDynamic Typeで破綻する場合は列数またはサイズを調整してよい

## 操作

- 地図タップでRouteMapFeatureを全画面表示
- 移動区間の自動分類をユーザー分類へ修正
- 滞在地点を確定、非表示、または自動判定へ戻す
- メディアタップでMediaPreviewFeatureへ遷移
- 日付ログ削除を開始する

## 未処理日の扱い

対象日が未処理の場合は、その日だけ優先処理する。

処理中は既存の集計結果があれば表示し、再集計中であることを示す。

## 完了条件

- 地図とサマリーを同時表示できる
- 下スクロールで詳細統計とメディアグリッドを確認できる
- 分類と滞在地点を修正できる
- 拡大地図とメディアプレビューへ遷移できる
- 日付ログ削除を実行できる
- iPhone SE相当からPro Maxまで破綻しない

---

# 23. RouteMapFeature

## 目的

その日の移動区間、滞在地点、位置情報付き写真・動画を全画面地図で表示する。

## 表示要素

- 移動区間ポリライン
- 区間ごとの時間・距離ラベル
- 滞在地点
- 推定滞在時間ラベル
- 写真・動画サムネイル
- メディアクラスタ

## 地図モード

### Preview

DayDetailFeature内で使用する。

- 操作を制限
- ラベルを簡略表示
- タップで全画面へ遷移

### Full

全画面表示。

- ズーム
- パン
- ポリライン選択
- 滞在地点選択
- メディア選択
- クラスタ展開

## タップ時

### 移動区間

- 開始時刻
- 終了時刻
- 移動時間
- 距離
- 推定平均速度
- 仮分類
- ユーザー分類

### 滞在地点

- 到着推定時刻
- 出発推定時刻
- 推定滞在時間
- 判定信頼度

### 写真・動画

MediaPreviewFeatureへ遷移する。

## 完了条件

- 複数ポリラインを表示できる
- ラベルを区間上へ表示できる
- 滞在地点を大きめに表示できる
- 位置情報付き写真・動画だけを地図表示できる
- メディアが密集した場合にクラスタ表示できる

---

# 24. MediaPreviewFeature

## 目的

地図または日別メディアグリッドから、写真・動画をプレビューする。

## 表示

- 写真または動画
- 撮影日時
- 撮影位置がある場合は位置情報
- 動画再生コントロール
- 共有ボタン

## 方針

- 元メディアはApple Photosライブラリを参照する
- アプリ内へ複製しない
- 複数選択機能は実装しない
- 純正写真アプリ側で削除された場合は参照不能表示にする

## 完了条件

- 写真をプレビューできる
- 動画を再生できる
- 削除済み資産でクラッシュしない
- 標準共有画面を開ける

---

# 25. ShareService

## 目的

写真または動画をiOS標準共有シートへ渡す。

## 責務

- 共有対象メディアをPhotoKitから取得する
- 必要に応じて一時ファイルを生成する
- UIActivityViewControllerへ渡す
- 共有完了後またはキャンセル後に一時ファイルを削除する

## 共有先

- AirDrop
- メッセージ
- LINE
- メール
- ファイル保存
- その他のiOS標準共有先

## 方針

- 共有時だけメディア実体を取得する
- 共有データを永続保存しない
- 共有対象は1件のみ
- MVPでは複数選択しない

## 完了条件

- 写真を共有できる
- 動画を共有できる
- 一時ファイルを共有後に削除できる
- 共有キャンセル時もクリーンアップできる

---

# 26. DeleteDayLogUseCase

## 目的

指定日の移動ログと関連データを、確認後に完全削除する。

## 入力

- 現地日付キー
- ユーザーの削除確認結果

## 削除対象

- 指定日のLocationEvent
- 指定日のMotionEvent
- 指定日のVisitEvent
- 指定日のDayAggregate
- 指定日のMovementSegment
- 指定日のStaySegment
- 指定日のClassificationOverride
- 指定日のStayOverride
- 指定日のDayProcessingState

## 削除しない対象

- Apple Photosライブラリ内の写真
- Apple Photosライブラリ内の動画
- 他の日付に属するログや区間

## 方針

- 確認ダイアログ後に即時完全削除する
- アプリ内ゴミ箱や復元機能は実装しない
- 日付をまたぐ区間は、現地日付境界で分割済みであることを前提とする
- 削除は一括処理し、部分的な削除状態を残さない

## 完了条件

- 指定日の関連データだけを削除できる
- 隣接日のデータを削除しない
- 写真・動画を削除しない
- 削除後にカレンダーと詳細画面へ反映される

---

# 27. AppLifecycleCoordinator

## 目的

アプリ起動、フォアグラウンド復帰、バックグラウンド移行時の処理を調整する。

## 起動時

- 権限状態を更新する
- SLC監視状態を確認する
- 未処理日の有無を確認する
- 必要なら軽い日別処理を開始する
- バックグラウンド処理を予約する

## フォアグラウンド復帰時

- 権限変更を反映する
- 写真ライブラリ変更を反映する
- 当日と前日の処理状態を確認する

## バックグラウンド移行時

- 未保存データを確定する
- 必要ならバックグラウンドタスクを予約する

## 完了条件

- 起動時に各サービスを正しい順序で初期化できる
- 権限変更を画面へ反映できる
- 未処理日を自動的に検出できる

---

# 28. LoggingService

## 目的

バックグラウンド処理や位置取得の問題を、個人情報を漏らさず記録する。

## 記録対象

- 位置監視開始・停止
- 位置イベント保存成功・失敗
- モーション取得成功・失敗
- Visit取得成功・失敗
- 日別処理開始・終了・中断
- 除外位置点数
- 写真・動画取得件数
- 権限状態変更
- 日付削除成功・失敗

## 記録しない情報

- 正確な緯度経度
- 写真・動画内容
- 詳細な移動経路
- ユーザーが修正した分類内容

## 完了条件

- 問題調査に必要な処理状態を確認できる
- 生の位置情報やメディア内容をログへ残さない

---

# 29. MVP実装順

## Phase 1：記録基盤

1. PersistenceActor
2. LocalTimeContextProvider
3. PermissionCoordinator
4. LocationMonitoringService
5. AppLifecycleCoordinator

完了状態：

- 権限を許可できる
- SLCによるバックグラウンド位置イベントを保存できる
- 記録時の現地時間情報を保存できる

## Phase 2：日別集計

1. LocationSanitizer
2. LocalDayBoundarySplitter
3. MovementSegmenter
4. DaySummaryBuilder
5. DayProcessingPipeline
6. DayProcessingCoordinator

完了状態：

- 保存位置から日別距離を生成できる
- 1km以上の日を移動日として判定できる
- 日付をまたぐ移動を現地日付境界で分割できる

## Phase 3：基本UI

1. CalendarFeature
2. DayDetailFeature
3. RouteMapFeature

完了状態：

- カレンダーから移動日を選択できる
- 日別経路と基本サマリーを表示できる
- SE相当からPro Maxまで縦向きで表示できる

## Phase 4：写真・動画

1. PhotoLibraryRepository
2. MediaEligibilityPolicy
3. MediaPlacementService
4. MediaPreviewFeature
5. ShareService

完了状態：

- 日別詳細最下部に写真・動画グリッドを表示できる
- 位置情報付きメディアを地図上に表示できる
- 写真をプレビュー・共有できる
- 動画をサムネイル表示・再生・共有できる

## Phase 5：移動・滞在分類

1. MotionActivityService
2. VisitMonitoringService
3. StayDetector
4. MovementClassifier
5. RouteLabelPlacementService

完了状態：

- 車っぽい移動を仮分類できる
- 滞在地点と滞在時間を表示できる
- ポリライン上に時間と距離を表示できる
- ポリライン選択時に区間平均速度を表示できる

## Phase 6：バックグラウンド集計

1. BackgroundTaskCoordinator
2. 中断・再開処理
3. 処理世代管理

完了状態：

- 充電中を優先して未処理日を集計できる
- 起動時と詳細表示時に処理を補完できる

## Phase 7：日付削除

1. DeleteDayLogUseCase
2. 削除確認UI
3. カレンダー・詳細画面の更新

完了状態：

- 指定日のログと関連データを完全削除できる
- Apple Photos内の写真・動画と隣接日のログを削除しない

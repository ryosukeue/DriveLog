# Interfaces

## 1. 目的

この文書は、DriveLog内の各コンポーネントが持つ責務、公開インターフェース、入力、出力、エラー、依存方向を定義する。

主な目的は次のとおり。

- 責務の境界を明確にする
- UI、OS機能、永続化、日別処理を分離する
- Codexが必要以上の範囲を変更しないようにする
- 実装をFakeへ差し替えてテスト可能にする
- 同じ機能を複数箇所へ重複実装しない

実装時は、ViewやViewModelからPlatform APIやSwiftDataを直接呼ばない。

## 2. 依存方向

依存方向は次のとおりとする。

```text
Feature / Presentation
        ↓
Application UseCase
        ↓
Domain Protocol / Value
        ↓
Data・Platform Implementation
```

上位層は下位層の具体実装を知らない。

### 禁止する依存

- View → Core Location
- View → Core Motion
- View → PhotoKit
- View → SwiftData
- ViewModel → ModelContext
- Domain → UIKit
- Domain → AVFoundation
- Domain → MapKit
- Domain → SwiftData
- Repository Protocol → SwiftData Model
- UseCase → OSの権限API

## 3. インターフェース分類

DriveLogのProtocolは次の4分類とする。

```text
Platform Protocols
- OS機能との接続

Repository Protocols
- 永続化されたデータの保存・取得

Application UseCases
- 画面やライフサイクルから実行する操作

Supporting Protocols
- 時刻、タイムゾーン、地図用変換、ログなど
```

Protocolは必要な責務だけを公開し、内部実装の詳細を漏らさない。

## 4. 共通規約

### 4.1 非同期処理

1回の処理で結果を返す操作は、原則として`async throws`を使用する。

```swift
func loadDayDetail(localDateKey: String) async throws -> DayDetailData
```

継続的に変更が発生する監視処理は、`AsyncStream`または`AsyncThrowingStream`を使用する。

```swift
var events: AsyncStream<LocationEventData> { get }
```

Platform内部でDelegateやCallbackを使用してよいが、Application層へは可能な限りSwift Concurrency形式で公開する。

### 4.2 Sendable

Domain Value、Repositoryの入出力、UseCaseの入出力は可能な限り`Sendable`へ準拠させる。

UIKit、MapKit、AVFoundationの型はPlatformまたはPresentation境界内に限定する。

### 4.3 MainActor

次だけをMainActor上で実行する。

- SwiftUI状態の更新
- `UIImage`や`AVPlayer`を利用するUI処理
- `UIViewController`の表示
- `MKMapView`の更新

次はMainActor上で実行しない。

- 距離計算
- 区間分割
- 滞在判定
- 経路簡略化
- SwiftDataの大量読み書き
- 写真・動画メタデータの大量検索

### 4.4 命名

Protocol名は役割を表す。

- OS機能：`LocationProviding`
- Repository：`RawEventRepository`
- Builder：`MapSceneBuilding`
- UseCase：`LoadDayDetailUseCase`

具体実装名には技術名を含めてよい。

例：

- `CoreLocationProvider`
- `SwiftDataRawEventRepository`
- `PhotoKitLibraryProvider`

## 5. 共通エラー

アプリ上位層へ公開するエラーは`DriveLogError`へ変換する。

```swift
enum DriveLogError: Error, Sendable, Equatable {
    case permissionDenied(PermissionKind)
    case permissionRestricted(PermissionKind)
    case monitoringUnavailable
    case persistenceFailure(code: String)
    case processingFailure(localDateKey: String, code: String)
    case invalidData
    case mediaUnavailable
    case mediaAccessLimited
    case backgroundTaskUnavailable
    case deletionFailure(localDateKey: String)
    case cancelled
    case unknown(code: String)
}
```

### 方針

- OSやSwiftDataの具体的なエラー型をFeature層へ直接渡さない
- ユーザー表示用メッセージはPresentation層で決定する
- 元エラーは個人情報を含まない形でLoggingへ渡してよい
- 緯度、経度、写真名、動画名、移動経路をエラーへ含めない
- キャンセルは通常の失敗と区別する

## 6. Platform Protocols

# 6.1 LocationProviding

## 目的

Significant Location Changeの開始、停止、状態確認、位置イベント受信を抽象化する。

```swift
protocol LocationProviding: Sendable {
    var monitoringState: LocationMonitoringState { get async }
    var events: AsyncStream<LocationProviderEvent> { get }

    func startSignificantLocationMonitoring() async throws
    func stopSignificantLocationMonitoring() async
}
```

```swift
enum LocationMonitoringState: Sendable, Equatable {
    case stopped
    case starting
    case running
    case unavailable
    case failed(code: String)
}
```

```swift
enum LocationProviderEvent: Sendable {
    case location(LocationEventData)
    case stateChanged(LocationMonitoringState)
    case error(DriveLogError)
}
```

## 責務

- Core LocationのDelegateを内部で扱う
- SLC監視だけを開始する
- 受信値をDomain用の`LocationEventData`へ変換する
- 現地時間情報は`LocalTimeContextProviding`から取得する
- 高精度GPSを開始しない

## 行わない処理

- SwiftData保存
- 距離計算
- 日別集計
- 移動区間分割
- 滞在判定

## Fake要件

`FakeLocationProvider`は次を満たす。

- 任意のLocationEventDataを流せる
- 任意のエラーを流せる
- start/stop呼び出し回数を確認できる
- monitoringStateを任意に変更できる

# 6.2 MotionProviding

## 目的

Core Motionの取得を抽象化する。

```swift
protocol MotionProviding: Sendable {
    var monitoringState: MotionMonitoringState { get async }
    var events: AsyncStream<MotionProviderEvent> { get }

    func startMonitoring() async throws
    func stopMonitoring() async
}
```

```swift
enum MotionProviderEvent: Sendable {
    case motion(MotionEventData)
    case stateChanged(MotionMonitoringState)
    case error(DriveLogError)
}
```

## 責務

- Core Motionの元フラグを保持したイベントを生成する
- confidenceを保存可能な形へ変換する
- 権限拒否時に位置監視へ影響を与えない

## Fake要件

- 任意のMotionEventDataを流せる
- 権限拒否を再現できる
- 複数フラグが同時にtrueのイベントを流せる

# 6.3 VisitProviding

## 目的

CLVisitの監視を抽象化する。

```swift
protocol VisitProviding: Sendable {
    var monitoringState: VisitMonitoringState { get async }
    var events: AsyncStream<VisitProviderEvent> { get }

    func startMonitoring() async throws
    func stopMonitoring() async
}
```

```swift
enum VisitProviderEvent: Sendable {
    case visit(VisitEventData)
    case stateChanged(VisitMonitoringState)
    case error(DriveLogError)
}
```

## 責務

- 到着だけ判明したVisitを受信する
- 出発判明後の更新イベントを返す
- 同一Visitの永続化判定自体はRepository側へ委ねる

## Fake要件

- 未完了Visitを流せる
- 同じVisitの出発更新を流せる
- CLVisitが来ない状態を再現できる

# 6.4 PhotoLibraryProviding

## 目的

PhotoKitによる写真・動画の検索、サムネイル、プレビュー、共有用実体取得を抽象化する。

Domain層ではなくPlatform境界のProtocolとする。

```swift
protocol PhotoLibraryProviding: Sendable {
    func authorizationState() async -> PhotoPermissionState

    func fetchAssets(
        in interval: DateInterval
    ) async throws -> [MediaAssetReference]

    func requestThumbnail(
        localIdentifier: String,
        targetSize: CGSize
    ) async throws -> UIImage

    func requestPhotoPreview(
        localIdentifier: String
    ) async throws -> UIImage

    func requestVideoAsset(
        localIdentifier: String
    ) async throws -> AVAsset

    func requestShareableResource(
        localIdentifier: String
    ) async throws -> ShareableMediaResource

    var libraryChanges: AsyncStream<PhotoLibraryChange> { get }
}
```

## 方針

- `UIImage`、`CGSize`、`AVAsset`はPlatformまたはPresentation内だけで扱う
- Domain Entityへこれらの型を保存しない
- 写真・動画本体を永続保存しない
- 共有用一時ファイルはShareServiceが管理する
- 限定アクセス時はアクセス可能な資産だけ返す

## Fake要件

- 任意のMediaAssetReference一覧を返せる
- サムネイル取得成功・失敗を再現できる
- 削除済み資産を再現できる
- ライブラリ変更イベントを流せる
- 動画資産取得を再現できる

# 6.5 PermissionManaging

## 目的

位置情報、モーション、写真権限の取得と要求を抽象化する。

```swift
@MainActor
protocol PermissionManaging: AnyObject {
    var currentState: PermissionState { get }
    var updates: AsyncStream<PermissionState> { get }

    func refresh() async
    func requestLocationWhenInUse() async
    func requestLocationAlways() async
    func requestMotion() async
    func requestPhotos() async
    func openSystemSettings()
}
```

## 方針

- 具体実装の`PermissionCoordinator`は`@Observable`にしてよい
- FeatureはOS APIを直接呼ばない
- Protocol利用側はPermissionStateだけを参照する

## Fake要件

- 任意の権限状態を返せる
- 権限変更をStreamへ流せる
- 各要求関数の呼び出しを確認できる

# 6.6 BackgroundTaskScheduling

## 目的

BGTaskの登録と予約を抽象化する。

```swift
protocol BackgroundTaskScheduling: Sendable {
    func registerProcessingTask() throws

    func scheduleProcessingTask(
        requiresExternalPower: Bool
    ) throws

    func cancelPendingProcessingTask()
}
```

## 方針

- 実行ハンドラの詳細はBackgroundTaskCoordinator内部へ閉じる
- 何日処理するかはSchedulerが決めない
- OSが実行時刻を保証しない前提とする

## Fake要件

- 登録回数を確認できる
- 予約条件を確認できる
- 予約失敗を再現できる
- キャンセル呼び出しを確認できる

# 6.7 SharePresenting

## 目的

iOS標準共有シートの表示を抽象化する。

```swift
@MainActor
protocol SharePresenting: AnyObject {
    func presentShareSheet(
        resource: ShareableMediaResource
    ) async throws
}
```

## 方針

- `UIActivityViewController`は具体実装内だけで扱う
- 共有完了・キャンセル後の一時ファイル削除はShareServiceが保証する

# 6.8 Logging

## 目的

個人情報を含めずに処理状態を記録する。

```swift
protocol Logging: Sendable {
    func debug(_ event: LogEvent)
    func info(_ event: LogEvent)
    func error(_ event: LogEvent)
}
```

```swift
enum LogEvent: Sendable, Equatable {
    case locationMonitoringStarted
    case locationMonitoringStopped
    case locationEventSaved(localDateKey: String)
    case locationEventRejected(reasonCode: String)
    case motionEventSaved(localDateKey: String)
    case visitEventSaved(localDateKey: String)
    case dayProcessingStarted(localDateKey: String)
    case dayProcessingCompleted(localDateKey: String)
    case dayProcessingFailed(localDateKey: String, code: String)
    case mediaCacheRefreshed(localDateKey: String, count: Int)
    case dayDeletionCompleted(localDateKey: String)
    case dayDeletionFailed(localDateKey: String, code: String)
    case permissionStateChanged
}
```

## 禁止

LogEventへ次を追加しない。

- 緯度
- 経度
- 写真・動画名
- PhotoKit localIdentifier
- 詳細な移動経路
- ユーザー分類の内容

## Fake要件

- 受信したLogEventを配列として保持できる
- テストから発生順序を確認できる

## 7. Supporting Protocols

# 7.1 Clock

## 目的

現在時刻への直接依存を除く。

```swift
protocol Clock: Sendable {
    var now: Date { get }
}
```

## 推奨実装

```swift
struct SystemClock: Clock {
    var now: Date { Date() }
}
```

## Fake要件

固定時刻を返せる。

# 7.2 TimeZoneProviding

## 目的

現在のタイムゾーン取得を抽象化する。

```swift
protocol TimeZoneProviding: Sendable {
    var current: TimeZone { get }
}
```

## Fake要件

- 任意のTimeZoneを返せる
- テスト途中でタイムゾーンを変更できる

# 7.3 LocalTimeContextProviding

## 目的

イベント取得時のタイムゾーン情報と現地日付キー生成を抽象化する。

```swift
protocol LocalTimeContextProviding: Sendable {
    func makeContext(for date: Date) -> RecordedTimeContext
}
```

```swift
struct RecordedTimeContext: Sendable, Equatable {
    let timeZoneIdentifier: String
    let utcOffsetSeconds: Int
    let localDateKey: String
}
```

## 依存

- `TimeZoneProviding`
- Calendar生成ロジック

# 7.4 StableIDGenerating

## 目的

MovementSegmentとStaySegmentの決定論的stableID生成を抽象化する。

```swift
protocol StableIDGenerating: Sendable {
    func movementSegmentID(
        localDateKey: String,
        startDate: Date,
        endDate: Date
    ) -> String

    func staySegmentID(
        localDateKey: String,
        arrivalDate: Date,
        departureDate: Date,
        latitude: Double,
        longitude: Double
    ) -> String
}
```

## 方針

- 実装はSHA-256を使用する
- 丸め規則は`data-model.md`と`processing-rules.md`に従う
- 同じ入力から必ず同じ出力を返す

# 7.5 RouteEncoding

## 目的

表示用ポリラインのData変換を抽象化する。

```swift
protocol RouteEncoding: Sendable {
    func encode(_ coordinates: [RouteCoordinate]) throws -> Data
    func decode(_ data: Data) throws -> [RouteCoordinate]
}
```

## 方針

- V1はPropertyListEncoderのbinary形式
- Payload内にformatVersionを持つ
- デコード不能時は`DriveLogError.invalidData`

# 7.6 MapSceneBuilding

## 目的

日別データから地図表示専用のMapSceneを生成する。

```swift
protocol MapSceneBuilding: Sendable {
    func build(
        movements: [MovementSegmentData],
        stays: [StaySegmentData],
        media: [MediaPlacement]
    ) -> MapScene
}
```

## 責務

- ポリライン表示モデル生成
- 区間ラベル生成結果の組み込み
- 滞在アノテーション生成
- メディアアノテーション生成
- 初期表示領域計算

## 行わない処理

- SwiftData取得
- PhotoKit取得
- MKMapView操作
- ユーザー操作処理

## 8. Repository Protocols

Repository Protocolは用途別に分割する。

具体実装はすべて同じ`PersistenceActor`を共有してよい。

# 8.1 RawEventRepository

## 目的

Location、Motion、Visitの生イベントを保存・取得する。

```swift
protocol RawEventRepository: Sendable {
    func saveLocationEvent(
        _ event: LocationEventData
    ) async throws -> RawEventSaveResult

    func saveMotionEvent(
        _ event: MotionEventData
    ) async throws -> RawEventSaveResult

    func saveOrUpdateVisitEvent(
        _ event: VisitEventData
    ) async throws -> RawEventSaveResult

    func rawEvents(
        for localDateKey: String
    ) async throws -> RawDayEvents

    func deleteRawEvents(
        for localDateKey: String
    ) async throws
}
```

```swift
enum RawEventSaveResult: Sendable, Equatable {
    case inserted
    case updated
    case duplicateIgnored
}
```

## 責務

- 位置イベントの近似重複判定
- Visitの同一候補判定と更新
- 保存成功時のrawRevision更新
- 生ログの日付単位取得

## 行わない処理

- 日別距離計算
- 派生データ生成
- Override適用
- メディア検索

# 8.2 ProcessingStateRepository

## 目的

日別処理状態と世代を管理する。

```swift
protocol ProcessingStateRepository: Sendable {
    func state(
        for localDateKey: String
    ) async throws -> DayProcessingStateData

    func pendingDateKeys() async throws -> [String]

    func markDirty(
        localDateKey: String
    ) async throws

    func markProcessing(
        localDateKey: String,
        attemptedAt: Date
    ) async throws -> DayProcessingRevision

    func markCompleted(
        localDateKey: String,
        processedRevision: Int,
        completedAt: Date
    ) async throws

    func markFailed(
        localDateKey: String,
        code: String,
        failedAt: Date
    ) async throws

    func deleteState(
        for localDateKey: String
    ) async throws
}
```

## 責務

- rawRevisionとprocessedRevisionの管理
- pending、processing、completed、failed状態管理
- 未処理日の一覧取得

# 8.3 DerivedDataRepository

## 目的

DayAggregate、MovementSegment、StaySegmentを保存・取得する。

```swift
protocol DerivedDataRepository: Sendable {
    func aggregate(
        for localDateKey: String
    ) async throws -> DayAggregateData?

    func aggregates(
        in month: LocalMonth
    ) async throws -> [DayAggregateData]

    func movementSegments(
        for localDateKey: String
    ) async throws -> [MovementSegmentData]

    func staySegments(
        for localDateKey: String
    ) async throws -> [StaySegmentData]

    func replaceDerivedData(
        for localDateKey: String,
        result: DayProcessingResult,
        processedRevision: Int
    ) async throws

    func deleteDerivedData(
        for localDateKey: String
    ) async throws
}
```

## トランザクション要件

`replaceDerivedData`は次を一括で行う。

1. 既存の派生データを削除
2. 新しいDayAggregateを保存
3. 新しいMovementSegmentを保存
4. 新しいStaySegmentを保存
5. 処理世代との整合性を確認
6. 1回の保存で確定

途中状態をUIへ見せない。

# 8.4 OverrideRepository

## 目的

ユーザーによる分類修正と滞在修正を保存・取得する。

```swift
protocol OverrideRepository: Sendable {
    func classificationOverrides(
        for localDateKey: String
    ) async throws -> [ClassificationOverrideData]

    func stayOverrides(
        for localDateKey: String
    ) async throws -> [StayOverrideData]

    func upsertClassificationOverride(
        _ override: ClassificationOverrideData
    ) async throws

    func upsertStayOverride(
        _ override: StayOverrideData
    ) async throws

    func deleteOverrides(
        for localDateKey: String
    ) async throws
}
```

## 方針

- 同じoverrideKeyは更新する
- 自動再集計では削除しない
- 日付完全削除時だけまとめて削除する
- stableID不一致時の近似適用判定はProcessing側が行う

# 8.5 MediaCacheRepository

## 目的

PhotoKit参照キャッシュを保存・取得する。

```swift
protocol MediaCacheRepository: Sendable {
    func cachedAssets(
        for localDateKey: String
    ) async throws -> [MediaAssetReference]

    func upsertAssets(
        _ assets: [MediaAssetReference],
        for localDateKey: String,
        validatedAt: Date
    ) async throws

    func removeAssets(
        localIdentifiers: [String]
    ) async throws

    func replaceAssets(
        for localDateKey: String,
        assets: [MediaAssetReference],
        validatedAt: Date
    ) async throws

    func deleteCache(
        for localDateKey: String
    ) async throws
}
```

## 責務

- localIdentifierの一意性維持
- 日付単位のキャッシュ置換
- PhotoKit側で削除された資産のキャッシュ削除
- 位置情報なしメディアもグリッド用に保持

## 行わない処理

- サムネイル保存
- 動画本体保存
- MediaEligibility判定
- 地図配置判定

# 8.6 DayDeletionRepository

## 目的

指定日の全関連データを一括削除する。

```swift
protocol DayDeletionRepository: Sendable {
    func deleteDay(
        localDateKey: String
    ) async throws
}
```

## 実装要件

同一PersistenceActor内で次を削除する。

- LocationEvent
- MotionEvent
- VisitEvent
- DayAggregate
- MovementSegment
- StaySegment
- ClassificationOverride
- StayOverride
- DayProcessingState
- MediaAssetCache

Apple Photos内の資産は削除しない。

## 9. Processing Protocols

# 9.1 LocationSanitizing

```swift
protocol LocationSanitizing: Sendable {
    func sanitize(
        _ locations: [LocationEventData]
    ) -> SanitizedLocations
}
```

# 9.2 LocalDayBoundarySplitting

```swift
protocol LocalDayBoundarySplitting: Sendable {
    func split(
        rawEvents: RawDayEvents
    ) -> [String: RawDayEvents]
}
```

# 9.3 MovementSegmenting

```swift
protocol MovementSegmenting: Sendable {
    func segment(
        locations: SanitizedLocations,
        motions: [MotionEventData],
        visits: [VisitEventData]
    ) -> MovementSegmentationResult
}
```

# 9.4 StayDetecting

```swift
protocol StayDetecting: Sendable {
    func detect(
        segmentation: MovementSegmentationResult,
        motions: [MotionEventData],
        visits: [VisitEventData],
        overrides: [StayOverrideData]
    ) -> [StaySegmentData]
}
```

# 9.5 MovementClassifying

```swift
protocol MovementClassifying: Sendable {
    func classify(
        segment: MovementSegmentCandidate,
        motions: [MotionEventData]
    ) -> MovementClassificationResult
}
```

# 9.6 RouteSimplifying

```swift
protocol RouteSimplifying: Sendable {
    func simplify(
        _ coordinates: [RouteCoordinate]
    ) -> [RouteCoordinate]
}
```

# 9.7 RouteLabelPlacing

```swift
protocol RouteLabelPlacing: Sendable {
    func makeLabel(
        for segment: MovementSegmentData,
        occupiedCoordinates: [RouteCoordinate]
    ) -> RouteLabel
}
```

# 9.8 DaySummaryBuilding

```swift
protocol DaySummaryBuilding: Sendable {
    func build(
        localDateKey: String,
        sanitizedLocations: SanitizedLocations,
        movements: [MovementSegmentData],
        stays: [StaySegmentData],
        mediaCount: Int,
        sourceRawRevision: Int,
        generatedAt: Date
    ) -> DayAggregateData
}
```

# 9.9 OverrideMatching

## 目的

stableIDが変わった場合の近似再紐づけを抽象化する。

```swift
protocol OverrideMatching: Sendable {
    func matchClassificationOverride(
        _ override: ClassificationOverrideData,
        to segments: [MovementSegmentData]
    ) -> MovementSegmentData?

    func matchStayOverride(
        _ override: StayOverrideData,
        to stays: [StaySegmentData]
    ) -> StaySegmentData?
}
```

具体的な時間差、座標差、誤適用防止ルールは`processing-rules.md`で定義する。

# 9.10 DayProcessing

```swift
protocol DayProcessing: Sendable {
    func process(
        localDateKey: String,
        rawEvents: RawDayEvents,
        mediaCount: Int,
        rawRevision: Int
    ) async throws -> DayProcessingResult
}
```

## 責務

- Processing Protocolsを定められた順で実行する
- Overrideを適用する
- 結果を返す

## 行わない処理

- SwiftDataへ直接保存
- BGTask予約
- UI更新

## 10. Application UseCases

UseCaseは画面またはAppLifecycleCoordinatorが実行する操作単位とする。

# 10.1 LoadCalendarMonthUseCase

```swift
protocol LoadCalendarMonthUseCase: Sendable {
    func execute(
        month: LocalMonth
    ) async throws -> CalendarMonthData
}
```

## 責務

- 指定月のDayAggregateを取得する
- `hasValidMovement == true`の日だけ移動情報を返す
- 生ログを取得しない
- 未処理日の処理予約が必要ならCoordinatorへ依頼する

# 10.2 LoadDayDetailUseCase

```swift
protocol LoadDayDetailUseCase: Sendable {
    func execute(
        localDateKey: String
    ) async throws -> DayDetailData
}
```

## 責務

- DayAggregate取得
- MovementSegment取得
- StaySegment取得
- Override適用済み表示値生成
- Media Cache取得
- 必要なら対象日処理を優先実行
- MapScene生成用データを返す

## 行わない処理

- UIImageの直接取得
- MKMapView操作
- 共有シート表示

# 10.3 ProcessDayUseCase

```swift
protocol ProcessDayUseCase: Sendable {
    func execute(
        localDateKey: String
    ) async throws -> DayProcessingResult
}
```

## 責務

1. 処理状態を確認
2. 生ログ取得
3. Override取得
4. メディア件数取得
5. DayProcessing実行
6. 派生データ置換
7. processedRevision更新

## 要件

- 同じ日を同時に二重処理しない
- 中断時に派生データを確定しない
- rawRevisionが処理中に変化した場合は再処理対象として残す

# 10.4 UpdateClassificationUseCase

```swift
protocol UpdateClassificationUseCase: Sendable {
    func execute(
        segment: MovementSegmentData,
        classification: UserMovementClassification
    ) async throws
}
```

## 責務

- Override Dataを生成する
- overrideKeyでUpsertする
- 自動分類データを変更しない
- UIへ更新結果を返す

# 10.5 UpdateStayOverrideUseCase

```swift
protocol UpdateStayOverrideUseCase: Sendable {
    func execute(
        stay: StaySegmentData,
        action: StayOverrideAction
    ) async throws
}
```

## 責務

- confirm、hide、automaticを保存する
- StaySegmentの自動判定結果を直接書き換えない
- 表示上はOverrideを優先する

# 10.6 DeleteDayLogUseCase

```swift
protocol DeleteDayLogUseCase: Sendable {
    func execute(
        localDateKey: String
    ) async throws
}
```

## 責務

- DayDeletionRepositoryを呼ぶ
- 日付に関連する全データを完全削除する
- 写真・動画を削除しない
- 成功後にUI再取得が必要なことを通知する
- 失敗時は部分削除状態を残さない

確認ダイアログ自体はPresentation層で表示する。

# 10.7 RefreshMediaCacheUseCase

```swift
protocol RefreshMediaCacheUseCase: Sendable {
    func execute(
        localDateKey: String
    ) async throws -> [MediaAssetReference]
}
```

## 責務

1. 現地日付キーからPhotoKit検索範囲を生成
2. PhotoLibraryProvidingから資産取得
3. MediaEligibilityPolicyを適用
4. MediaCacheRepositoryを日付単位で置換
5. DayAggregateのmediaCountCacheを更新
6. 削除済み資産をキャッシュから除外

# 10.8 LoadMediaThumbnailUseCase

```swift
@MainActor
protocol LoadMediaThumbnailUseCase: AnyObject {
    func execute(
        localIdentifier: String,
        targetSize: CGSize
    ) async throws -> UIImage
}
```

## 方針

- FeatureがPhotoKitを直接呼ばないための薄いUseCase
- メモリキャッシュを内部で利用してよい
- 永続キャッシュは作らない

# 10.9 LoadMediaPreviewUseCase

```swift
@MainActor
protocol LoadMediaPreviewUseCase: AnyObject {
    func loadPhoto(
        localIdentifier: String
    ) async throws -> UIImage

    func loadVideo(
        localIdentifier: String
    ) async throws -> AVAsset
}
```

# 10.10 ShareMediaUseCase

```swift
@MainActor
protocol ShareMediaUseCase: AnyObject {
    func execute(
        localIdentifier: String
    ) async throws
}
```

## 責務

1. PhotoLibraryProvidingから共有用実体取得
2. 必要なら一時ファイル生成
3. SharePresentingで共有シート表示
4. 完了またはキャンセル後に一時ファイル削除

# 10.11 StartMonitoringUseCase

```swift
protocol StartMonitoringUseCase: Sendable {
    func execute() async
}
```

## 責務

- 権限状態確認
- SLC監視開始
- 利用可能ならMotion監視開始
- 利用可能ならVisit監視開始
- 個別サービス失敗で全体を停止しない

# 10.12 StopMonitoringUseCase

```swift
protocol StopMonitoringUseCase: Sendable {
    func execute() async
}
```

通常のアプリバックグラウンド移行ではSLCを停止しない。

明示的停止が必要なデバッグや将来設定向けのインターフェースとして定義する。

## 11. Coordinator Interfaces

# 11.1 DayProcessingCoordinating

```swift
protocol DayProcessingCoordinating: Sendable {
    func processIfNeeded(
        localDateKey: String,
        priority: ProcessingPriority
    ) async

    func processPendingDays(
        limit: Int
    ) async

    func cancelCurrentProcessing() async
}
```

```swift
enum ProcessingPriority: Int, Sendable {
    case background = 0
    case normal = 1
    case userVisible = 2
}
```

## 責務

- 同じ日の重複処理防止
- ユーザー表示日の優先
- BGTask終了要求時のキャンセル
- 処理失敗日の再試行管理

# 11.2 AppLifecycleCoordinating

```swift
@MainActor
protocol AppLifecycleCoordinating: AnyObject {
    func handleLaunch() async
    func handleForeground() async
    func handleBackground() async
}
```

## 責務

- 権限更新
- 監視開始状態確認
- 未処理日確認
- メディア変更反映
- BGTask予約

## 12. Media Eligibility Interface

```swift
protocol MediaEligibilityEvaluating: Sendable {
    func evaluate(
        _ asset: MediaAssetReference
    ) -> MediaEligibility
}
```

```swift
enum MediaEligibility: String, Sendable {
    case eligible
    case ineligible
}
```

## 判定

- スクリーンショット：ineligible
- 画面収録：ineligible
- その他：原則eligible
- AIや画像解析は行わない

## 13. Media Placement Interface

```swift
protocol MediaPlacementCalculating: Sendable {
    func place(
        assets: [MediaAssetReference],
        movements: [MovementSegmentData]
    ) -> [MediaPlacement]
}
```

## 方針

- 位置情報付き資産だけ返す
- 位置情報なし資産は地図へ配置しない
- 関連区間IDは経路から一定距離以内の場合だけ設定する

## 14. Presentation向けデータ

FeatureへSwiftData Modelを直接渡さない。

UseCaseは表示用の値を返す。

### CalendarMonthData

```swift
struct CalendarMonthData: Sendable {
    let month: LocalMonth
    let days: [CalendarDayData]
}
```

### DayDetailData

```swift
struct DayDetailData: Sendable {
    let aggregate: DayAggregateData
    let movements: [MovementDisplayData]
    let stays: [StayDisplayData]
    let media: [MediaAssetReference]
    let mapScene: MapScene
    let isReprocessing: Bool
}
```

### MovementDisplayData

自動分類とユーザー分類を両方保持し、表示時はユーザー分類を優先する。

### StayDisplayData

自動表示状態とユーザーOverride後の表示状態を両方保持する。

## 15. AppContainer公開依存

`AppContainer`は次を生成し、Initializer Injectionで渡す。

```text
Platform
- LocationProviding
- MotionProviding
- VisitProviding
- PhotoLibraryProviding
- PermissionManaging
- BackgroundTaskScheduling
- SharePresenting
- Logging

Supporting
- Clock
- TimeZoneProviding
- LocalTimeContextProviding
- StableIDGenerating
- RouteEncoding
- MapSceneBuilding

Repositories
- RawEventRepository
- ProcessingStateRepository
- DerivedDataRepository
- OverrideRepository
- MediaCacheRepository
- DayDeletionRepository

Processing
- LocationSanitizing
- LocalDayBoundarySplitting
- MovementSegmenting
- StayDetecting
- MovementClassifying
- RouteSimplifying
- RouteLabelPlacing
- DaySummaryBuilding
- OverrideMatching
- DayProcessing

UseCases
- LoadCalendarMonthUseCase
- LoadDayDetailUseCase
- ProcessDayUseCase
- UpdateClassificationUseCase
- UpdateStayOverrideUseCase
- DeleteDayLogUseCase
- RefreshMediaCacheUseCase
- LoadMediaThumbnailUseCase
- LoadMediaPreviewUseCase
- ShareMediaUseCase
- StartMonitoringUseCase

Coordinators
- DayProcessingCoordinating
- AppLifecycleCoordinating
```

ViewへAppContainer全体を渡さない。

各Featureには必要なUseCaseだけを渡す。

例：

```text
CalendarViewModel
- LoadCalendarMonthUseCase

DayDetailViewModel
- LoadDayDetailUseCase
- UpdateClassificationUseCase
- UpdateStayOverrideUseCase
- DeleteDayLogUseCase
- LoadMediaThumbnailUseCase

MediaPreviewViewModel
- LoadMediaPreviewUseCase
- ShareMediaUseCase
```

## 16. 実装上の禁止事項

- 巨大な`DayLogRepository`へ全処理を集約しない
- Repository内部でUI状態を管理しない
- UseCase内部でSwiftUI Viewを生成しない
- FeatureからPersistenceActorを直接取得しない
- FeatureからPHAsset、CLLocation、CMMotionActivityを直接扱わない
- ViewModelへ距離計算や滞在判定を実装しない
- Platform Serviceから直接SwiftDataへ保存しない
- Loggerへ自由文字列で座標を渡さない
- Protocolへ実装都合だけのメソッドを追加しない
- 1つのUseCaseから無関係な機能を変更しない

## 17. Test Double方針

各ProtocolにはFakeまたはSpyを用意する。

### Fake

決めた値やイベントを返す。

用途：

- 位置イベントの再現
- PhotoKit資産の再現
- 時刻・タイムゾーン固定
- Repositoryのメモリ実装

### Spy

呼び出し回数や引数を記録する。

用途：

- 削除が1回だけ実行されたか
- BGTaskが予約されたか
- 権限要求順序が正しいか
- Loggingイベントが発生したか

### Stub

単純な固定結果だけを返す。

用途：

- MapSceneBuilderの固定結果
- RouteEncoderの固定Data
- PermissionStateの固定結果

テスト用実装は本番ターゲットへ含めず、Test TargetまたはTestSupportへ配置する。

## 18. MVP完了条件

- Platform APIがProtocolの背後に隠れている
- Repositoryが用途別に分割されている
- ViewModelがRepositoryを直接呼んでいない
- 各画面操作がUseCaseとして定義されている
- 監視系イベントをAsyncStreamで受け取れる
- 共通エラーがDriveLogErrorへ変換される
- ClockとTimeZoneをテストで差し替えられる
- MapScene生成がViewModelから分離されている
- 写真・動画取得がPhotoLibraryProvidingへ集約されている
- 日付削除がDayDeletionRepository経由で一括実行される
- 各主要ProtocolへFakeまたはSpyを作成できる
- AppContainerから各Featureへ必要なUseCaseだけを注入できる

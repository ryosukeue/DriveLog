# Data Model

## 実機フィードバック変更のMigration方針（2026-07-15）

Issue 14の変更ではV1 Schemaを変更しない。`ClassificationOverrideModel`と集計詳細PropertyはProduction UIから未使用になっても、既存Store互換と将来利用のため保持する。Raw LocationとPhotos Assetは自動削除しない。

## 1. 目的

この文書は、DriveLogのMVPで使用するSwiftDataモデル、永続化対象、識別子、重複判定、リレーション、削除ルール、キャッシュ方針、スキーマ移行方針を定義する。

実装時にモデル構造を独自判断で変更しない。変更が必要な場合は、先にこの文書と関連文書を更新する。

## 2. 対象

- iOS 17以降
- SwiftData
- オンデバイス保存
- iCloud同期なし
- 外部サーバーなし
- 生ログは当面期限なしで保存
- ユーザー操作による日付単位の完全削除あり
- 写真・動画本体は保存せず、PhotoKitの参照と最低限のメタデータだけをキャッシュする

## 3. 共通データ規約

### 3.1 日時

- `Date`は絶対時刻として保存する
- 表示や日付グループ化には、イベント取得時に保存した現地タイムゾーン情報を使用する
- 現在の端末タイムゾーンへ変更して再計算しない

各生イベントには次を保存する。

```swift
let timeZoneIdentifier: String
let utcOffsetSeconds: Int
let localDateKey: String
```

### 3.2 現地日付キー

`localDateKey`は次の形式とする。

```text
YYYY-MM-DD
```

例：

```text
2026-07-13
```

生成時は記録時の現地カレンダーとタイムゾーンを使用する。

保存後は不変とする。

### 3.3 単位

- 距離：メートル
- 時間：秒
- 速度：メートル毎秒
- 緯度・経度：度
- UTCオフセット：秒
- 水平精度：メートル

UI表示時にkm、分、時間、km/hへ変換する。

### 3.4 ID

通常の生イベントには`UUID`を使用する。

再集計後もユーザー修正との対応を維持する必要がある派生区間には、決定論的な安定IDを使用する。

### 3.5 Enumの保存

SwiftDataにはEnumそのものを直接依存させず、原則として`String`または`Int`のRaw Valueを保存する。

未知の値を読み込んだ場合は、`unknown`または安全な既定値へフォールバックする。

### 3.6 任意値

Core Locationなどが無効値を返した場合は、無理に数値を保存せず`nil`へ変換する。

例：

- `speed < 0`は`nil`
- 到着・出発時刻が未確定なら`nil`

## 4. SwiftData Schema Versioning

初期版からVersionedSchemaを使用する。

```swift
enum DriveLogSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            LocationEventModel.self,
            MotionEventModel.self,
            VisitEventModel.self,
            DayProcessingStateModel.self,
            DayAggregateModel.self,
            MovementSegmentModel.self,
            StaySegmentModel.self,
            ClassificationOverrideModel.self,
            StayOverrideModel.self,
            MediaAssetCacheModel.self
        ]
    }
}
```

初期Migration Planも用意する。

V1では実質的な移行処理がなくても、今後の変更に備えてSchemaとMigration Planを最初から分離する。

### 移行ルール

- 追加フィールドには安全な既定値またはOptionalを設定する
- モデル名やフィールド名を変更する場合は明示的な移行を用意する
- 生ログを破棄する破壊的移行は行わない
- 派生データは必要に応じて削除し、生ログから再生成してよい
- メディアキャッシュは移行不能な場合に削除・再生成してよい

## 5. 永続モデル一覧

| モデル | 種別 | 再生成 | 主な役割 |
|---|---|---:|---|
| `LocationEventModel` | 生データ | 不可 | SLCで取得した位置 |
| `MotionEventModel` | 生データ | 不可 | Core Motionの状態 |
| `VisitEventModel` | 生データ | 不可 | CLVisitの到着・出発 |
| `DayProcessingStateModel` | 処理管理 | 可 | 日別処理の世代・状態 |
| `DayAggregateModel` | 派生データ | 可 | カレンダー・日別サマリー |
| `MovementSegmentModel` | 派生データ | 可 | 移動区間 |
| `StaySegmentModel` | 派生データ | 可 | 滞在区間 |
| `ClassificationOverrideModel` | ユーザーデータ | 不可 | 区間分類の修正 |
| `StayOverrideModel` | ユーザーデータ | 不可 | 滞在判定の修正 |
| `MediaAssetCacheModel` | キャッシュ | 可 | PhotoKit資産の参照情報 |

## 6. LocationEventModel

### 目的

Significant Location Changeで取得した位置情報を、生ログとして保存する。

### フィールド

| フィールド | 型 | 必須 | 説明 |
|---|---|---:|---|
| `id` | `UUID` | 必須 | イベントID |
| `latitude` | `Double` | 必須 | 緯度 |
| `longitude` | `Double` | 必須 | 経度 |
| `timestamp` | `Date` | 必須 | Core Locationの取得時刻 |
| `horizontalAccuracy` | `Double` | 必須 | 水平精度 |
| `speedMetersPerSecond` | `Double?` | 任意 | 有効な場合だけ保存 |
| `createdAt` | `Date` | 必須 | アプリが保存した時刻 |
| `timeZoneIdentifier` | `String` | 必須 | 記録時のタイムゾーンID |
| `utcOffsetSeconds` | `Int` | 必須 | 記録時のUTCオフセット |
| `localDateKey` | `String` | 必須 | 記録時の現地日付 |
| `deduplicationKey` | `String` | 必須 | 重複候補検索用キー |

### バリデーション

- 緯度は`-90...90`
- 経度は`-180...180`
- `horizontalAccuracy >= 0`
- `speedMetersPerSecond < 0`は`nil`
- タイムスタンプが大幅に未来の場合は保存しない

### 重複判定

次の両方を満たす既存イベントがある場合、重複として保存しない。

- 時刻差が30秒以内
- 位置差が10m以内

`deduplicationKey`は検索対象を絞るための補助値とし、最終判定は時刻差と実距離で行う。

キー生成例：

```text
30秒単位のtimestamp bucket
+
丸めた緯度
+
丸めた経度
```

近似キーだけで重複を確定しない。

### 一意性

- `id`は一意
- `deduplicationKey`単体は一意制約にしない

## 7. MotionEventModel

### 目的

Core Motionの判定結果を、元フラグを保持したまま保存する。

### フィールド

| フィールド | 型 | 必須 |
|---|---|---:|
| `id` | `UUID` | 必須 |
| `startDate` | `Date` | 必須 |
| `endDate` | `Date?` | 任意 |
| `isAutomotive` | `Bool` | 必須 |
| `isWalking` | `Bool` | 必須 |
| `isRunning` | `Bool` | 必須 |
| `isCycling` | `Bool` | 必須 |
| `isStationary` | `Bool` | 必須 |
| `isUnknown` | `Bool` | 必須 |
| `confidenceRawValue` | `Int` | 必須 |
| `createdAt` | `Date` | 必須 |
| `timeZoneIdentifier` | `String` | 必須 |
| `utcOffsetSeconds` | `Int` | 必須 |
| `localDateKey` | `String` | 必須 |

### 方針

- 主分類1つだけに変換せず、Core Motionの元フラグを保存する
- 複数フラグが同時に`true`でも許容する
- confidenceが低くても生ログとして保存する
- 自動分類は日別処理で行う

## 8. VisitEventModel

### 目的

CLVisitの到着・出発・位置を保存する。

### フィールド

| フィールド | 型 | 必須 |
|---|---|---:|
| `id` | `UUID` | 必須 |
| `latitude` | `Double` | 必須 |
| `longitude` | `Double` | 必須 |
| `arrivalDate` | `Date?` | 任意 |
| `departureDate` | `Date?` | 任意 |
| `horizontalAccuracy` | `Double` | 必須 |
| `createdAt` | `Date` | 必須 |
| `updatedAt` | `Date` | 必須 |
| `timeZoneIdentifier` | `String` | 必須 |
| `utcOffsetSeconds` | `Int` | 必須 |
| `localDateKey` | `String` | 必須 |
| `visitMatchKey` | `String` | 必須 |

### 同一Visitの判定

到着だけ判明したVisitへ、後から出発時刻を反映するため、次を用いて同一候補を探す。

- 到着時刻
- 近似座標
- 水平精度
- 現地日付キー

`visitMatchKey`は、到着時刻の時間バケットと近似座標から生成する。

最終的な同一判定は、到着時刻差と座標距離で行う。

同一Visitと判定した場合は、新規作成せず既存モデルを更新する。

## 9. DayProcessingStateModel

### 目的

日別集計の世代、成功状態、中断状態を管理する。

### フィールド

| フィールド | 型 | 必須 |
|---|---|---:|
| `id` | `UUID` | 必須 |
| `localDateKey` | `String` | 必須 |
| `rawRevision` | `Int` | 必須 |
| `processedRevision` | `Int` | 必須 |
| `statusRawValue` | `String` | 必須 |
| `lastAttemptDate` | `Date?` | 任意 |
| `lastSuccessfulDate` | `Date?` | 任意 |
| `lastErrorCode` | `String?` | 任意 |
| `updatedAt` | `Date` | 必須 |

### 一意性

`localDateKey`を一意とする。

### 状態

```swift
enum ProcessingStatus: String {
    case pending
    case processing
    case completed
    case failed
}
```

### 判定

```text
rawRevision == processedRevision
→ 最新の生ログに対して処理済み

rawRevision > processedRevision
→ 未処理または再処理が必要
```

新しいLocation、Motion、Visitイベントが追加・更新された場合、該当日の`rawRevision`を増加させる。

## 10. DayAggregateModel

### 目的

月間カレンダーと日別詳細の基本サマリーを高速に表示する。

### フィールド

| フィールド | 型 | 必須 |
|---|---|---:|
| `id` | `UUID` | 必須 |
| `localDateKey` | `String` | 必須 |
| `totalDistanceMeters` | `Double` | 必須 |
| `totalMovementDurationSeconds` | `Double` | 必須 |
| `startDate` | `Date?` | 任意 |
| `endDate` | `Date?` | 任意 |
| `locationRecordCount` | `Int` | 必須 |
| `rejectedLocationCount` | `Int` | 必須 |
| `mediaCountCache` | `Int` | 必須 |
| `automaticClassificationRawValue` | `String` | 必須 |
| `hasValidMovement` | `Bool` | 必須 |
| `movementSegmentCount` | `Int` | 必須 |
| `staySegmentCount` | `Int` | 必須 |
| `totalStayDurationSeconds` | `Double` | 必須 |
| `automotiveDurationSeconds` | `Double` | 必須 |
| `walkingDurationSeconds` | `Double` | 必須 |
| `sourceRawRevision` | `Int` | 必須 |
| `generatedAt` | `Date` | 必須 |

### 保存しない値

- 日全体の平均速度
- 最高速度
- 写真・動画本体
- 地図表示用アノテーション

### 一意性

`localDateKey`を一意とする。

### メディア件数

`mediaCountCache`はキャッシュであり、PhotoKitライブラリ変更時に更新可能とする。

正しい値を再取得できない場合でも、位置ログや日別集計を壊さない。

## 11. MovementSegmentModel

### 目的

日付内の移動区間と、地図表示用ポリラインを保存する。

### フィールド

| フィールド | 型 | 必須 |
|---|---|---:|
| `id` | `UUID` | 必須 |
| `stableID` | `String` | 必須 |
| `localDateKey` | `String` | 必須 |
| `startDate` | `Date` | 必須 |
| `endDate` | `Date` | 必須 |
| `distanceMeters` | `Double` | 必須 |
| `durationSeconds` | `Double` | 必須 |
| `estimatedAverageSpeedMetersPerSecond` | `Double?` | 任意 |
| `automaticClassificationRawValue` | `String` | 必須 |
| `classificationConfidenceRawValue` | `String` | 必須 |
| `encodedRouteData` | `Data` | 必須 |
| `labelLatitude` | `Double?` | 任意 |
| `labelLongitude` | `Double?` | 任意 |
| `sourceRawRevision` | `Int` | 必須 |
| `generatedAt` | `Date` | 必須 |

### 安定ID

再集計後も同じ区間を識別しやすくするため、`stableID`を決定論的に生成する。

基本シード：

```text
localDateKey
+
開始時刻を分単位へ丸めた値
+
終了時刻を分単位へ丸めた値
```

シードをCryptoKitのSHA-256でハッシュし、16進文字列として保存する。

例：

```text
2026-07-13|1783910400|1783912200
↓
SHA-256
```

時刻の変動によってstableIDが変わる可能性はあるため、ユーザー修正側にも時間帯を保存する。

### 一意性

`stableID`を一意とする。

### 経路データ

`encodedRouteData`には表示用座標列を保存する。

V1の形式：

```swift
struct EncodedRoutePayloadV1: Codable {
    let formatVersion: Int
    let coordinates: [EncodedCoordinate]
}

struct EncodedCoordinate: Codable {
    let latitude: Double
    let longitude: Double
}
```

エンコードには`PropertyListEncoder`のバイナリ形式を使用する。

`formatVersion`は`1`から開始する。

元のLocationEvent ID一覧は保存しない。

## 12. StaySegmentModel

### 目的

推定滞在地点と滞在時間を保存する。

### フィールド

| フィールド | 型 | 必須 |
|---|---|---:|
| `id` | `UUID` | 必須 |
| `stableID` | `String` | 必須 |
| `localDateKey` | `String` | 必須 |
| `representativeLatitude` | `Double` | 必須 |
| `representativeLongitude` | `Double` | 必須 |
| `estimatedArrivalDate` | `Date` | 必須 |
| `estimatedDepartureDate` | `Date` | 必須 |
| `durationSeconds` | `Double` | 必須 |
| `confidenceRawValue` | `String` | 必須 |
| `sourceRawValue` | `String` | 必須 |
| `isVisibleByAutomaticRule` | `Bool` | 必須 |
| `sourceRawRevision` | `Int` | 必須 |
| `generatedAt` | `Date` | 必須 |

### 安定ID

基本シード：

```text
localDateKey
+
到着時刻を分単位へ丸めた値
+
出発時刻を分単位へ丸めた値
+
代表緯度を小数第4位へ丸めた値
+
代表経度を小数第4位へ丸めた値
```

シードをSHA-256でハッシュし、16進文字列として保存する。

### 一意性

`stableID`を一意とする。

## 13. ClassificationOverrideModel

### 目的

ユーザーが移動区間ごとに修正した分類を、自動分類とは分離して保存する。

### フィールド

| フィールド | 型 | 必須 |
|---|---|---:|
| `id` | `UUID` | 必須 |
| `overrideKey` | `String` | 必須 |
| `targetStableID` | `String` | 必須 |
| `localDateKey` | `String` | 必須 |
| `originalStartDate` | `Date` | 必須 |
| `originalEndDate` | `Date` | 必須 |
| `userClassificationRawValue` | `String` | 必須 |
| `createdAt` | `Date` | 必須 |
| `updatedAt` | `Date` | 必須 |

### overrideKey

```text
localDateKey|targetStableID
```

`overrideKey`を一意とし、同じ区間に複数の有効Overrideを作らない。

### 再集計後の再紐づけ

1. `targetStableID`の完全一致を優先する
2. 一致しない場合は、同じ`localDateKey`内で`originalStartDate`と`originalEndDate`に近い区間を探す
3. 一定以上近い場合だけ再適用する
4. 誤適用の可能性がある場合は自動適用しない

具体的な近似閾値は`processing-rules.md`で定義する。

## 14. StayOverrideModel

### 目的

ユーザーによる滞在地点の確定、非表示、自動判定復帰を保存する。

### フィールド

| フィールド | 型 | 必須 |
|---|---|---:|
| `id` | `UUID` | 必須 |
| `overrideKey` | `String` | 必須 |
| `targetStableID` | `String` | 必須 |
| `localDateKey` | `String` | 必須 |
| `originalArrivalDate` | `Date` | 必須 |
| `originalDepartureDate` | `Date` | 必須 |
| `originalLatitude` | `Double` | 必須 |
| `originalLongitude` | `Double` | 必須 |
| `actionRawValue` | `String` | 必須 |
| `createdAt` | `Date` | 必須 |
| `updatedAt` | `Date` | 必須 |

### action

```swift
enum StayOverrideAction: String {
    case confirm
    case hide
    case automatic
}
```

### overrideKey

```text
localDateKey|targetStableID
```

`overrideKey`を一意とする。

### 再集計後の再紐づけ

1. stableIDの完全一致
2. 同じ日付内の到着・出発時刻の近さ
3. 代表座標の近さ

具体的な近似閾値は`processing-rules.md`で定義する。

## 15. MediaAssetCacheModel

### 目的

PhotoKit資産の最低限の参照情報を保存し、日別グリッドと地図表示を高速化する。

写真・動画本体、サムネイル、プレビュー画像は永続保存しない。

### フィールド

| フィールド | 型 | 必須 |
|---|---|---:|
| `id` | `UUID` | 必須 |
| `localIdentifier` | `String` | 必須 |
| `localDateKey` | `String` | 必須 |
| `mediaTypeRawValue` | `String` | 必須 |
| `creationDate` | `Date?` | 任意 |
| `latitude` | `Double?` | 任意 |
| `longitude` | `Double?` | 任意 |
| `durationSeconds` | `Double?` | 任意 |
| `isScreenshot` | `Bool` | 必須 |
| `isScreenRecording` | `Bool` | 必須 |
| `eligibilityRawValue` | `String` | 必須 |
| `lastValidatedAt` | `Date` | 必須 |

### 一意性

`localIdentifier`を一意とする。

### キャッシュ方針

- PhotoKit側の資産が存在しなくなった場合は削除する
- 限定アクセスから外れた場合も削除または利用不可として再検証する
- スクリーンショットと画面収録はキャッシュ可能だが、表示対象外とする
- 位置情報がないメディアも日別グリッド用にキャッシュする
- 位置情報がないメディアは地図へ配置しない
- サムネイルはメモリキャッシュのみとする

### MediaPlacement

`MediaPlacement`はV1では永続モデルにしない。

位置情報付きメディアと移動区間の対応は、地図表示時または日別画面生成時に計算する。

## 16. リレーション

### DayAggregateと派生区間

`DayAggregateModel`から次のTo-Many Relationshipを持たせてよい。

- `movementSegments`
- `staySegments`

削除ルールはCascadeとする。

ただし、日付削除ではRelationshipだけに依存せず、`localDateKey`でも対象を検索して削除する。

処理失敗などによりDayAggregateが存在しない場合でも、孤立した派生データを削除できるようにする。

### 生ログ

Location、Motion、VisitはDayAggregateとの直接Relationshipを持たない。

`localDateKey`で取得する。

### Override

OverrideはMovementSegmentやStaySegmentへのSwiftData Relationshipを必須としない。

`targetStableID`と近似用情報で紐づける。

派生区間の再生成によってRelationshipが切れる問題を避ける。

### Media Cache

MediaAssetCacheはDayAggregateとの直接Relationshipを持たず、`localDateKey`で取得する。

## 17. 一意キーと検索キー

| モデル | 一意キー | 主な検索キー |
|---|---|---|
| LocationEvent | `id` | `localDateKey`, `timestamp`, `deduplicationKey` |
| MotionEvent | `id` | `localDateKey`, `startDate` |
| VisitEvent | `id` | `localDateKey`, `visitMatchKey` |
| DayProcessingState | `localDateKey` | `statusRawValue`, revision |
| DayAggregate | `localDateKey` | 月範囲、`hasValidMovement` |
| MovementSegment | `stableID` | `localDateKey`, `startDate` |
| StaySegment | `stableID` | `localDateKey`, arrival |
| ClassificationOverride | `overrideKey` | `localDateKey`, `targetStableID` |
| StayOverride | `overrideKey` | `localDateKey`, `targetStableID` |
| MediaAssetCache | `localIdentifier` | `localDateKey`, `creationDate` |

iOS 17で利用可能なSwiftData APIの範囲で実装し、特定OSバージョンでしか使えないIndex APIへ依存しない。

必要な高速化は、検索キーを単純な保存型として持つことと、クエリ範囲を日付単位に絞ることで行う。

## 18. 主なクエリ

### 月間カレンダー

```text
指定月のlocalDateKey範囲
AND
hasValidMovement == true
```

返却対象：

- localDateKey
- totalDistanceMeters

### 日別詳細

```text
localDateKey == 対象日
```

取得対象：

- DayAggregate
- MovementSegment
- StaySegment
- Override
- MediaAssetCache

### 未処理日

```text
rawRevision > processedRevision
OR
status == failed
OR
status == pending
```

### 日別メディア

```text
localDateKey == 対象日
AND
eligibility == eligible
```

地図表示ではさらに座標が存在するものだけを使用する。

## 19. 日付単位の完全削除

`deleteDay(localDateKey:)`で次を削除する。

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

### 削除しないもの

- Apple Photosライブラリ内の写真・動画
- 他の日付に属するデータ
- アプリ全体の設定や権限状態

### 削除手順

1. 対象日を確認する
2. ユーザーへ確認ダイアログを表示する
3. 1つのPersistenceActor操作内で全対象を削除する
4. ModelContextを1回保存する
5. 保存に成功した場合だけUIへ成功を通知する
6. カレンダーと日別画面のキャッシュを更新する

ゴミ箱、論理削除、復元機能は実装しない。

`isDeleted`フラグは持たない。

## 20. PhotoKit側の変更同期

PhotoKitのライブラリ変更通知または画面再表示時の再検証で、キャッシュを更新する。

### 資産が削除された場合

- 対応する`MediaAssetCacheModel`を削除する
- `DayAggregate.mediaCountCache`を再計算する
- 地図アノテーションとグリッドから除外する

### 資産が追加された場合

- 対象日を検索する
- MediaEligibilityPolicyを適用する
- MediaAssetCacheModelを追加する
- 日別メディア件数を更新する

### 位置情報や日時が編集された場合

- キャッシュを更新する
- 必要に応じて旧日付キャッシュを削除し、新日付へ作成する
- 地図配置を再計算する

## 21. 永続化しないデータ

V1では次をSwiftDataへ保存しない。

- 写真・動画本体
- サムネイル画像
- 動画プレビュー
- `MKMapView`の状態
- 現在の地図ズーム
- MapScene
- MediaPlacement
- MovementSegmentが使用したLocationEvent ID一覧
- 一時共有ファイル
- 日全体の平均速度
- 最高速度

## 22. データ整合性ルール

- `endDate >= startDate`
- `estimatedDepartureDate >= estimatedArrivalDate`
- 距離と時間は0以上
- `durationSeconds`は時刻差と大きく矛盾しない
- `localDateKey`は`YYYY-MM-DD`
- 派生モデルの`sourceRawRevision`は生成元の日付状態と一致する
- `processedRevision`は`rawRevision`を超えない
- `hasValidMovement == false`の場合、カレンダー遷移対象にしない
- stableIDは生成後に変更しない
- Overrideはユーザー操作以外で削除しない。ただし日付完全削除時を除く
- キャッシュ破損は生ログやユーザー修正へ影響させない

## 23. 再集計時の更新方針

日別処理が成功した場合、対象日の派生データを置き換える。

### 置換対象

- DayAggregate
- MovementSegment
- StaySegment

### 維持対象

- LocationEvent
- MotionEvent
- VisitEvent
- ClassificationOverride
- StayOverride
- MediaAssetCache

置換後にOverrideをstableIDまたは近似情報で再適用する。

派生データ置換と`processedRevision`更新は、同じPersistenceActor処理内で確定する。

## 24. 初期値

| 項目 | 初期値 |
|---|---:|
| `rawRevision` | 0 |
| `processedRevision` | 0 |
| `ProcessingStatus` | `pending` |
| `mediaCountCache` | 0 |
| `hasValidMovement` | `false` |
| 各時間集計 | 0 |
| 各件数 | 0 |
| 自動分類 | `other`または`unknown` |
| `isVisibleByAutomaticRule` | 判定結果に従う |
| Route payload version | 1 |

## 25. MVP完了条件

- 全モデルをDriveLogSchemaV1へ登録できる
- SwiftDataコンテナを起動できる
- Location、Motion、Visitを保存・取得できる
- 記録時の現地日付キーを保存できる
- 日別集計結果を保存・置換できる
- ポリラインをDataとしてエンコード・デコードできる
- MovementSegmentとStaySegmentへ安定IDを生成できる
- OverrideをstableIDと近似情報で保持できる
- PhotoKit参照キャッシュを保存・削除できる
- PhotoKit側で削除された資産のキャッシュを削除できる
- 指定日の全関連データを完全削除できる
- Schema VersioningとMigration Planを有効にした状態で起動できる

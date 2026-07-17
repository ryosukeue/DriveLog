# Processing Rules

## 実機Polyline診断の補足（2026-07-15）

- Visit/Motion境界はStay検出と分類Evidenceに使用する。5分未満では、座標が連続するMovement routeの強制分割理由にはしない。
- 5分以上かつ前後位置が150m以内、またはCLVisitが重なる区間はStay境界としてMovement routeを分割する。
- 現地日付境界と90分以上の観測欠損もhard splitとする。大きな欠損は直線接続しない。
- 30m route simplificationは維持し、各routeの始点/終点を保持する。簡略化前後の点数を診断する。
- Mediaの500m閾値は関連Movement選択にだけ使用し、位置情報付きMedia Annotation自体の表示除外には使用しない。
- 診断は件数、時間間隔bucket、精度bucket、除外/gap理由だけを扱い、座標やIdentifierを記録しない。

## 1. 目的

この文書は、DriveLogのMVPで使用する位置ログ処理、移動区間分割、滞在判定、移動分類、日別有効判定、Override再紐づけ、メディア判定、経路簡略化、ラベル配置の初期ルールを定義する。

すべての閾値は、画面、Repository、SwiftData Modelへ直接埋め込まず、`ProcessingConfiguration`へ集約する。

実機ログを確認して閾値を変更する場合は、先にこの文書を更新する。

## 2. 基本方針

- Significant Location Changeの位置点は粗い前提で扱う
- 高精度GPSの軌跡と同等の精度を期待しない
- 完全な経路再現より、長期間安定して記録できることを優先する
- 誤検出を増やして細かく分類するより、不明またはその他として残す
- 生ログは変更せず、除外・分類結果は派生データとして扱う
- 同じ入力と同じ設定からは、同じ結果を生成する
- ユーザー修正を自動判定より優先する
- 位置、速度、滞在時間、移動分類は推定値として扱う

## 3. ProcessingConfiguration

MVP初期値は次の構造へまとめる。

```swift
struct ProcessingConfiguration: Sendable, Equatable {
    let location: LocationRules
    let segmentation: SegmentationRules
    let stay: StayRules
    let classification: ClassificationRules
    let dayValidation: DayValidationRules
    let overrideMatching: OverrideMatchingRules
    let media: MediaRules
    let route: RouteRules
}
```

初期値はコード上で1箇所だけに定義する。

設定画面からの変更はMVP対象外とする。

## 4. 全体処理順

日別処理は次の順番で実行する。

1. 生ログ取得
2. イベントの時系列並べ替え
3. 無効座標除外
4. 重複位置点除外
5. 水平精度による除外
6. 不自然な座標ジャンプ除外
7. 現地日付境界での分割
8. 移動区間候補の生成
9. 滞在候補の生成
10. 移動区間の確定
11. 移動区間ごとの距離・時間・平均速度計算
12. 自動移動分類
13. Override再紐づけ
14. ユーザー修正適用
15. 表示用経路簡略化
16. ポリラインラベル位置計算
17. 日別サマリー生成
18. 派生データ保存

後続処理は、前段階で除外された位置点を使用しない。

## 5. 位置ログの事前整形

### 5.1 並べ替え

位置イベントは`timestamp`の昇順へ並べる。

同時刻のイベントが複数ある場合は、次の優先順位で並べる。

1. 水平精度が良い
2. `createdAt`が早い
3. `id`の文字列表現

並べ替えは結果の決定性を保つために行う。

### 5.2 無効座標

次の場合は除外する。

- 緯度が`-90...90`の範囲外
- 経度が`-180...180`の範囲外
- 緯度・経度が有限値ではない
- `horizontalAccuracy < 0`
- タイムスタンプが不正
- タイムスタンプが現在時刻より24時間以上未来

除外理由を`RejectedLocationReason`として保存可能にする。

```swift
enum RejectedLocationReason: String, Sendable {
    case invalidCoordinate
    case invalidAccuracy
    case futureTimestamp
    case duplicate
    case poorAccuracy
    case implausibleJump
    case invalidSequence
}
```

## 6. 位置ログの重複判定

次の両方を満たす場合、後から受信した位置点を重複として除外する。

```text
時刻差 <= 30秒
AND
位置差 <= 10m
```

初期値：

```text
duplicateTimeInterval = 30秒
duplicateDistance = 10m
```

### 判定順序

1. `deduplicationKey`で近い候補を取得
2. 実際の時刻差を計算
3. 実際の地表距離を計算
4. 両方を満たす場合だけ重複とする

### どちらを残すか

重複候補では次の優先順位で1点を残す。

1. 水平精度が良い
2. Core Locationのtimestampが新しい
3. 保存時刻が早い

## 7. 水平精度による除外

初期値：

```text
maximumHorizontalAccuracy = 500m
```

`horizontalAccuracy > 500m`の点は、距離計算、区間分割、経路描画から除外する。

ただし生ログは削除しない。

SLCは位置点が粗いため、MVPでは500m未満へ厳しくしない。

水平精度だけで滞在や分類を断定しない。

## 8. 不自然な座標ジャンプ

隣接する有効候補点について、地表距離と時刻差から推定速度を計算する。

```text
推定速度 = 2点間距離 ÷ 時刻差
```

初期値：

```text
maximumPlausibleSpeed = 250km/h
```

推定速度が250km/hを超える場合、座標ジャンプ候補とする。

### 除外対象の選択

単純に後側を必ず除外しない。

前後3点がある場合は次を比較する。

```text
A → B → C
```

- AからBの速度
- BからCの速度
- AからCの速度

Bを除外した場合にAからCが自然になるなら、Bを除外する。

判定不能な場合は、水平精度が悪い側を除外する。

両点の精度差が小さく、どちらが誤りか判断できない場合は、後側を除外する。

### 例外

新幹線などの高速移動も考慮し、250km/h以下は速度だけで除外しない。

## 9. 現地日付境界

各イベントに保存された`localDateKey`を使用する。

現在の端末タイムゾーンで再計算しない。

異なる`localDateKey`のイベントを、同一日の移動区間へ結合しない。

日付をまたぐ区間は必ず現地日付境界で分割する。

境界時刻そのものに位置点がない場合は、前日側の最後の点と翌日側の最初の点を直接結ばない。

## 10. 移動区間の分割

### 10.1 基本分割条件

次のいずれかを満たす場合、別の移動区間候補とする。

- 位置点間の時間差が90分以上
- 現地日付キーが変わる
- CLVisitによる明確な滞在が存在する
- StayDetectorが表示対象の滞在を確定する
- モーション状態が明確に変化し、位置点の空白または停止を伴う

初期値：

```text
maximumContinuousGap = 90分
```

### 10.2 時間差90分以上

位置点間が90分以上空いている場合、前後を直接つないで距離を計算しない。

前側の区間を終了し、後側から新しい区間を開始する。

### 10.3 モーション状態変化

モーション状態が変化しただけでは、必ず区間分割しない。

次の条件を組み合わせる。

- automotiveからwalkingへ変化
- walkingからautomotiveへ変化
- 3分以上の停止候補
- CLVisit
- 位置点間の時間差

自転車、running、unknownの短時間変化だけでは分割しない。

### 10.4 最小区間条件

移動区間候補は次を満たさない場合、独立した区間として確定しない。

```text
位置点数 >= 2
AND
距離 >= 100m
```

ただし前後の区間と連結可能なら、近い側へ統合してよい。

統合できない場合は無効区間として日別総距離へ含めない。

## 11. 移動距離

各移動区間内の有効位置点を時刻順に並べ、隣接点間の地表距離を合計する。

```text
区間距離 = Σ 隣接有効点間距離
```

道路補正、Map Matching、経路検索は行わない。

SLCの点が粗いため、実走行距離より短く算出される可能性を許容する。

## 12. 移動時間

区間の移動時間は次で計算する。

```text
移動時間 = 区間終了時刻 - 区間開始時刻
```

表示対象の滞在が区間内部へ存在する場合は、滞在地点で区間を分割する。

信号待ちや非表示滞在は区間時間から除外しない。

## 13. 区間平均速度

```text
区間平均速度 = 区間距離 ÷ 区間時間
```

次のいずれかを満たす場合、平均速度は`nil`として表示しない。

```text
区間時間 < 2分
OR
位置点数 < 2
OR
区間距離 < 100m
```

初期値：

```text
minimumSpeedDisplayDuration = 2分
minimumSpeedDisplayDistance = 100m
minimumSpeedDisplayPointCount = 2
```

平均速度は移動区間ごとにだけ保存・表示する。

日全体の平均速度と最高速度は生成しない。

## 14. 滞在判定

### 14.1 基本時間ルール

#### 3分未満

原則として表示しない。

```text
duration < 3分
→ 非表示
```

#### 3分以上5分未満

次のいずれかを満たす場合だけ、滞在候補とする。

- CLVisitが存在する
- automotiveからwalkingへ変化した
- automotiveからstationaryを経てwalkingへ変化した
- ユーザーの`confirm` Overrideが存在する

```text
3分 <= duration < 5分
AND
補助証拠あり
→ 滞在候補
```

#### 5分以上

原則として滞在候補とする。

```text
duration >= 5分
→ 滞在候補
```

### 14.2 信号・渋滞候補

5分以上でも、次をすべて満たす場合は自動表示しない候補とする。

- automotiveからstationaryを経てautomotiveへ戻る
- walkingが確認されない
- CLVisitが存在しない
- 前後の移動方向が大きく変わらない
- 前後区間が連続した車両系移動として解釈できる

条件が不十分な場合は滞在候補を残す。

### 14.3 滞在半径

初期値：

```text
stayRadius = 150m
```

停止中の位置点が概ね半径150m以内に収まる場合、同一滞在地点として扱う。

SLCでは停止中の位置点が少ない場合があるため、位置点が1点しかない候補でもCLVisitまたは時間差があれば判定可能とする。

### 14.4 代表座標

次の優先順位を使用する。

1. CLVisitの座標
2. 停止中位置点の精度加重平均
3. 前区間の終了位置
4. 後区間の開始位置
5. 前区間終了位置と後区間開始位置の中間

### 14.5 推定到着・出発

CLVisitがある場合：

- 到着はCLVisit arrivalDateを優先
- 出発はCLVisit departureDateを優先

CLVisitがない場合：

- 到着は前区間の終了時刻
- 出発は後区間の開始時刻

### 14.6 ユーザーOverride

優先順位：

```text
hide
→ 非表示

confirm
→ 表示

automatic
→ 自動判定
```

ユーザーOverrideは自動判定より優先する。

## 15. 移動自動分類

MVPの自動分類は次の3種類とする。

```swift
enum AutomaticMovementType: String {
    case automotiveLike
    case walkingLike
    case other
}
```

### 15.1 モーション占有率

区間時間に対して各モーション状態が占める割合を計算する。

```text
状態占有率 = 状態が有効な時間 ÷ 区間時間
```

重複するMotionEventがある場合、同じ時間を二重加算しない。

confidenceは次の重みとして使用してよい。

```text
low = 0.5
medium = 0.75
high = 1.0
```

重み付き占有率を分類証拠として使用する。

### 15.2 車っぽい移動

次のいずれかを満たす場合、車っぽい候補とする。

#### Rule A：Core Motion優先

```text
automotive占有率 >= 50%
```

#### Rule B：Motion不足時の補助

```text
automotive証拠なし
AND
区間平均速度 >= 15km/h
AND
区間距離 >= 2km
```

ただし、電車やバスも含む可能性があるため、自動表示は「車っぽい移動」とする。

自家用車と断定しない。

### 15.3 徒歩っぽい移動

次のいずれかを満たす場合、徒歩っぽい候補とする。

#### Rule A：Core Motion優先

```text
walkingまたはrunning占有率 >= 40%
```

#### Rule B：Motion不足時の補助

```text
区間平均速度 <= 8km/h
AND
区間距離 <= 3km
```

区間距離が極端に短い場合は、徒歩っぽいと断定せず`other`としてよい。

### 15.4 その他

次の場合は`other`とする。

- cyclingが中心
- unknownが中心
- 車両系と徒歩系の証拠が拮抗する
- Motion情報が不足し、速度条件にも当てはまらない
- 区間平均速度を計算できない
- 位置点が少なすぎる
- 判定信頼度が低い

### 15.5 競合時の優先順位

車っぽい条件と徒歩っぽい条件を両方満たす場合：

1. confidenceを加味したMotion占有率が高い側
2. 明確なautomotiveがある場合は車っぽい
3. 明確なwalkingまたはrunningがある場合は徒歩っぽい
4. 判定不能なら`other`

### 15.6 自転車

MVPでは自転車専用分類を表示しない。

cyclingが中心の場合は`other`とする。

## 16. 分類信頼度

分類結果には次の信頼度を付与する。

```swift
enum ClassificationConfidence: String {
    case low
    case medium
    case high
}
```

### high

- confidence付きMotion占有率が70%以上
- 他の分類証拠と矛盾しない

### medium

- Motion占有率が40%以上
- または速度・距離条件とMotionが概ね一致する

### low

- Motion情報が少ない
- 速度・距離条件だけで判定
- 複数状態が混在
- 短い区間

信頼度はデバッグに利用し、MVPの通常画面では必ずしも表示しない。

## 17. 有効移動日の判定

初期値：

```text
minimumValidDayDistance = 1km
minimumValidMovementSegments = 1
```

次のすべてを満たす場合だけ、有効な移動日とする。

```text
合計有効移動距離 >= 1km
AND
有効移動区間数 >= 1
AND
有効位置点数 >= 2
```

次の場合は無効日とする。

- 合計距離が1km未満
- 有効区間がない
- 有効位置点が2点未満
- 座標誤差だけで移動したように見える
- 全区間が不自然なジャンプとして除外された

無効日でも生ログと処理結果を保存してよい。

カレンダーでは距離やマーカーを表示せず、日別詳細へ遷移させない。

## 18. 代表仮分類

日別サマリーの代表仮分類は、移動時間が最も長い自動分類を採用する。

ユーザー分類が存在する場合も、日別代表仮分類の自動値自体は変更しない。

表示上、ユーザー分類を集計した代表分類を別途生成してよい。

同率または判定不能の場合は`other`とする。

## 19. Override再紐づけ

### 19.1 基本方針

1. stableID完全一致を最優先
2. 完全一致しない場合だけ近似判定
3. 複数候補が存在する場合は自動適用しない
4. 誤適用の可能性がある場合は適用しない
5. 元Overrideは削除しない

### 19.2 MovementSegment Override

stableIDが一致しない場合、次のすべてを満たす区間を候補とする。

```text
同じlocalDateKey
開始時刻差 <= 15分
終了時刻差 <= 15分
時間帯の重なり率 >= 50%
```

時間帯の重なり率：

```text
重なっている秒数 ÷ 短い方の区間時間
```

候補が1件だけなら再適用する。

候補が0件または2件以上なら自動適用しない。

初期値：

```text
movementOverrideStartTolerance = 15分
movementOverrideEndTolerance = 15分
movementOverrideMinimumOverlap = 50%
```

### 19.3 Stay Override

stableIDが一致しない場合、次のすべてを満たす滞在を候補とする。

```text
同じlocalDateKey
到着時刻差 <= 15分
出発時刻差 <= 15分
代表座標差 <= 300m
```

候補が1件だけなら再適用する。

候補が0件または2件以上なら自動適用しない。

初期値：

```text
stayOverrideArrivalTolerance = 15分
stayOverrideDepartureTolerance = 15分
stayOverrideCoordinateTolerance = 300m
```

## 20. stableID生成時の丸め

### MovementSegment

```text
localDateKey
+
開始時刻を1分単位に丸める
+
終了時刻を1分単位に丸める
```

### StaySegment

```text
localDateKey
+
到着時刻を1分単位に丸める
+
出発時刻を1分単位に丸める
+
緯度を小数第4位へ丸める
+
経度を小数第4位へ丸める
```

生成文字列をSHA-256でハッシュする。

同じ入力から同じstableIDを生成する。

## 21. メディア表示対象判定

### 21.1 対象

- 静止画
- 動画
- creationDateを持つ資産

### 21.2 除外

次を確実に除外する。

- スクリーンショット
- 画面収録

### 21.3 除外しないもの

次は、メタデータだけで確実に判断できない限り除外しない。

- ダウンロード画像
- 他アプリから保存された画像
- 撮影元が不明な写真
- 編集済み写真
- 位置情報がない写真
- 位置情報がない動画

AIや画像内容解析は使用しない。

### 21.4 日付

メディアの日別グループは`creationDate`を、記録対象日の現地タイムゾーンで評価する。

PhotoKit資産自体に記録時タイムゾーンが保持されない場合は、対象日検索時の`DateInterval`に基づいて分類する。

この制約により旅行時に境界付近のメディアが異なる日へ入る可能性を許容する。

## 22. メディアグリッド

MediaEligibilityが`eligible`の資産を表示する。

位置情報の有無はグリッド表示条件にしない。

並び順は次とする。

```text
creationDate昇順
```

creationDateがない資産は原則表示対象外とする。

同時刻の場合はlocalIdentifierの文字列順とする。

## 23. メディア地図配置

位置情報を持つメディアだけを地図へ配置する。

位置情報がないメディアを撮影時刻から推測配置しない。

### 経路との関連付け

メディア座標から各移動区間ポリラインまでの最短距離を計算する。

初期値：

```text
maximumRouteMediaDistance = 500m
```

500m以内の移動区間が1つ以上ある場合、最も近い区間へ関連付ける。

500mを超える場合：

- 地図上には実際のメディア位置として表示してよい
- 移動区間との関連付けは行わない

複数区間が同距離に近い場合は、撮影時刻が区間時間内または最も近い区間を優先する。

## 24. 経路簡略化

初期値：

```text
simplificationTolerance = 30m
minimumPointCountForSimplification = 10
```

位置点数が10点未満の区間は簡略化しない。

10点以上の場合はDouglas-Peucker方式を使用する。

必ず維持する点：

- 開始点
- 終了点

簡略化前の生ログは変更しない。

表示用経路だけを簡略化する。

## 25. ポリラインラベル

1つの移動区間につき、原則1つのラベルを生成する。

表示内容：

```text
移動時間・移動距離
```

例：

```text
32分・18.4km
1時間12分・54.8km
```

### 基準位置

経路距離の50%地点を基準にする。

単純な配列中央は使用しない。

### 重なり時の候補順

```text
50%
40%
45%
55%
60%
```

次と重なる場合、次候補へ移動する。

- 他の区間ラベル
- 滞在地点
- メディアアノテーション
- 地図端に近すぎる位置

すべて重なる場合は50%地点を使用し、Map表示側で重なりを許容する。

## 26. ラベル表示フォーマット

### 距離

```text
1km未満：整数m
1km以上10km未満：小数第1位km
10km以上：小数第1位km
```

例：

```text
850m
3.4km
18.4km
```

### 時間

```text
60分未満：整数分
60分以上：X時間Y分
```

例：

```text
32分
1時間12分
```

1分未満の区間は原則として有効区間にならない。

## 27. 日別サマリー

次を移動区間から集計する。

- 総移動距離
- 総移動時間
- 開始時刻
- 終了時刻
- 移動区間数
- 車っぽい移動時間
- 徒歩っぽい移動時間
- 代表仮分類

次を滞在区間から集計する。

- 表示対象滞在地点数
- 表示対象滞在の総時間

ユーザーが非表示にした滞在は、表示用件数と表示用総時間へ含めない。

自動判定値をデバッグ用に別保持してよい。

## 28. 境界条件

### 位置点が0件

- 有効移動なし
- 派生区間なし
- 処理成功として空結果を保存してよい

### 位置点が1件

- 有効移動なし
- 距離0
- 区間なし

### Motionが0件

- 位置ログだけで処理を続行
- 分類は速度・距離条件または`other`

### Visitが0件

- 位置点間の時間差とMotionから滞在推定
- CLVisitなしを失敗扱いにしない

### メディアが0件

- mediaCountは0
- 地図と詳細画面は通常表示

### 全位置点が除外

- 有効移動なし
- rejectedLocationCountへ件数を保存
- エラーではなく処理済みとする

## 29. 処理キャンセル

処理中にキャンセルされた場合：

- 新しい派生データを保存しない
- 既存の派生データを削除しない
- processedRevisionを更新しない
- 状態をpendingまたはfailedへ戻す
- 次回は同じ日を最初から再処理する

## 30. 決定性

同じ入力、同じConfiguration、同じOverrideから、次が一致しなければならない。

- 除外位置点
- 区間分割
- 区間距離
- 区間平均速度
- 滞在候補
- 自動分類
- stableID
- 日別サマリー
- ラベル候補位置

現在時刻に依存する処理では`Clock`を注入する。

## 31. 初期設定値一覧

| 設定 | 初期値 |
|---|---:|
| `duplicateTimeInterval` | 30秒 |
| `duplicateDistance` | 10m |
| `maximumHorizontalAccuracy` | 500m |
| `maximumPlausibleSpeed` | 250km/h |
| `maximumContinuousGap` | 90分 |
| `minimumSegmentDistance` | 100m |
| `minimumSegmentPointCount` | 2 |
| `minimumSpeedDisplayDuration` | 2分 |
| `minimumSpeedDisplayDistance` | 100m |
| `minimumSpeedDisplayPointCount` | 2 |
| `minimumStayDuration` | 3分 |
| `automaticStayDuration` | 5分 |
| `stayRadius` | 150m |
| `automotiveMotionRatio` | 50% |
| `automotiveFallbackSpeed` | 15km/h |
| `automotiveFallbackDistance` | 2km |
| `walkingMotionRatio` | 40% |
| `walkingFallbackMaximumSpeed` | 8km/h |
| `walkingFallbackMaximumDistance` | 3km |
| `minimumValidDayDistance` | 1km |
| `minimumValidMovementSegments` | 1 |
| `movementOverrideStartTolerance` | 15分 |
| `movementOverrideEndTolerance` | 15分 |
| `movementOverrideMinimumOverlap` | 50% |
| `stayOverrideArrivalTolerance` | 15分 |
| `stayOverrideDepartureTolerance` | 15分 |
| `stayOverrideCoordinateTolerance` | 300m |
| `maximumRouteMediaDistance` | 500m |
| `simplificationTolerance` | 30m |
| `minimumPointCountForSimplification` | 10 |
| `routeLabelPrimaryPosition` | 50% |
| `routeLabelFallbackPositions` | 40%, 45%, 55%, 60% |

## 32. テスト必須ケース

### LocationSanitizer

- 30秒以内・10m以内の重複
- 30秒以内だが10m超
- 10m以内だが30秒超
- 水平精度500m
- 水平精度500m超
- 250km/h以下
- 250km/h超
- A-B-CでBだけ異常なケース

### MovementSegmenter

- 90分未満の空白
- 90分以上の空白
- 日付境界
- CLVisitによる分割
- automotiveからwalkingへの変化
- 100m未満の候補区間

### StayDetector

- 3分未満
- 3〜5分で証拠なし
- 3〜5分でCLVisitあり
- 5分以上
- automotive-stationary-automotive
- walkingあり
- confirm Override
- hide Override

### MovementClassifier

- automotive 50%以上
- automotive 50%未満
- Motionなし・15km/h以上・2km以上
- walking/running 40%以上
- Motionなし・8km/h以下・3km以下
- cycling中心
- 複数状態競合
- 平均速度なし

### Day Validation

- 999m
- 1000m
- 1km以上だが有効区間なし
- 有効点1件
- 有効点2件

### Override Matching

- stableID完全一致
- 時刻差15分以内
- 時刻差15分超
- 重なり率50%
- 候補が複数
- 滞在座標300m以内
- 滞在座標300m超

### Media

- スクリーンショット
- 画面収録
- 通常写真
- ダウンロード由来か不明な写真
- 位置情報なし
- 位置情報あり・経路500m以内
- 位置情報あり・経路500m超
- 動画

### Route

- 点数9点
- 点数10点
- 開始・終了点維持
- 50%地点
- 50%地点が重なる場合の候補順

## 33. MVP完了条件

- すべての閾値が`ProcessingConfiguration`へ集約されている
- 重複、低精度点、座標ジャンプを決定的に除外できる
- 90分空白と現地日付境界で区間分割できる
- 3分、5分、150mのルールで滞在候補を生成できる
- automotive、walking、otherを初期ルールで分類できる
- 区間平均速度だけを生成できる
- 1km未満の日を移動日から除外できる
- stableIDと近似条件でOverrideを再紐づけできる
- スクリーンショットと画面収録を除外できる
- 位置情報付きメディアだけを地図へ配置できる
- 経路を30m許容差で簡略化できる
- 経路距離50%地点を基準にラベルを配置できる
- 必須テストケースがUnit Testとして実装可能である

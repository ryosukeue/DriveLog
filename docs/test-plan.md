# Test Plan

## 実機フィードバック改訂の追加検証（2026-07-15）

- 停止中GPSドリフトは5分、0.5m/s、進行率40%、Motion Evidence 3分、stationary比率60%の全条件と各境界をUnit Testし、低速前進、travel優勢、Evidence不足のMovementを維持する。
- Visit/Motion境界だけではPolylineを分割せず、5分以上のStay境界、90分Gap、現地日付境界では分割する。
- 充電状態とLocation Mode遷移、約60秒emit境界、重複起動防止をUnit Testする。
- MapSceneのMedia Annotationは別Media snapshotが空でも描画し、Thumbnail失敗時もfallbackを維持する。
- 日別Galleryと場所ClusterのPreviewは、選択元Media内を左右Page移動できることをUI Testする。
- Calendarからの日付Sheet、下Swipe dismiss、記録日の左右Page移動、全画面地図の単一戻る矢印をUI Testする。
- 多数の経路、Stay、Mediaを持つ全画面地図でも、補助Accessibility要素が画面幅を拡張せず、戻る矢印がSafe Area内で操作可能なことをUI Testする。
- Movement分類変更Presentation Testは削除し、既存Override表示/Application/Data互換Testを維持する。
- Stayの3操作、保存中、失敗、即時Scene反映をTestする。
- Stay縮小時のCluster化と、Stay/Media/両方の共通場所Popup選択をTestする。
- 詳細統計UIは存在せず、基本Summary/Map/MediaをTestする。
- Calendarは縦Scroll、月window遅延追加、年境界、一意なAccessibility label、記録なし日無効化をTestする。旧左右Swipe月移動Testは適用しない。
- アプリ終了などで`processing`のまま残った未完了世代が次回の再処理候補へ戻り、世代一致済みの日は戻らないことをSwiftData Integration Testする。
- 5分以上の確定Visitでは到着端点を直前Movementへ保持し、Visit中の追加位置点をMovementから除外し、退出後を別SegmentとしてUnit Testする。
- Processing Algorithm Version更新は完了日だけを1回pendingへ戻し、既に未完了の日を維持し、Invalidation失敗時にVersionを進めないことをUnit/Integration Testする。
- Movement選択中は端点付近のStayだけを強調し、無関係な独立StayとMedia付属Stay時間を減光し、選択解除で復元することをUnit Testする。
- 出発未確定/5分未満VisitはMovementをhard splitせず、確定5分以上Visitは分割し、表示PolylineのStay接続は時間5分・距離150mの両条件をUnit Testする。
- 同一場所の複数Stayは件数表示を持たず、Movement選択時は最も近い前後各1件だけを表示し、選択解除で汎用表示へ戻ることをUnit Testする。
- 非充電中の車両系Activityで高精度Modeへ昇格し、Activity終了後の3分猶予、充電優先、Motion利用不可時のSLC fallbackをUnit Testする。

## 1. 目的

この文書は、DriveLog MVPのテスト方針、対象範囲、優先順位、実行環境、Fixture、実機確認項目、完了条件を定義する。

目的は次のとおり。

- 移動判定ロジックの再現性を保証する
- SwiftDataの保存・削除ミスを検出する
- OS依存機能を自動テストと実機確認へ適切に分ける
- 日付・タイムゾーン依存の不具合を防ぐ
- ユーザーデータや個人情報をテストへ持ち込まない
- Codexがテストを省略して完了扱いにしないようにする

## 2. テスト戦略

テストの優先順位は次とする。

1. Unit Test
2. SwiftData Integration Test
3. 主要導線のUI Test
4. 実機Test
5. 長期利用Test

理由：

- ProcessingはOSなしで決定的に検証できる
- RepositoryはSwiftData実体で確認する必要がある
- UI Testは主要導線だけに絞る
- SLC、PhotoKit、BGTask、電池消費は実機確認が必要
- 長期間の自動記録は短時間テストだけでは判断できない

## 3. 自動テストと実機テストの境界

### 自動テストするもの

- 日付キー生成
- 位置点の重複判定
- 無効位置点除外
- 水平精度による除外
- 座標ジャンプ除外
- 日付境界分割
- 移動区間分割
- 滞在判定
- 移動分類
- 平均速度計算
- 有効移動日判定
- stableID生成
- Override再紐づけ
- 経路簡略化
- ラベル候補生成
- メディアEligibility
- メディア地図配置
- 日別サマリー生成
- UseCaseの分岐
- Repository保存・削除
- Coordinatorの重複処理防止
- エラー変換

### 実機で確認するもの

- Significant Location Change受信
- 充電開始通知を取り逃した場合の定期照合と高精度Mode復旧
- 充電状態、Location Mode、受信、emit、保存のPrivacy-safeな診断連鎖
- アプリ終了後の再起動挙動
- バックグラウンド記録
- Core Motion受信
- Core Motionの車両系Activityによる高精度Mode昇格、短時間停止の猶予、非充電時のSLC復帰
- CLVisit受信
- Photo Library限定アクセス
- iCloud上だけにあるメディア
- BGProcessingTask実行
- 共有シート
- 実電池消費
- 長時間移動
- 実際の写真・動画表示
- MapKit Calloutの操作感

## 4. Unit Test対象

# 4.1 LocalTimeContext

必須ケース：

- 日本時間で`YYYY-MM-DD`を生成できる
- 台湾時間で正しい日付キーになる
- UTC日付と現地日付が異なる
- 23:59から翌日へ切り替わる
- 記録後に端末タイムゾーンが変わっても保存済み日付キーが変わらない
- UTC offsetを保存できる
- TimeZone identifierを保存できる
- サマータイム開始境界
- サマータイム終了境界

テストでは`Clock`と`TimeZoneProviding`のFakeを使用する。

# 4.2 LocationSanitizer

必須ケース：

- 緯度範囲外
- 経度範囲外
- NaN座標
- 負の水平精度
- 未来24時間以内
- 未来24時間超
- 水平精度500m
- 水平精度500m超
- 時刻順でない入力
- 同時刻で精度が異なる点
- 全位置点が除外される
- 位置点0件
- 位置点1件

# 4.3 Duplicate Detection

必須ケース：

- 30秒以内かつ10m以内
- 30秒ちょうどかつ10mちょうど
- 30秒以内だが10m超
- 10m以内だが30秒超
- 同一時刻かつ同一座標
- 重複候補で後側の精度が良い
- 重複候補で前側の精度が良い
- deduplicationKeyが同じでも実距離条件を満たさない

# 4.4 Implausible Jump Detection

必須ケース：

- 250km/h未満
- 250km/hちょうど
- 250km/h超
- A-B-CでBだけ異常
- A-B-CでCが異常
- 前後点が不足
- 両点の精度差が大きい
- 両点の精度差が小さい
- 高速鉄道相当だが250km/h以下

# 4.5 Local Day Boundary Split

必須ケース：

- 同じlocalDateKey
- 日付境界をまたぐ
- UTCでは同日だが現地日付が異なる
- 現在端末のTimeZoneと保存済みTimeZoneが異なる
- 日付境界付近に位置点がない
- 複数日を含む生ログ

# 4.6 MovementSegmenter

必須ケース：

- 通常の連続移動
- 90分未満の空白
- 90分ちょうど
- 90分超
- CLVisitによる分割
- automotiveからwalking
- walkingからautomotive
- Motion変化だけで停止証拠なし
- 100m未満の候補区間
- 点数1点
- 点数2点
- 日付境界
- 複数滞在を含む
- 前後区間へ統合できる短区間
- 統合できない短区間
- 停止中に同一範囲を往復する低速GPSドリフト
- 低速でも一方向へ進む経路
- walkingまたはautomotiveが優勢な往復経路
- Motion Evidence不足
- open Motion snapshotの次snapshotによる置換
- travelとstationaryが競合するsnapshot

# 4.7 StayDetector

必須ケース：

- 3分未満
- 3分ちょうど
- 3〜5分で証拠なし
- 3〜5分でCLVisitあり
- 3〜5分でautomotive→walking
- 3〜5分でautomotive→stationary→walking
- 5分ちょうど
- 5分超
- automotive→stationary→automotive
- walking証拠あり
- CLVisitあり
- 半径150m以内
- 半径150m超
- 位置点1件
- confirm Override
- hide Override
- automatic Override
- CLVisitのarrivalDate優先
- CLVisitのdepartureDate優先
- 出発未確定Visit

# 4.8 MovementClassifier

必須ケース：

- automotive占有率50%未満
- automotive占有率50%
- automotive占有率50%超
- walkingまたはrunning占有率40%未満
- walkingまたはrunning占有率40%
- walkingまたはrunning占有率40%超
- Motionなし、15km/h以上、2km以上
- Motionなし、15km/h未満
- Motionなし、2km未満
- Motionなし、8km/h以下、3km以下
- Motionなし、8km/h超
- cycling中心
- unknown中心
- 車両系と徒歩系が競合
- confidence low
- confidence medium
- confidence high
- 平均速度なし
- 点数不足
- 短区間

# 4.9 Average Speed

必須ケース：

- 距離と時間から正しく算出
- 2分未満
- 2分ちょうど
- 100m未満
- 100mちょうど
- 点数1点
- 点数2点
- 0秒区間
- 負の時間差を拒否
- 日全体平均速度を生成しない

# 4.10 Valid Movement Day

必須ケース：

- 999m
- 1000m
- 1001m
- 有効区間0件
- 有効区間1件
- 有効点1件
- 有効点2件
- 全区間が除外
- 生ログはあるが有効移動なし
- 複数区間合計で1km超

# 4.11 Stable ID

必須ケース：

- 同じ入力から同じID
- 開始時刻の1分丸め
- 終了時刻の1分丸め
- localDateKeyが異なる
- 滞在座標小数第4位丸め
- 座標差が丸め範囲内
- 座標差が丸め範囲外
- SHA-256出力が決定的
- 区間再処理後も同条件なら一致

# 4.12 Override Matching

Movement必須ケース：

- stableID完全一致
- 開始時刻差15分以内
- 開始時刻差15分超
- 終了時刻差15分以内
- 終了時刻差15分超
- 重なり率50%
- 重なり率50%未満
- 候補0件
- 候補1件
- 候補複数
- 異なるlocalDateKey
- 元Overrideが削除されない

Stay必須ケース：

- stableID完全一致
- 到着時刻差15分以内
- 到着時刻差15分超
- 出発時刻差15分以内
- 出発時刻差15分超
- 座標300m以内
- 座標300m超
- 候補複数
- 異なるlocalDateKey

# 4.13 Route Simplifier

必須ケース：

- 点数0
- 点数1
- 点数9
- 点数10
- 直線
- 曲線
- 開始点保持
- 終了点保持
- 30m許容差
- 同一座標の連続
- 簡略化前データを変更しない

# 4.14 Route Label Placement

必須ケース：

- 50%地点
- 50%地点が占有済み
- 40%へ移動
- 45%へ移動
- 55%へ移動
- 60%へ移動
- 全候補が競合
- 短い経路
- 単一点
- 区間ラベル文字列

# 4.15 Media Eligibility

必須ケース：

- 通常写真
- 通常動画
- スクリーンショット
- 画面収録
- ダウンロード由来が不明
- 他アプリ保存が不明
- 編集済み写真
- 位置情報なし
- creationDateなし
- 削除済み参照
- 限定アクセス内
- 限定アクセス外

# 4.16 Media Placement

必須ケース：

- 位置情報なし
- 経路500m以内
- 経路500mちょうど
- 経路500m超
- 複数区間候補
- 最も近い区間
- 撮影時刻が区間時間内
- 撮影時刻が全区間外
- 地図表示はするが区間関連付けなし

# 4.17 Day Summary

必須ケース：

- 距離合計
- 時間合計
- 開始時刻
- 終了時刻
- 移動区間数
- 表示滞在件数
- 表示滞在時間
- hide Overrideの滞在を除外
- mediaCount
- 代表仮分類
- 同率でother
- 区間0件
- rejectedLocationCount
- sourceRawRevision

## 5. UseCase Unit Test

# 5.1 LoadCalendarMonthUseCase

確認：

- 月内の日別集計を取得する
- 有効移動日だけ距離を返す
- 1km未満の日を無効として返す
- 生ログRepositoryを呼ばない
- 空月を返せる
- Repository ErrorをDriveLogErrorへ変換する

# 5.2 LoadDayDetailUseCase

確認：

- Aggregate、Movement、Stay、Mediaを取得する
- MapSceneを生成する
- 再集計中状態を返す
- Override適用済み表示を返す
- 日全体平均速度を返さない
- メディア0件
- 削除直後の空状態
- 取得失敗

# 5.3 ProcessDayUseCase

確認：

- 未処理日を処理する
- processedRevisionがrawRevisionと同じなら再処理しない
- rawRevisionが新しい場合は再処理する
- 生ログ取得
- Override取得
- Media件数取得
- Processing実行
- 派生データ一括置換
- processedRevision更新
- 処理中にrawRevisionが変わった場合はpendingに残す
- Processing失敗
- Repository保存失敗
- キャンセル
- 同日二重実行防止

# 5.4 UpdateClassificationUseCase

確認：

- OverrideをUpsertする
- 自動分類を変更しない
- 同一overrideKeyで更新する
- 保存失敗
- 正しいログイベント

# 5.5 UpdateStayOverrideUseCase

確認：

- confirm
- hide
- automatic
- 自動判定値を変更しない
- 保存失敗
- 正しいログイベント

# 5.6 DeleteDayLogUseCase

確認：

- DayDeletionRepositoryを1回呼ぶ
- Photos削除APIを呼ばない
- 成功
- 失敗
- 部分削除を完了扱いにしない
- 正しいログイベント

# 5.7 RefreshMediaCacheUseCase

確認：

- 日付から検索範囲を生成する
- PhotoLibraryから取得する
- スクリーンショットを除外する
- 画面収録を除外する
- 位置情報なしを残す
- キャッシュを日付単位で置換する
- 削除済み参照を消す
- mediaCountを更新する
- 限定アクセス
- 取得失敗

# 5.8 Monitoring UseCases

確認：

- 位置監視開始
- Motion利用可能時に開始
- Motion拒否でも位置監視継続
- Visit失敗でも位置監視継続
- 重複開始しない
- start/stop呼び出し回数
- 状態変更イベント処理

## 6. SwiftData Integration Test

インメモリ構成のSwiftData Containerを使用する。

実際のSchemaとMigration Planを使用する。

Fake Repositoryだけではなく、具体Repository実装を対象とする。

# 6.1 RawEventRepository

確認：

- LocationEvent保存
- MotionEvent保存
- VisitEvent保存
- Visitの到着だけ保存
- 同一Visitの出発更新
- 近似重複Location無視
- 異なるLocation保存
- rawRevision増加
- localDateKey別取得
- 日付削除
- 大量保存時に毎回saveしない

# 6.2 ProcessingStateRepository

確認：

- 初期state
- markDirty
- markProcessing
- markCompleted
- markFailed
- rawRevision
- processedRevision
- pendingDateKeys
- 日付削除
- 状態遷移の整合性

# 6.3 DerivedDataRepository

確認：

- Aggregate保存
- Movement保存
- Stay保存
- 月別Aggregate取得
- 日付別取得
- replaceDerivedData
- 既存データ一括置換
- 途中失敗時に旧データ維持
- sourceRawRevision保存
- 日付削除
- orphan cleanup

# 6.4 OverrideRepository

確認：

- Classification Override保存
- Stay Override保存
- 同じoverrideKeyで更新
- 再処理で維持
- 日付別取得
- 日付削除

# 6.5 MediaCacheRepository

確認：

- localIdentifier一意
- 位置情報あり
- 位置情報なし
- 動画
- 日付単位置換
- 削除済みID除去
- 同一ID重複防止
- 日付削除
- 画像本体を保存しない

# 6.6 DayDeletionRepository

指定日の次をすべて削除する。

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

確認：

- 別日のデータを削除しない
- Photos資産を削除しない
- 関連なしの孤児データもlocalDateKeyで削除する
- 途中失敗時に部分状態を残さない
- 削除後に再取得すると空になる

# 6.7 Schema

確認：

- V1 Schemaで起動できる
- 空Containerで起動できる
- 既存データを読み込める
- Modelの必須値が保存できる
- encodedRouteDataを保存・復元できる
- Relationship delete ruleが意図通り
- Migration Planが登録されている

## 7. Coordinator Test

# 7.1 DayProcessingCoordinator

Fake Scheduler、Fake UseCase、Fake Clockを使用する。

確認：

- 同じ日の同時処理を1回にまとめる
- userVisibleをbackgroundより優先する
- pending日をlimit件処理する
- 失敗日を再試行対象へ残す
- キャンセル時にUseCaseへ伝播する
- BGTask expirationでキャンセルする
- 別日は並行または順次処理できる
- 同一日を二重保存しない

# 7.2 AppLifecycleCoordinator

確認：

- Launch時に権限を更新する
- 監視状態を確認する
- 必要なら監視を開始する
- pending日を確認する
- Background移行時にBGTaskを予約する
- Foreground復帰時にメディア変更を反映する
- 通常Background移行でSLCを停止しない

## 8. Provider Conversion Test

OS Frameworkそのものではなく、Provider内部の変換処理をUnit Testする。

# 8.1 Location Provider

確認：

- CLLocationからLocationEventDataへ変換
- timestamp
- latitude
- longitude
- horizontalAccuracy
- altitude
- speed
- course
- localDateKey
- timeZone identifier
- UTC offset
- Delegate Error変換
- Streamへイベント送信

# 8.2 Motion Provider

確認：

- automotive
- walking
- running
- cycling
- stationary
- unknown
- 複数フラグ同時true
- confidence変換
- 権限拒否
- Stream終了

# 8.3 Visit Provider

確認：

- 到着だけのVisit
- 出発確定Visit
- 座標変換
- arrivalDate
- departureDate
- 同一候補更新用データ

# 8.4 Photo Library Provider

Fakeまたは変換Helperで確認：

- PHAssetからMediaAssetReference変換
- 写真
- 動画
- screenshot subtype
- screen recording subtype
- location
- creationDate
- duration
- 削除済み
- 限定アクセス
- Change Observerイベント

## 9. UI Test

UI Testは主要導線に限定する。

Snapshot TestはMVPで導入しない。

### 主要フロー

```text
権限説明
→ カレンダー
→ 日別詳細
→ 全画面地図
→ 区間Callout
→ 滞在Callout
→ メディアプレビュー
→ 共有導線
→ 日付削除
```

# 9.1 Onboarding

確認：

- 位置情報説明
- Motion説明
- Photos説明
- 端末内処理説明
- 権限要求ボタン
- 拒否時の設定ボタン
- 限定アクセス状態

OS権限ダイアログ自体の詳細文言はUI Testへ依存しすぎない。

# 9.2 Calendar

確認：

- 月が表示される
- 日付が表示される
- 有効移動日に距離が表示される
- 1km未満の日に距離が表示されない
- 無効日をタップしても遷移しない
- 有効日で日別詳細へ遷移
- 左右スワイプで月移動
- 今日の表示
- 空月
- エラーと再試行

# 9.3 Day Detail

確認：

- 地図プレビュー
- サマリー
- 詳細統計
- メディアグリッド
- グリッド原則4列
- 動画アイコン
- 地図タップでFull Map
- 再集計バナー
- 既存データ維持
- 削除Menu
- 削除確認
- 削除成功後にCalendarへ戻る
- 削除失敗時に画面維持

# 9.4 Full Map

確認：

- ポリライン表示
- 区間ラベル
- 区間タップでCallout
- 滞在タップでCallout
- 1度に1つのCallout
- 空白タップで閉じる
- 分類変更
- 滞在confirm
- 滞在hide
- 滞在automatic
- 現在地ボタン
- コンパス
- メディアタップ
- クラスタ

# 9.5 Media Preview

確認：

- 写真表示
- 動画表示
- 動画再生
- 共有ボタン
- 参照不能エラー
- ローディング
- 戻る操作

# 9.6 Accessibility UI Test

最低限確認：

- 主要ボタンにAccessibility Labelがある
- 日付セルのLabel
- 区間CalloutのLabel
- 滞在CalloutのLabel
- メディアセルのLabel
- Accessibility Identifierが安定している

## 10. 画面サイズTest

### Simulator対象

- iPhone SE相当
- 標準サイズiPhone
- iPhone 15
- Pro Max相当

確認：

- Calendarセルが切れない
- サマリーが押しつぶされない
- Calloutが画面外へ出ない
- Media Gridが破綻しない
- Navigation Titleが切れない
- 削除Alertが読める
- 権限説明がスクロール可能
- Safe Areaと重ならない

端末モデル名で実装を分岐しない。

## 11. Appearance Test

主要画面をライト・ダーク両方で確認する。

対象：

- Onboarding
- Calendar
- Day Detail
- Full Map
- 区間Callout
- 滞在Callout
- Media Preview
- 権限拒否
- 削除確認
- エラー表示

確認：

- 赤Accentが見える
- 今日の青丸が見える
- 文字と背景のコントラスト
- 地図上のラベル
- Callout
- 動画アイコン
- Destructive表示

## 12. Dynamic Type Test

最低限次を確認する。

- 標準
- 最大付近
- Accessibilityサイズ1種類

対象：

- Calendar日付セル
- Day Detailサマリー
- 詳細統計
- 区間Callout
- 滞在Callout
- 権限説明
- 削除確認
- 空状態
- エラー表示

確認：

- 重要情報が欠けない
- 固定高さで切れない
- ボタンが押せる
- Calloutが操作可能
- Gridが必要に応じて3列へ変化する
- 横スクロールを要求しない

## 13. Fixture方針

### 13.1 個人情報禁止

テストFixtureへ次を含めない。

- 自宅座標
- 学校座標
- 実際の移動経路
- 実写真
- 実動画
- PhotoKit localIdentifier
- 実名を含むファイル名

### 13.2 座標

実在の場所を想起させても、個人の行動履歴と関係しない架空データを使用する。

例：

- TokyoLikeRoute
- OsakaLikeRoute
- TaipeiLikeRoute
- DateBoundaryRoute
- TrafficStopRoute
- WalkingTransitionRoute

正確な自宅・学校・勤務先座標は使用しない。

### 13.3 時刻

固定日時を使用する。

例：

```text
2026-01-15 09:00 Asia/Tokyo
2026-01-15 23:59 Asia/Tokyo
2026-01-16 00:01 Asia/Tokyo
2026-07-15 09:00 Asia/Taipei
```

テスト実行時の現在日時に依存しない。

### 13.4 形式

少量のFixtureはSwiftコードで作る。

```text
Tests/TestSupport/Fixtures/
```

大量ログが必要になった場合だけJSONを使用する。

JSONを追加する場合：

- Schemaを文書化する
- 個人情報を含めない
- 期待結果を別Fixtureへ明示する
- 読込失敗Testを追加する

## 14. Fake / Spy / Stub

主要ProtocolへTest Doubleを用意する。

### Fake

- FakeClock
- FakeTimeZoneProvider
- FakeLocationProvider
- FakeMotionProvider
- FakeVisitProvider
- FakePhotoLibraryProvider
- InMemoryRawEventRepository
- InMemoryDerivedDataRepository
- InMemoryOverrideRepository
- FakeMapSceneBuilder

### Spy

- SpyLogger
- SpyBackgroundTaskScheduler
- SpySharePresenter
- SpyDayDeletionRepository
- SpyProcessingUseCase

### Stub

- StubPermissionManager
- StubRouteEncoder
- StubMediaEligibilityEvaluator

Test DoubleはTest TargetまたはTestSupportへ配置する。

本番ターゲットへ含めない。

## 15. PhotoKit Test方針

自動テストではFakePhotoLibraryProviderを使用する。

再現必須状態：

- 通常写真
- 動画
- スクリーンショット
- 画面収録
- 位置情報あり
- 位置情報なし
- creationDateなし
- 削除済み
- 限定アクセス
- アクセス拒否
- iCloud上のみ
- Thumbnail失敗
- Video Asset失敗
- Library Change

実際のPhoto Libraryを操作する自動テストはMVPで必須にしない。

## 16. Core Location / Motion / Visit Test方針

### Simulator

利用してよいもの：

- GPXまたはSimulator Location
- Foregroundでの位置変化確認
- 基本的なMap表示

Simulatorだけで合格判定しないもの：

- SLCバックグラウンド受信
- アプリ強制終了後の挙動
- 長時間停止
- CLVisitの確実な発生
- 電池消費
- Motion Activity精度

### 実機

実機確認必須：

- 「常に許可」
- Background App Refresh
- 位置監視開始
- 車移動
- 徒歩移動
- 停止
- アプリBackground
- アプリ終了後
- 再起動後
- Motion拒否時
- Visit未発生時

## 17. BGTask Test方針

### Unit Test

FakeBackgroundTaskSchedulerを使用する。

確認：

- register
- schedule
- cancel
- requiresExternalPower
- 予約失敗
- expiration
- Coordinatorキャンセル
- pending日処理
- limit
- 再試行

### 実機

確認：

- BGProcessingTaskが登録される
- 予約要求が成功する
- 充電中に実行される可能性がある
- 実行されなくてもForegroundで処理できる
- expiration時に途中データを確定しない
- 次回再処理できる

BGTaskの実行時刻はOS依存のため、必ず実行されることを合格条件にしない。

代わりにForeground fallbackを必須とする。

## 18. 実機構成

基準実機：

- iPhone 15
- 最新の対象iOS 17系またはそれ以降の対応OS

Simulator：

- iPhone SE相当
- iPhone 15
- Pro Max相当

実機で確認する項目：

- 位置権限
- Motion権限
- Photos権限
- SLC
- Background
- PhotoKit
- Video Playback
- Share Sheet
- Haptic
- Map Callout
- 電池消費

## 19. 実機手動テストシナリオ

# 19.1 初回起動

1. アプリを新規インストール
2. Onboarding表示
3. 位置情報を使用中のみ許可
4. 常に許可へ移行
5. Motion許可
6. Photos許可
7. Calendar表示
8. 監視開始状態確認

確認：

- 権限順序
- 拒否時にもクラッシュしない
- 設定アプリ導線
- 再起動後の状態復元

# 19.2 権限拒否

1. 位置拒否
2. Motion拒否
3. Photos拒否
4. アプリ再起動
5. 設定から一部許可

確認：

- 位置拒否の説明
- Motion拒否でも位置機能が継続
- Photos拒否でも移動記録が表示
- 権限変更後にUI更新

# 19.3 徒歩移動

1. 10分以上徒歩
2. 数分停止
3. 再度徒歩
4. 写真撮影

確認：

- 徒歩っぽい分類
- 区間分割
- 滞在候補
- 写真グリッド
- 地図配置
- 平均速度表示

# 19.4 車移動

1. 20分以上車移動
2. 5分以上停車
3. 徒歩へ移行
4. 写真・動画撮影

確認：

- 車っぽい分類
- automotive→walking
- 滞在地点
- 写真・動画表示
- 経路関連付け
- 動画再生
- Callout

# 19.5 渋滞・信号

1. 車で移動
2. 5分以上停止
3. 車で再開
4. 徒歩なし

確認：

- 滞在として過剰表示されない
- 区間が不自然に分割されない
- ユーザーが必要なら修正できる

# 19.6 日付境界

1. 23時台に移動開始
2. 0時をまたぐ
3. 翌日も移動
4. 両日を確認

確認：

- 2日へ分割
- 前日と翌日の距離
- メディアの所属日
- 削除が片日だけに効く

# 19.7 タイムゾーン変更

1. Asia/Taipeiで記録
2. Asia/Tokyoへ変更
3. 過去日を表示

確認：

- 保存済みlocalDateKeyが変わらない
- 記録日が再分類されない
- 表示時刻が仕様通り

# 19.8 Photos限定アクセス

1. 一部写真だけ許可
2. 日別詳細表示
3. 許可対象を変更
4. アプリへ戻る

確認：

- 許可済みだけ表示
- キャッシュ更新
- 削除・除外された参照を消す
- クラッシュしない

# 19.9 日付削除

1. 有効移動日を開く
2. 分類Overrideを作る
3. 滞在Overrideを作る
4. メディアを確認
5. 日付削除
6. Calendarへ戻る
7. Photosアプリを確認

確認：

- 当日の全ログ削除
- Calendar距離消失
- Photos資産維持
- 他日データ維持
- 復元不能
- 再起動後も削除済み

## 20. 長期利用テスト

MVP完成前に最低3種類を実施する。

### Test A：普通の外出1日

含める：

- 徒歩
- 停止
- 店舗滞在
- 写真

### Test B：車移動を含む1日

含める：

- 車
- 渋滞または信号
- 駐車
- 徒歩
- 複数滞在

### Test C：メディアを多く撮影する1日

含める：

- 写真複数
- 動画複数
- 位置情報あり
- 位置情報なし
- スクリーンショット
- 画面収録

各テストで確認：

- Background記録
- 電池消費
- Calendar反映
- 距離
- 区間分割
- 滞在
- 分類
- メディアグリッド
- メディア地図配置
- 再集計
- 翌日反映
- アプリ再起動

## 21. 電池消費確認

MVPでは厳密な数値目標を設定しないが、明らかな異常消費がないことを確認する。

確認方法：

- 通常利用日とDriveLog有効日の比較
- 設定アプリのバッテリー使用状況
- 位置情報インジケーターの継続点灯有無
- 高精度GPSが継続していないこと
- Background処理がループしていないこと
- PhotoKit検索が過剰に走っていないこと

異常条件：

- 高精度位置取得が継続する
- 数分ごとに大量処理が走る
- Foregroundで操作していないのにCPU使用が続く
- 1日で明らかにバッテリー使用率が増える

## 22. Performance Test

厳密なBenchmarkはMVP必須ではないが、次を確認する。

- 1日分位置イベント1,000件
- MovementSegment 100件
- StaySegment 100件
- Media Cache 1,000件
- 月間Aggregate 31日
- 1日分再処理
- 日付完全削除
- メディアグリッドスクロール
- Map上のクラスタ表示

確認：

- Main Threadを長時間占有しない
- Calendar表示が生ログ件数に比例して遅くならない
- Day Detailが全期間ログを取得しない
- Thumbnailを一括読込しない
- 処理キャンセルが効く
- メモリ警告でクラッシュしない

## 23. Privacy Test

確認：

- Loggerへ緯度・経度が出ない
- LoggerへPhotoKit localIdentifierが出ない
- Loggerへ写真・動画名が出ない
- テストFixtureに個人座標がない
- 共有一時ファイルが残らない
- SwiftDataへ画像本体が保存されない
- ネットワーク通信が発生しない
- 日付削除後に該当ログが残らない
- Photos資産は削除されない

## 24. Regression Test

不具合修正時は次の順序で行う。

1. 不具合を再現するTestを追加
2. Testが修正前に失敗することを確認
3. 実装修正
4. Test成功
5. 関連する既存Test成功
6. 必要なら実機再確認

再現Testを追加できないOS依存不具合は、手動Test手順をIssueまたはこの文書へ追加する。

## 25. Flaky Test方針

不安定なTestを無視設定にしない。

禁止：

- 無条件のsleep
- 実行順依存
- 実時計依存
- 実Photo Library依存
- 実ネットワーク依存
- 不要な再試行で隠す
- `.skip`の恒久利用

対応：

- Fake Clockへ置換
- Expectation条件を明確化
- OS依存なら実機手動Testへ移動
- 不要なら削除理由を記録
- AsyncStream終了条件を明示

## 26. Test Naming

形式：

```swift
func test_<unit>_when<condition>_<expectedResult>()
```

例：

```swift
func test_dayValidation_whenDistanceIs999Meters_marksDayInvalid()
func test_overrideMatching_whenMultipleCandidatesExist_doesNotApplyAutomatically()
func test_deleteDayLog_whenDeletionSucceeds_doesNotDeletePhotoAssets()
```

日本語名は使用しない。

テスト名から条件と期待結果が分かるようにする。

## 27. Test Directory

推奨構成：

```text
DriveLogTests/
├── TestSupport/
│   ├── Fakes/
│   ├── Spies/
│   ├── Stubs/
│   ├── Fixtures/
│   └── Builders/
├── Domain/
├── Processing/
├── Application/
├── Data/
├── Platform/
└── Shared/

DriveLogUITests/
├── Onboarding/
├── Calendar/
├── DayDetail/
├── RouteMap/
└── MediaPreview/
```

## 28. CI方針

MVP初期ではGitHub Actions等のCIを必須にしない。

各Issue完了時にローカルで次を実行する。

- Build
- Unit Test
- Integration Test
- 主要UI Test
- SwiftLint
- SwiftFormat Check

コードが安定した段階でCIを追加してよい。

CI追加時は次を確認する。

- Xcode Version固定
- Simulator固定
- Cacheに依存しない
- Signing不要の構成
- Test結果を保存
- Secretや個人情報を使用しない

## 29. カバレッジ方針

全体の数値目標は設定しない。

代わりに、責務ごとに必要な分岐を確認する。

### Processing

ほぼすべてのルール、境界値、例外をTestする。

### UseCase

主要成功経路、失敗経路、キャンセル、空状態をTestする。

### Repository

主要保存、取得、置換、削除、重複防止をTestする。

### Platform

変換ロジックとエラー変換をTestする。

### UI

主要導線だけをTestする。

単純なGetterやSwiftUIレイアウト内部実装のためにカバレッジを水増ししない。

## 30. Issue完了時のTest必須条件

- 対象機能のUnit Testがある
- 変更した分岐のTestがある
- Repository変更ならIntegration Testがある
- UI導線変更なら必要なUI Testがある
- 不具合修正なら再現Testがある
- 全Unit Test成功
- 全Integration Test成功
- 対象UI Test成功
- Build成功
- 新規Warningなし
- SwiftLint成功
- SwiftFormat Check成功
- 実機必須項目がある場合は手動確認済み
- 個人情報をTestやLogへ追加していない

## 31. MVPリリース前チェック

### Automated

- 全Unit Test成功
- 全Integration Test成功
- 主要UI Test成功
- Release Build成功
- SwiftLint成功
- SwiftFormat Check成功
- Migration起動Test成功

### Simulator

- iPhone SE相当
- iPhone 15
- Pro Max相当
- ライトモード
- ダークモード
- Dynamic Type標準
- Dynamic Type最大付近
- Accessibilityサイズ

### Device

- 初回権限
- 権限拒否
- 位置監視
- Background
- 徒歩
- 車
- 滞在
- 写真
- 動画
- Share Sheet
- 日付削除
- タイムゾーン
- 日付境界
- 再集計
- アプリ再起動
- 電池消費

### Privacy

- 外部通信なし
- 座標ログなし
- メディアIDログなし
- 共有一時ファイル削除
- 日付削除完全性
- Photos資産維持

## 32. MVP完了条件

- Processingの全主要ルールがUnit Testされている
- SwiftData RepositoryがインメモリIntegration Testを持つ
- 日付完全削除が自動Testされている
- stableIDとOverride再紐づけが自動Testされている
- ClockとTimeZoneがFakeへ差し替え可能である
- PhotoKitの主要状態をFakeで再現できる
- Coordinatorの重複処理とキャンセルがTestされている
- 主要画面遷移がUI Testされている
- SE相当からPro Maxまで表示確認されている
- ライト・ダーク・Dynamic Typeが確認されている
- iPhone 15実機でSLC、PhotoKit、BGTask fallbackが確認されている
- 普通の外出、車移動、メディア多用の3種類を長期Testしている
- 個人情報をFixture、Test Log、Repository Testへ含めていない
- 不具合修正時にRegression Testを追加できる体制になっている

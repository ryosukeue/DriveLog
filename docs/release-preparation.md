# DriveLog プロト公開準備チェックリスト

この文書は、無料・旧版をプロトタイプとして公開するための準備表です。法的文面、連絡先、Apple Accountの設定は公開者が最終確認してください。

## リリース候補

- [x] 手動の高密度記録開始画面を追加する前の版へ復元
- [x] Bundle Identifier: `com.ryosukeue.DriveLog`
- [x] iOS 17.0以上
- [x] iPhoneのみ、Portraitのみ
- [x] 無料配布方針
- [ ] 公開用Marketing VersionとBuild番号を決める
- [ ] Archiveを作成し、TestFlightへアップロードする

## Apple側で必要な作業（公開者）

- [ ] Apple Developer ProgramとApp Store Connectの契約を確認する
- [ ] Paid Apps Agreementは無料公開なら不要だが、契約状態を確認する
- [ ] App Store Connectでアプリレコードを作成する
- [ ] Privacy Policy URLを登録する
- [ ] Support URLを登録する
- [ ] App Privacy質問票へ回答する
- [ ] 年齢レーティング質問票へ回答する
- [ ] Export Compliance質問票へ回答する
- [ ] 価格を無料、公開地域、配信開始日を設定する
- [ ] スクリーンショットとアプリアイコンを登録する
- [ ] App Review Informationへ操作手順と連絡先を入力する
- [ ] TestFlightで実機確認後、審査へ提出する

## DriveLog固有の申告内容

- 位置情報: 移動経路の記録に使用。バックグラウンド利用あり
- モーション: 移動方法の推定に使用
- 写真ライブラリ: 移動日の写真・動画の日時、位置情報、サムネイル表示に使用
- 保存: 現行実装は端末内保存。サーバー、ログイン、CloudKit、広告SDK、解析SDKなし
- 共有: ユーザーが明示的に共有操作を行わない限り、アプリから外部送信しない
- 削除: アプリ内の日付削除でDriveLogの関連データを削除。Photosの元資産は削除しない

実際のApp Privacy回答は、App Store Connectの質問文と最新版の実装を照合して入力する。

## 実機リリース確認

- [ ] 初回権限フロー（位置情報、モーション、写真）
- [ ] 「常に許可」へ変更した後のバックグラウンド記録
- [ ] 充電中・非充電中の記録
- [ ] 低電力モード時の挙動
- [ ] 数時間の走行でのバッテリー・発熱
- [ ] アプリをバックグラウンドへ移した後の記録継続
- [ ] アプリ強制終了後の制限を説明文とReview Notesへ記載
- [ ] 写真の地図Annotation、ギャラリー、プレビュー
- [ ] 記録処理が遅延した場合の表示
- [ ] 日付削除後に地図・写真・集計が残らないこと

## 既知のプロト制限

- GPS精度が悪い場所では経路が粗くなることがある
- Raw Locationの処理完了まで表示に時間差が出ることがある
- iOSのバックグラウンド制約により、厳密な周期記録は保証しない
- 強制終了後の自動再開は保証しない

これらを隠して「常に正確な経路を記録する」と説明しない。

## 公開前に私が作成済みの下書き

- [Privacy Policy下書き](release/privacy-policy-draft.md)
- [Supportページ下書き](release/support-page-draft.md)
- [App Store説明・審査情報下書き](release/app-store-connect-metadata-draft.md)

## 公開者が入力する項目

- 法的な氏名または法人名
- 問い合わせメールアドレス
- Privacy PolicyとSupportページの公開URL
- 著作権表記
- 公開地域と公開日
- App Review用の連絡先
- 実機確認で得た制限事項

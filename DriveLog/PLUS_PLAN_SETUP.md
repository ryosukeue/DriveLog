# DriveLog Plus: App Store Connect設定

アプリ側のStoreKit商品IDは次で固定している。

- 商品ID: `com.ryosukeue.DriveLog.plus.monthly`
- 種類: 自動更新サブスクリプション
- 期間: 1か月
- 参照名: `DriveLog Plus Monthly`
- 表示名: `DriveLog Plus`

## App Store Connect

1. 「契約／税金／口座情報」で有料App契約を有効にする。
2. DriveLogの「サブスクリプション」で`DriveLog Plus`グループを作成する。
3. 上の商品IDで1か月の自動更新サブスクリプションを作成する。
4. 日本の価格設定で「すべての価格を表示」から選択可能な最安価格を選ぶ。
5. 「お試し価格」で初回利用者向けオファーを追加する。
   - 種類: 無料トライアル
   - 期間: 1週間（7日間）
   - 対象地域: 商品を販売するすべての地域
6. 日本語の表示名と説明を登録し、審査用スクリーンショットを追加する。
7. Appの新しいバージョンにサブスクリプションを紐づけて審査へ提出する。

価格はアプリへ直書きしていない。StoreKitが返す`displayPrice`を表示するため、App Store
Connectの価格変更や国別価格へ自動で追従する。

## リリース前に必要なもの

- 公開済みのプライバシーポリシーURL
- サポートURL
- App Store ConnectのApp内課金審査情報
- SandboxまたはTestFlightでの購入・復元・期限切れ確認

Apple公式:

- https://developer.apple.com/help/app-store-connect/manage-subscriptions/offer-auto-renewable-subscriptions/
- https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/
- https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions/

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("最終更新日：2026年8月10日")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                policySection(
                    "取得する情報",
                    "DriveLogは、ユーザーの許可と操作に応じて、位置情報、" +
                        "モーション情報、写真・動画の撮影日時や位置情報、" +
                        "車両名と車載オーディオ識別情報、燃費・給油・オイル交換の記録を扱います。"
                )
                policySection(
                    "利用目的",
                    "取得した情報は、移動経路・滞在・距離の記録、車両判定、" +
                        "燃費とメンテナンス情報の表示、友達ランキングの提供に利用します。"
                )
                policySection(
                    "保存と外部サービス",
                    "移動経路、車両、燃費、給油、オイル交換の情報は主に端末内へ保存します。" +
                        "友達機能ではAppleのCloudKitへ表示名、友達ID、友達関係、" +
                        "月間移動距離を保存します。購入状態の確認にはAppleのStoreKit、" +
                        "無料プランの広告表示にはGoogle Mobile Adsを利用します。"
                )
                policySection(
                    "写真・動画",
                    "写真・動画の元データをDriveLogのサーバーへアップロードしません。" +
                        "写真ライブラリの元データを削除または変更しません。"
                )
                policySection(
                    "削除と権限変更",
                    "アプリ内で対象日の記録や登録車両を削除できます。位置情報、モーション、" +
                        "写真などの権限は、iOSの設定からいつでも変更できます。" +
                        "iCloud連携は友達タブの設定から解除できます。"
                )
                policySection(
                    "第三者提供",
                    "法令に基づく場合を除き、取得した情報を本人の同意なく第三者へ販売しません。" +
                        "共有機能を使用した場合は、ユーザーが選択した共有先の取扱いが適用されます。"
                )
                policySection(
                    "お問い合わせ",
                    "運営者：宇惠諒介\nue.ryosuke@gmail.com"
                )
            }
            .padding()
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policySection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}
